.segment "CODE"

.export handle_byte_run

.segment "CODE"

.include "../include/global.inc"

.proc handle_byte_run: near
   RTS_VAR16_DETAIL RC_UNSUPPORTED_CHUNK_TYPE, ZP16_chunkType
.endproc
