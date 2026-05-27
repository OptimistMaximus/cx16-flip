.export handle_frame_type

.import func_snooze_if_necessary
.import func_slurp_chunk
.import func_vera_flip_stage

.segment "CODE"

.include "../include/global.inc"
.include "../include/slurp.inc"
.include "../include/vera.inc"
.include "../include/video.inc"

.proc handle_frame_type: near
   stz ZP8_imageVSyncsElapsed           ; i.e. start the frame timer
   SLURP_INTO_U16 GR16_chunkCount
   SLURP_INTO_OBLIVION 8

   U16_CMP_IMM GR16_chunkCount, 0
   beq @rendering_complete

   U16_STZ GR16_chunkIndex
@subchunk_loop:
   jsr func_slurp_chunk
   U16_INC GR16_chunkIndex
   U16_CMP_VAR GR16_chunkIndex, GR16_chunkCount
   bne @subchunk_loop
@subchunk_loop_done:
   ldx #200
   ldy #0
   jsr func_vera_flip_stage

@rendering_complete:
   jmp func_snooze_if_necessary
.endproc
