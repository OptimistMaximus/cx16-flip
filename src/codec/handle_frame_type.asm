.export handle_frame_type

.import func_snooze_if_necessary
.import func_slurp_chunk
.import func_vera_flip_stage
.import func_load_palette
.import bsod

.segment "CODE"

.include "../include/global.inc"
.include "../include/slurp.inc"
.include "../include/vera.inc"
.include "../include/video.inc"

;==============================================================================
; handle_frame_type
.proc handle_frame_type: near
   stz ZP8_imageVSyncsElapsed     ; i.e. start the frame timer
   SLURP_INTO_U8 GR8_chunkCount   ; low byte of chunk count       
   SLURP_INTO_OBLIVION 9          ; high byte of chunk count & remaining 8

   lda #0                               
   cmp GR8_chunkCount             ; zero-chunk frames are a common way to
   beq @rendering_complete        ; make the current image linger as is

   jsr sub_render_chunks
   jsr sub_apply_chunks

@rendering_complete:
   jmp func_snooze_if_necessary
.endproc

.proc sub_render_chunks: near
   ldy #0                         ; .Y is the chunk index
@subchunk_loop:
   phy
      jsr func_slurp_chunk
   ply
   sta CONST_skipArray,y       ; squirrel the line skip
   txa
   sta CONST_countArray,y      ; squirrel the line count
   iny
   cpy GR8_chunkCount
   bne @subchunk_loop
@subchunk_loop_done:
   rts
.endproc

.proc sub_apply_chunks: near
   ldy #0
@flip_loop:
   lda CONST_countArray,y
   beq @flip_palette_instead
   tax
   lda CONST_skipArray,y
   phy
      jsr func_vera_flip_stage
   ply
   bra @flipped
@flip_palette_instead:
   phy
      jsr func_load_palette
   ply
@flipped:
   iny
   cpy GR8_chunkCount
   bne @flip_loop 
   rts
.endproc
