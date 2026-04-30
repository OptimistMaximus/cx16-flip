.segment "CODE"

.export handle_unsupported

.segment "CODE"

.include "../include/global.inc"

.proc handle_unsupported: near
   RTS_VAR16_DETAIL RC_UNSUPPORTED_CHUNK_TYPE, ZP16_chunkType 
.endproc
