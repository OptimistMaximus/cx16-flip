.export handle_fli_copy
.import func_prep_for_active_buffering
.import func_slurp_into_buffer
.import func_vera_flip_stage

.segment "CODE"

.include "../include/global.inc"
.include "../include/video.inc"
.include "../include/vera.inc"

; Note, this frame is extremely rare (in fact I've never encountered one in
;       the wild) so it isn't worth it to optimize for speed.  Instead we'll
;       optimize for size.
;
; Note also, the chunk size will be $FA04 which seems odd because the spec
;      says that the chunk size is the size of the chunk including the
;      chunk size, but apparently this means NOT including the 2 byte
;      chunk type.  Anyway, it's always the full frame of 320x240 ($FA00)
;      so we don't need to look at the stated chunk size.
.proc handle_fli_copy: near
   lda #0 ; full screen
   jsr func_prep_for_active_buffering
   ldy #200
@outer_loop:
   jsr sub_copy_half_line
   jsr sub_copy_half_line
   dey
   bne @outer_loop
   jmp func_vera_flip_stage
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
