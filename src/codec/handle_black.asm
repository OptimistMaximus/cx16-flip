.export handle_black
.import func_prep_for_active_buffering
.import func_vera_flip_stage

.segment "CODE"

.include "../include/global.inc"
.include "../include/vera.inc"
.include "../include/video.inc"

.proc handle_black: near
   lda #0 ; full screen must be color zero
   jsr func_prep_for_active_buffering

   lda #0 ; color zero
   ldy #200
@outer_loop:
   ldx #(320 / 8) ; divide by 8 because 16 STA calls below
@inner_loop:
   sta VERA_DATA0
   sta VERA_DATA0
   sta VERA_DATA0
   sta VERA_DATA0
   sta VERA_DATA0
   sta VERA_DATA0
   sta VERA_DATA0
   sta VERA_DATA0
   dex
   bne @inner_loop
   dey
   bne @outer_loop

   ldx #200
   ldy #0
   jmp func_vera_flip_stage
.endproc
