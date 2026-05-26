.export handle_frame_type

.import func_snooze_if_necessary
.import func_slurp_chunk

.segment "CODE"

.include "../include/global.inc"
.include "../include/slurp.inc"
.include "../include/vera.inc"
.include "../include/video.inc"

.proc handle_frame_type: near
   U16_STZ GR16_speedVsyncs
   SLURP_INTO_U16 GR16_chunkCount
   SLURP_INTO_OBLIVION 8
@subchunk_loop:
   U16_CMP_VAR GR16_chunkIndex, GR16_chunkCount  ; check first in case zero
   beq @subchunk_loop_done
   jsr func_slurp_chunk
   U16_INC GR16_chunkIndex
   bra @subchunk_loop
@subchunk_loop_done:
   jmp func_snooze_if_necessary
.endproc
