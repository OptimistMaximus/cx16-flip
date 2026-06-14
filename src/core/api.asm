.import func_init_vram_table
.import func_vera_setup
.import func_vera_restore
.import func_cache_init
.import func_slurp_header
.import func_slurp_frame

.segment "DLL_API"

.include "../include/global.inc"
.include "../include/math.inc"

;==============================================================================
; VIDEO DRIVER ENTRY POINTS
;
; The first 9 bytes of the video driver library (wherever it is loaded) are
; a jump table holding the addresses of its three "public API" subroutines.
;==============================================================================
jmp video_driver_init
jmp video_driver_next
jmp video_driver_done

.proc video_driver_init: near
   jsr func_init_vram_table
   jsr func_vera_setup
   jsr func_cache_init
   jsr func_slurp_header
   U16_STZ GR16_frameIndex
   lda #0
   rts   
.endproc

.proc video_driver_next: near
   jsr func_slurp_frame
   lda GR8_returnCode
   beq @success
   ldx #<GR16_returnDetail
   ldy #>GR16_returnDetail
   rts
@success:
   U16_INC     GR16_frameIndex
   U16_CMP_VAR GR16_frameIndex, GR16_frameCount
   lda #0
   rts
.endproc

.proc video_driver_done: near
   jmp func_vera_restore
.endproc
