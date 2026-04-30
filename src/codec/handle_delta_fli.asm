.segment "CODE"

.export handle_delta_fli

.segment "CODE"

.include "../include/global.inc"

.proc handle_delta_fli: near
   RTS_VAR16_DETAIL RC_UNSUPPORTED_CHUNK_TYPE, ZP16_chunkType 
.endproc
