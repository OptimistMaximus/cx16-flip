.segment "CODE"

.export handle_invalid

.segment "CODE"

.include "../include/global.inc"

.proc handle_invalid: near
   RTS_VAR16_DETAIL RC_INVALID_CHUNK_TYPE, ZP16_chunkType
.endproc
