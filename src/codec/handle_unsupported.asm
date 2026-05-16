.segment "CODE"

.export handle_unsupported
.import bsod

.include "../include/global.inc"

.proc handle_unsupported: near
   BSOD RC_UNSUPPORTED_CHUNK_TYPE, ZP16_chunkType
.endproc
