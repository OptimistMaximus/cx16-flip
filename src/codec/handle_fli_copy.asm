.export handle_fli_copy
.import func_prep_for_active_buffering
.import func_slurp_into_buffer
.import func_vera_flip_stage
.import func_snooze_if_necessary

.segment "CODE"

.include "../include/global.inc"
.include "../include/video.inc"
.include "../include/vera.inc"

.proc handle_fli_copy: near
   lda #0 ; full screen
   jsr func_prep_for_active_buffering
   ldy #200
@outer_loop:
   jsr sub_copy_half_line
   jsr sub_copy_half_line
   dey
   bne @outer_loop
   jsr func_vera_flip_stage
   jmp func_snooze_if_necessary
.endproc

.proc sub_copy_half_line: near
   lda #160
   phy
      jsr func_slurp_into_buffer
   ply
   ldx #0
@inner_loop:
   lda RAM_VOLATILE_BUF,x
   sta VERA_DATA0
   inx
   cpx #160
   bne @inner_loop
   rts
.endproc
