.export func_setup_irq_handler
.export func_restore_irq_handler
.export func_snooze_if_necessary
.export func_snooze

.import func_print_hex

.segment "CODE"

.include "../include/debug.inc"
.include "../include/global.inc"
.include "../include/kernal.inc"
.include "../include/math.inc"
.include "../include/petscii.inc"
.include "../include/vera.inc"

.proc func_setup_irq_handler: near
   sei
      pha
         lda KERNAL_IRQ_VECTOR+0
         sta GR16_origIrqHandler+0
         lda KERNAL_IRQ_VECTOR+1
         sta GR16_origIrqHandler+1

         lda #<sub_irq_handler_for_delay
         sta KERNAL_IRQ_VECTOR+0
         lda #>sub_irq_handler_for_delay
         sta KERNAL_IRQ_VECTOR+1
      pla
   cli
   rts
.endproc

.proc func_restore_irq_handler: near
   sei
      pha
         lda GR16_origIrqHandler+0
         sta KERNAL_IRQ_VECTOR+0
         lda GR16_origIrqHandler+1
         sta KERNAL_IRQ_VECTOR+1
      pla
   cli
   rts
.endproc

; ---------------------------------------------------------------------
; IRQ handler
;
; Note that writing to "hardware registers" isn't the same as writing
; to a memory address. They sometimes have different semantics, as
; described in their documentation.  For VERA_ISR and VIA1_IFR, storing
; a value does not store it literally. It is more like a mask that does
; something when a bit is set. That's why storing %01000000 to VIA1_IFR
; actually CLEARS the interrupt flag, because it tells the hardware
; register which flags to CLEAR based on the 1's in your byte.
; ---------------------------------------------------------------------
sub_irq_handler_for_delay:
   pha

      lda VERA_ISR           ; read VERA IRQ status
      and #%00000001         ; b0 means VSYNC caused this interrupt
      beq @vsync_false_alarm
      inc ZP8_imageVSyncsElapsed
      DEBUG_TIMER_INCREMENT
      lda #%00000001         ; clear VSYNC IRQ to avoid immediate re-interrupt
      sta VERA_ISR
   @vsync_false_alarm:

      lda VIA1_IFR           ; Similar trick with VIA IFR
      and #%01000000         ; b6 means VIA timer caused the interrupt
      beq @via_false_alarm
      dec ZP8_timerTrigger   ; flip from 0 to $FF (snooze logic will notice)
      lda #%01000000         ; clear VIA flag to avoid immediate re-interrupt
      sta VIA1_IFR
   @via_false_alarm:

   pla
   jmp (GR16_origIrqHandler) ; don't RTI, rather chain to previous which will RTI

;==============================================================================
; func_snooze_if_necessary
;
; @prep  .A holds the number of sixtieths to snooze
; @effect .A .X .Y
;==============================================================================
.proc func_snooze_if_necessary: near
   sec
   lda ZP8_speedLimitVSyncs
   sbc ZP8_imageVSyncsElapsed
   bmi @handle_negative
   jmp func_snooze
@handle_negative:
   DEBUG_TIMER_REGISTER_SPEED_VIOLATION
   rts
.endproc

;##############################################################################
;# VIA Timer lets us wait up to $FFFF cycles.  We need to wait in increments
;# of 1/60th of a second. That's 133,333 cycles,  which is too big for VIA to
;# accommodate. So instead we'll ask it to sleep 44,444 cycles three times.
;# The symbols below reflect this.  If the 65c02 is being run at 4MHz or 2MHz
;# then these values will need to be tweaked. It is assumed that everyone will
;# be running their system at 8 MHz.
;##############################################################################
JIFFY_COUNT  := 3
JIFFY_CYCLES := $AD9C

;==============================================================================
; func_snooze
;
; @param  .A holds the number of sixtieths of a second to sleep
;            a value of zero is effectively a no-op
; @effect .A .X .Y
;
; At 8 MHz, 1/60 of a second is 133333 cycles. That's roughly $AD9C times 3.
; So to sleep 1/60, we'll sleep $AD9C three times.
;==============================================================================
.proc func_snooze: near
.ifdef DEBUG_TIMER_ENABLED
   rts
.endif
   tax
   bne @outer_loop
   rts
@outer_loop:
   ldy #JIFFY_COUNT
@inner_loop:
   phx
      phy
         jsr sub_snooze_jiffy
      ply
   plx
   dey
   bne @inner_loop
   dex
   bne @outer_loop
   rts
.endproc

.proc sub_snooze_jiffy: near
   sei                 ; disable interrupts while settubg up VIA

   lda #<JIFFY_CYCLES  ; Load Timer 1 latch
   sta VIA1_T1L_L
   lda #>JIFFY_CYCLES
   sta VIA1_T1L_H

   lda VIA1_ACR         ; establish "one shot mode" by
   and #%10111111       ; turning off bit 6
   sta VIA1_ACR
   lda #%01000000       ; clear timer 1 flag (i.e. start fresh)
   sta VIA1_IFR
   lda #%11000000       ; enable timer 1 interrupt
   sta VIA1_IER

   lda #<JIFFY_CYCLES   ; set timer 1 ticks
   sta VIA1_T1C_L
   lda #>JIFFY_CYCLES
   sta VIA1_T1C_H

   stz ZP8_timerTrigger ; establish that the timer has not yet triggered
   cli                  ; re-enable interrupts now that we're done setting up

@wait_loop:

   wai                  ; wait/block for ANY interrupt from ANY source
   lda ZP8_timerTrigger ; load the timer trigger (set by our interrupt handler)
   beq @wait_loop       ; if it's still zero, the timer hasn't triggered

   rts
.endproc

