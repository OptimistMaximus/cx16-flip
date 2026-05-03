.export handle_frame_type

.segment "CODE"

.include "../include/file.inc"
.include "../include/global.inc"

.proc handle_frame_type: near

   ; There are 10 bytes after the size & type. For FLI support, we only care
   ; about the immediate next 2 bytes which is the number of sub-chunks to
   ; follow.  The remaining 8 are only needed if we eventually support FLC.
   SLURP_VAR16 ZP16_numSubChunks
   SLURP_ARRAY_IMM 8, RAM_VOLATILE_BUF
   RTS_NO_DETAIL RC_SUCCESS
.endproc
