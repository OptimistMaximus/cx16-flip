.export handle_invalid
.import v16_chunkType
.import v8_returnCode
.import v16_returnDetail

.segment "CODE"

.include "./api.inc"
.include "../include/global.inc"
.include "../include/math.inc"

.proc handle_invalid: near
   U8_COPY_IMM v8_returnCode, RC_INVALID_CHUNK_TYPE
   U16_COPY_VAR v16_returnDetail, v16_chunkType
   rts
.endproc
