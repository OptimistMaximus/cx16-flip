.export handle_frame_type

.segment "CODE"

.include "../include/global.inc"
.include "../include/math.inc"
.include "../include/slurp.inc"

.proc handle_frame_type: near

   ; There are 10 bytes after the size & type. For FLI support, we only care
   ; about the immediate next 2 bytes which is the number of sub-chunks to
   ; follow.  The remaining 8 are only needed if we eventually support FLC.
   SLURP_INTO_BUFFER_IMM 10, RAM_VOLATILE_BUF
   rts
.endproc
