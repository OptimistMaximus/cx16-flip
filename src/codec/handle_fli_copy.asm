.export handle_fli_copy
.import func_prep_for_active_buffering
.import func_vera_flip_stage

.segment "CODE"

.include "../include/global.inc"
.include "../include/slurp.inc"
.include "../include/video.inc"
.include "../include/vera.inc"

.proc handle_fli_copy: near
   lda #0 ; full screen
   jsr func_prep_for_active_buffering
   ldy #200
@outer_loop:
   lda #160
   jsr func_cache_read_into_vram
   lda #160
   jsr func_cache_read_into_vram
   dey
   bne @outer_loop

   ldx #200
   ldy #0
   jmp func_vera_flip_stage
.endproc
