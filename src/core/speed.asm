.export func_setup_irq_handler
.export func_restore_irq_handler

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
         sta ZP16_origIrqHandler+0
         lda KERNAL_IRQ_VECTOR+1
         sta ZP16_origIrqHandler+1

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
         lda ZP16_origIrqHandler+0
         sta KERNAL_IRQ_VECTOR+0
         lda ZP16_origIrqHandler+1
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
      DEBUG_TIMER_INCREMENT
      lda #%00000001         ; clear VSYNC IRQ to avoid immediate re-interrupt
      sta VERA_ISR
   @vsync_false_alarm:

   pla
   jmp (ZP16_origIrqHandler) ; don't RTI, rather chain to previous which will RTI
