.export handle_frame_type

.import func_slurp_chunk
.import func_load_image
.import func_load_palette
.import func_cache_load_page
.import func_cache_discard_bytes

.import v8_chunkCount
.import line_skip_array
.import line_count_array
.import v8_returnCode
.import v16_returnDetail

.segment "CODE"

.include "./cache.inc"
.include "../include/global.inc"
.include "../include/vera.inc"
.include "./video.inc"
.include "./api.inc"

;==============================================================================
; handle_frame_type
;==============================================================================
.proc handle_frame_type: near
   stz ZP8_imageVSyncsElapsed       ; i.e. start the frame timer
   SIP_INTO_U16 v16_returnDetail   ; chunk count (is return detail if too many)
   U16_CMP_IMM v16_returnDetail, 5
   bcc @cool_chunks
   U8_COPY_VAR v8_returnCode, RC_TOO_MANY_CHUNKS
   rts
   
@cool_chunks:
   SIP_INTO_OBLIVION 8              ; high byte of chunk count & remaining 8
   U8_COPY_VAR v8_chunkCount, v16_returnDetail ; shuffle to non-volatile

   lda v8_chunkCount              ; zero-chunk frames are a common way to
   cmp #0                         ; make the current image linger longer
   beq @rendering_complete        ; 1-chunk frames are common but optimzing
                                  ; for them has no perceivable benefit.
   jsr sub_render_chunks
   lda v8_returnCode
   beq @success
   rts
@success:
   jsr sub_apply_chunks

@rendering_complete:
   rts
.endproc

.proc sub_render_chunks: near
   ldy #0                         ; .Y is the chunk index
@subchunk_loop:
   phy
      jsr func_slurp_chunk        ; .A is return code
   ply
   lda v8_returnCode
   beq @success
   rts
@success:

   lda ZP8_lineSkip
   sta line_skip_array,y          ; squirrel the line skip
   lda ZP8_lineCount
   sta line_count_array,y         ; squirrel the line count
   iny
   cpy v8_chunkCount
   bne @subchunk_loop
@subchunk_loop_done:
   stz v8_returnCode
   rts
.endproc

.proc sub_apply_chunks: near
   ldy #0
@flip_loop:
   phy
      ldx line_skip_array,y
      cpx #$FF
      beq @flip_palette_instead
      lda line_count_array,y
      jsr func_load_image
      bra @flipped
   @flip_palette_instead:
      jsr func_load_palette
   @flipped:
   ply
   iny
   cpy v8_chunkCount
   bne @flip_loop
   rts
.endproc
