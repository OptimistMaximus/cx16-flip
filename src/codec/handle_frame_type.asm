.export handle_frame_type

.segment "CODE"

.include "../include/global.inc"
.include "../include/math.inc"
.include "../include/slurp.inc"

.proc handle_frame_type: near

   ; There are 10 bytes after the size & type. For FLI support, only the
   ; next 2 bytes are interesting (the number of subchunks) but we don't
   ; really care about them because we instead use byte counts to figure
   ; out when we're done (since there's no other way to know when a file
   ; has arbitrary padding the end of the chunk)
   SLURP_INTO_OBLIVION 10
   rts
.endproc
