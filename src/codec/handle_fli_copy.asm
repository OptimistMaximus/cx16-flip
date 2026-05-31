.export handle_fli_copy

.import func_cache_read_into_vram

.segment "CODE"

.include "../include/global.inc"
.include "../include/slurp.inc"
.include "../include/video.inc"
.include "../include/vera.inc"

.proc handle_fli_copy: near
   phy
      SET_VRAM_ADDR_FOR_FULL_LINE
      ldy #200
   @outer_loop:
      lda #160
      jsr func_cache_read_into_vram
      lda #160
      jsr func_cache_read_into_vram
      dey
      bne @outer_loop
   ply
   U8_COPY_IMM ZP8_lineSkip, 0
   U8_COPY_IMM ZP8_lineCount, 200
   rts
.endproc
