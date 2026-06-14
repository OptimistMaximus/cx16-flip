.export handle_fli_copy

.import func_cache_load_page
.import func_cache_read_into_vram

.segment "CODE"

.include "../include/cache.inc"
.include "../include/global.inc"
.include "../include/video.inc"
.include "../include/vera.inc"

.proc handle_fli_copy: near
   SET_VRAM_ADDR_FOR_FULL_LINE
   ldy #200
@outer_loop:
   jsr sip_half
   jsr sip_half
   dey
   bne @outer_loop
   U8_COPY_IMM ZP8_lineSkip, 0
   U8_COPY_IMM ZP8_lineCount, 200
   stz GR8_returnCode
   rts
.endproc

.proc sip_half: near
   lda #160
   SIP_INTO_VRAM
   rts
.endproc
