.export handle_invalid
.import bsod

.segment "CODE"

.include "../include/global.inc"

.proc handle_invalid: near
   BSOD RC_INVALID_CHUNK_TYPE, GR16_chunkType
.endproc
