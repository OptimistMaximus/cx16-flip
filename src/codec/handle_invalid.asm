.export handle_invalid

.segment "CODE"

.include "../include/global.inc"
.include "../include/math.inc"

.proc handle_invalid: near
   U8_COPY_IMM GR8_returnCode, RC_INVALID_CHUNK_TYPE
   U16_COPY_VAR GR16_returnDetail, GR16_chunkType
   rts
.endproc
