.export handle_delta_fli

.segment "CODE"

.include "../include/file.inc"
.include "../include/global.inc"
.include "../include/math.inc"
.include "../include/video.inc"

; this runs within an .X and .Y loop so it must preserve .X and .Y
; It is invoked after having just loaded the byte count into .A
.macro PROCESS_POSITIVE_COUNT scratchVar
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

; same comment as for positive count macro
.macro PROCESS_NEGATIVE_COUNT 
   eor #$FF ; for negative values, two's compliment gets the absolute value
   inc      ; (unless special case of -128 which an encoder should never do)
   phy
   tay                          ; .Y now becomes the repeat count
   SLURP_INTO_A                 ; .A now becomes the byte to repeat
:  sta VERA_DATA0
   dey
   bne :-
   ply
.endmacro

; skip column by doing reads (.A holds skip count, where 0 means 0)
.macro BURN_PIXELS
   beq @burn_done
   phy
   tay
@burn_loop:
   lda VERA_DATA0
   dey
   bne @burn_loop
   ply
@burn_done:
.endmacro


.proc handle_delta_fli: near

   vramOffset = ZP_VOLATILE_ABC
   copyCount  = ZP_VOLATILE_D

   lineSkip   = ZP_VOLATILE_EF        ; for FLI, only low byte is relevant
   lineCount  = ZP_VOLATILE_GH        ; for FLI, only low byte is relevant
   scratch    = ZP_VOLATILE_IJ
   
   SLURP_VAR16 lineSkip
   SLURP_VAR16 lineCount
   
   CALC_VRAM_OFFSET_FOR_DELTA vramOffset, lineSkip, scratch
   SET_VERA_ADDR24_VAR $00, vramOffset, $10

   ldx lineCount                      ; .X is the line countdown
@line_loop:

      SLURP_INTO_A                    ; packet count
      tay                             ; .Y is the packet countdown
      @packet_loop:
         SLURP_INTO_A                 ; column skip
         BURN_PIXELS                  ; actually skip
         SLURP_INTO_A                 ; byte count
         bit #%10000000
         beq @process_positive_count  ; i.e. bit 7 was clear         
            PROCESS_NEGATIVE_COUNT 
            bra @process_count_done
         @process_positive_count:
            PROCESS_POSITIVE_COUNT copyCount
         @process_count_done:
       dey
       bne @packet_loop

       U24_ADD_IMM vramOffset, 320    ; advance to the next line
       SET_VERA_ADDR24_VAR $00, vramOffset, $10

   dex
   bne @line_loop
   
   FLIP_LAYERS

   RTS_NO_DETAIL RC_SUCCESS
.endproc
