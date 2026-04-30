.segment "CODE"

.export handle_black

.segment "CODE"

.include "../include/global.inc"

.proc handle_black: near
   RTS_VAR16_DETAIL RC_UNSUPPORTED_CHUNK_TYPE, ZP16_chunkType 
.endproc
