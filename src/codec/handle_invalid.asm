.export handle_invalid
.import v16_chunkType

.segment "CODE"

.include "./api.inc"
.include "../include/global.inc"
.include "../include/math.inc"

.proc handle_invalid: near
   U8_COPY_IMM ZP8_returnCode, RC_INVALID_CHUNK_TYPE
   U16_COPY_VAR ZP16_returnDetail, v16_chunkType
   rts
.endproc
