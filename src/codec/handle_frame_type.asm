.export handle_frame_type

.import func_snooze_if_necessary
.import func_slurp_chunk

.segment "CODE"

.include "../include/global.inc"
.include "../include/slurp.inc"
.include "../include/vera.inc"
.include "../include/video.inc"

.proc handle_frame_type: near
   stz ZP8_imageVSyncsElapsed
   SLURP_INTO_U16 GR16_chunkCount
   SLURP_INTO_OBLIVION 8

   U16_CMP_IMM GR16_chunkCount, 0
   beq @subchunk_loop_done

   U16_STZ GR16_chunkIndex
@subchunk_loop:
   jsr func_slurp_chunk
   U16_INC GR16_chunkIndex
   U16_CMP_VAR GR16_chunkIndex, GR16_chunkCount
   bne @subchunk_loop
@subchunk_loop_done:
   jmp func_snooze_if_necessary
.endproc
