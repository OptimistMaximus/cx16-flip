.export handle_black

.segment "CODE"

.include "../include/global.inc"
.include "../include/vera.inc"
.include "./video.inc"

;==============================================================================
; handle_black
;
; Populates staging area with color zero for all 200 lines.
;==============================================================================
.proc handle_black: near
   SET_VRAM_ADDR_FOR_FULL_LINE
   lda #0 ; color zero
   ldy #200
@outer_loop:
   ldx #(320 / 4) ; divide by 4 because 4 STA calls below
@inner_loop:
   sta VERA_DATA0
   sta VERA_DATA0
   sta VERA_DATA0
   sta VERA_DATA0
   dex
   bne @inner_loop
   dey
   bne @outer_loop
   U8_COPY_IMM ZP8_lineSkip, 0
   U8_COPY_IMM ZP8_lineCount, 200
   stz GR8_returnCode
   rts
.endproc
