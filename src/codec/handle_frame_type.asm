.export handle_frame_type

.import func_snooze_if_necessary
.import func_slurp_chunk
.import func_load_image
.import func_load_palette
.import func_cache_load_page
.import func_cache_discard_bytes

.segment "CODE"

.include "../include/cache.inc"
.include "../include/global.inc"
.include "../include/vera.inc"
.include "../include/video.inc"

;==============================================================================
; handle_frame_type
.proc handle_frame_type: near
   stz ZP8_imageVSyncsElapsed     ; i.e. start the frame timer
   SIP_INTO_U8 GR8_chunkCount     ; low byte of chunk count
   SIP_INTO_OBLIVION 9            ; high byte of chunk count & remaining 8

   lda GR8_chunkCount             ; zero-chunk frames are a common way to
   cmp #0                         ; make the current image linger longer
   beq @rendering_complete        ; 1-chunk frames are common but optimzing
                                  ; for them has no perceivable benefit.
   jsr sub_render_chunks
   lda GR8_returnCode
   beq @success
   rts
@success:
   jsr sub_apply_chunks

@rendering_complete:
   jmp func_snooze_if_necessary
.endproc

.proc sub_render_chunks: near
   ldy #0                         ; .Y is the chunk index
@subchunk_loop:
   phy
      jsr func_slurp_chunk        ; .A is return code
   ply
   lda GR8_returnCode
   beq @success
   rts
@success:
   
   lda ZP8_lineSkip
   sta CONST_skipArray,y          ; squirrel the line skip
   lda ZP8_lineCount
   sta CONST_countArray,y         ; squirrel the line count
   iny
   cpy GR8_chunkCount
   bne @subchunk_loop
@subchunk_loop_done:
   stz GR8_returnCode
   rts
.endproc

.proc sub_apply_chunks: near
   ldy #0
@flip_loop:
   phy
      ldx CONST_skipArray,y
      cpx #$FF
      beq @flip_palette_instead
      lda CONST_countArray,y
      jsr func_load_image
      bra @flipped
   @flip_palette_instead:
      jsr func_load_palette
   @flipped:
   ply
   iny
   cpy GR8_chunkCount
   bne @flip_loop
   rts
.endproc
