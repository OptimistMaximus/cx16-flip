.segment "CODE"

.export handle_frame_type

.segment "CODE"

.include "../include/global.inc"

.proc handle_frame_type: near
   RTS_VAR16_DETAIL RC_UNSUPPORTED_CHUNK_TYPE, ZP16_chunkType 
.endproc
