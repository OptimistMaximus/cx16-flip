.export handle_delta_fli

.import func_slurp_into_buffer
.import func_slurp_into_a
.import func_vera_flip_stage
.import func_prep_for_active_buffering

.segment "CODE"

.include "../include/global.inc"
.include "../include/math.inc"
.include "../include/video.inc"

; this runs within an .X and .Y loop so it must preserve .X and .Y
; It is invoked after having just loaded the byte count into .A
.macro PROCESS_POSITIVE_COUNT scratchVar
   sta scratchVar

   phx
      phy
         jsr func_slurp_into_buffer
         ldy #0
      :  lda RAM_VOLATILE_BUF,y
         sta VERA_DATA0
         iny
         cpy scratchVar
         bne :-
      ply
   plx
.endmacro

; same comment as for positive count macro
.macro PROCESS_NEGATIVE_COUNT
   eor #$FF ; for negative values, two's compliment gets the absolute value
   inc      ; (unless special case of -128 which an encoder should never do)
   phy
   tay                          ; .Y now becomes the repeat count
   jsr func_slurp_into_a        ; .A now becomes the byte to repeat
:  sta VERA_DATA0
   dey
   bne :-
   ply
.endmacro

.proc sub_skip_columns: near
   jsr func_slurp_into_a ; (.A holds skip count, where 0 means 0)
   bne @proceed_to_skip
   rts

@proceed_to_skip:
   phy
   tay
@burn_loop:
   lda VERA_DATA0
   dey
   bne @burn_loop
   ply
   rts
.endproc


.proc handle_delta_fli: near
   scratchVar = ZP_VOLATILE_A

   lda #4                              ; slurp 2 words: line skip, line count
   jsr func_slurp_into_buffer
   lda RAM_VOLATILE_BUF+0              ; .A now holds line skip (0-199)
   ldx RAM_VOLATILE_BUF+2              ; .X now holds line count (1-200)

   ; TODO: need logic to suppress first and last lines from writing to VERA

   jsr func_prep_for_active_buffering  ; .A has line skip

@line_loop:                            ; .X is the line countdown

      jsr func_slurp_into_a            ; packet count
      tay                              ; .Y is the packet countdown
      @packet_loop:
         jsr sub_skip_columns
         jsr func_slurp_into_a         ; byte count
         bit #%10000000
         beq @process_positive_count   ; i.e. bit 7 was clear
            PROCESS_NEGATIVE_COUNT
            bra @process_count_done
         @process_positive_count:
            PROCESS_POSITIVE_COUNT scratchVar
         @process_count_done:
       dey
       bne @packet_loop

       ADVANCE_LINE_FOR_ACTIVE_BUFFERING

   dex
   bne @line_loop

   jsr func_vera_flip_stage

   RTS_NO_DETAIL RC_SUCCESS
.endproc
