.export handle_frame_type

.import func_slurp_into_buffer

.segment "CODE"

.include "../include/global.inc"
.include "../include/math.inc"

.proc handle_frame_type: near

   ; There are 10 bytes after the size & type. For FLI support, we only care
   ; about the immediate next 2 bytes which is the number of sub-chunks to
   ; follow.  The remaining 8 are only needed if we eventually support FLC.
   lda #10
   jsr func_slurp_into_buffer
   U16_COPY_VAR ZP16_numSubChunks, RAM_VOLATILE_BUF
   rts
.endproc
