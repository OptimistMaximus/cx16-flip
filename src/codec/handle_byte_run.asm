.export handle_byte_run

.segment "CODE"

.include "../include/file.inc"
.include "../include/global.inc"
.include "../include/video.inc"

; this runs within an .X and .Y loop so it must preserve .X and .Y
; It is invoked after having just loaded the byte count into .A
.macro PROCESS_POSITIVE_COUNT
   phy
      tay                          ; .Y now becomes the repeat count
      SLURP_INTO_A                 ; .A now becomes the byte to repeat
   :  sta VERA_DATA0
      dey
      bne :-
   ply
.endmacro

; same comment as for positive count macro
.macro PROCESS_NEGATIVE_COUNT scratchVar
   eor #$FF ; for negative values, two's compliment gets the absolute value
   inc      ; (unless special case of -128 which an encoder should never do)
   sta scratchVar

   phx
      phy
         SLURP_ARRAY RAM_VOLATILE_BUF
         ldy #0
      :  lda RAM_VOLATILE_BUF,y
         sta VERA_DATA0
         iny
         cpy scratchVar
         bne :-
      ply
   plx
.endmacro


.proc handle_byte_run: near

   vramOffset = ZP_VOLATILE_ABC
   copyCount  = ZP_VOLATILE_D
   
   CALC_VRAM_OFFSET_FOR_FULL vramOffset
   SET_VERA_ADDR24_VAR $00, vramOffset, $10

   ldx ZP8_height                     ; .X is the line countdown
@line_loop:

      SLURP_INTO_A                    ; packet count
      tay                             ; .Y is the packet countdown
      @packet_loop:
         SLURP_INTO_A                 ; byte count
         bit #%10000000
         beq @process_positive_count  ; i.e. bit 7 was clear         
            PROCESS_NEGATIVE_COUNT copyCount
            bra @process_count_done
         @process_positive_count:
            PROCESS_POSITIVE_COUNT
         @process_count_done:
       dey
       bne @packet_loop      

   dex
   bne @line_loop
   
   FLIP_LAYERS

   RTS_NO_DETAIL RC_SUCCESS
.endproc
