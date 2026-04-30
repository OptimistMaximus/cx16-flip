.segment "CODE"

.export handle_color_256

.segment "CODE"

.include "../include/global.inc"

.proc handle_color_256: near
   RTS_VAR16_DETAIL RC_UNSUPPORTED_CHUNK_TYPE, ZP16_chunkType 
.endproc
