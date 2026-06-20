.export func_slurp_chunk
.export func_slurp_frame
.export sub_resolve_chunk_type ; exported for unit test purpose only
.export sub_resolve_frame_type ; exported for unit test purpose only

.import handle_invalid
.import handle_frame_type
.import handle_color_256
.import handle_color_64
.import handle_delta_fli
.import handle_black
.import handle_byte_run
.import handle_fli_copy
.import func_cache_load_page

.import v32_chunkSize
.import v16_chunkType

.segment "RODATA"

;##############################################################################
; There are quite a few holes in the chunk type numbers if  arranged in order
; but not so many as to make a jump table out of the question.  These "holes"
; will jump to a subroutine that always returns an error.
;
; We only support FLI, and the header validator is expected to error out if
; the header's file type indicates FLC.  Given that, and assuming the file is
; properly encoded, we should only ever encounter FLI chunk types.  So, the
; jump table only needs to go as high as the FLI chunk numbers go.
;
; There are 5 more chunk types with a 16-bit value that all have high byte $F1,
; and only one of them is appropriate for FLI files. So, in keeping with the
; "trust me, bro" mentality we'll just check to see if the high byte is zero
; or not. If it's zero, we'll assume it's a valid FLI chunk, else we'll assume
; it's $F1FA.
;##############################################################################

chunk_type_jump_table:     ; listed in order of most to least frequent
.word handle_invalid       ; $00              (not a real type, i.e. invalid)
.word handle_frame_type    ; $F1FA FRAME_TYPE frame with subchunks
.word handle_delta_fli     ; $0C   DELTA_FLI  delta image, byte oriented RLE
.word handle_color_64      ; $0B   COLOR_64   64-level color palette
.word handle_color_256     ; $04   COLOR_256  256-level color palette
.word handle_byte_run      ; $0F   BYTE_RUN   full image, byte oriented RLE
.word handle_fli_copy      ; $10   FLI_COPY   uncompressed image (rare)
.word handle_black         ; $0D   BLACK      full black frame (rare)

.segment "CODE"

.include "./api.inc"
.include "./cache.inc"
.include "../include/global.inc"
.include "../include/kernal.inc"
.include "../include/math.inc"
.include "../include/math2.inc"
.include "../include/petscii.inc"

;==============================================================================
; func_slurp_chunk
;
; Reads the chunk size and chunk type, then looks up the appropriate handler
; for the chunk type and jumps to it. Each handler is obligated to render
; that frame into the image buffer or palette buffer (as appropriate) and
; update ZP8_lineSkip and ZP8_lineCount as follows (while preserving .Y)
;
; @effect ZP8_lineSkip holds the line skip ($FF if color chunk)
; @effect ZP8_lineCount holds line count ($FF if color chunk)
; @effect .X clobbered
; @effect .Y clobbered
;
; This works fine because FLI format has a maximum height of 200, so anything
; over 200 can be used to signify other stuff
;==============================================================================
.proc func_slurp_chunk: near
   SIP_INTO_U32 v32_chunkSize
   SIP_INTO_U16 v16_chunkType
@resolve_loop:
   jsr sub_resolve_chunk_type       ; resolve
   cpx #0                           ; compare to 0 (invalid) ...
   bne @resolution_done             ; ... if not invalid, we're done!
   jsr sub_shuffle_preamble
   jsr sub_resolve_chunk_type       ; resolve
@resolution_done:
   jmp (chunk_type_jump_table,x)
.endproc

;==============================================================================
; func_slurp_frame
;
; Reads the chunk size and chunk type, then verifies if the chunk is indeed of
; type FRAME_TYPE.  If so, it jumps to its appropriate handler. If not, it
; shuffles in another byte from the input stream and evaluates again.  In this
; way it can easily handle padding of 1 zero (which seems to be about 99.99%
; of the padding found in FLI files in the wild).  It also works well for any
; arbitrary padding, so long as the frame after the padding doesn't happen to
; have the low two bytes of its chunk size as exactly $FA,$F1.  In this case
; the file parsing will go awry. But it is a concious trade-off because it
; means we don't need to keep track of 32-byte stream offsets (which is a
; performance killer for an 8-bit chip)
;
; @effect .X clobbered
; @effect .Y clobbered
;==============================================================================
.proc func_slurp_frame: near
   SIP_INTO_U32 v32_chunkSize
   SIP_INTO_U16 v16_chunkType
@resolve_loop:
   jsr sub_resolve_frame_type       ; resolve
   cpx #0                           ; compare to 0 (invalid) ...
   bne @resolution_done             ; ... if not invalid, we're done!
   jsr sub_shuffle_preamble
   bra @resolve_loop
@resolution_done:
   jmp (chunk_type_jump_table,x)
.endproc

.macro SET_OFFSET_AND_RETURN_IF_MATCH chunkTypeLowerByte, jumpTableOffset
   cmp #chunkTypeLowerByte       ; compare .A with the lower byte
   bne :+                        ; if it's not equal, skip ahead
   ldx #jumpTableOffset          ; if we fall through to here then it's legit
   rts
:
.endmacro

.macro SET_OFFSET_TO_ZERO_AND_RETURN
   ldx #$00
   rts
.endmacro

;------------------------------------------------------------------------------
; sub_resolve_chunk_type
; @param v32_chunkSize holds the chunk size
; @param v16_chunkType holds the chunk type
; @effect .X holds the jump table offset to the handler (zero means invalid)
;------------------------------------------------------------------------------
.proc sub_resolve_chunk_type: near
   lda v16_chunkType+1
   bne @mismatch
   lda v16_chunkType+0
   SET_OFFSET_AND_RETURN_IF_MATCH $0C, $04 ; DELTA_FLI
   SET_OFFSET_AND_RETURN_IF_MATCH $0B, $06 ; COLOR_64
   SET_OFFSET_AND_RETURN_IF_MATCH $04, $08 ; COLOR_256
   SET_OFFSET_AND_RETURN_IF_MATCH $0F, $0A ; BYTE_RUN
   SET_OFFSET_AND_RETURN_IF_MATCH $10, $0C ; FLI_COPY
   SET_OFFSET_AND_RETURN_IF_MATCH $0D, $0E ; BLACK
@mismatch:
   SET_OFFSET_TO_ZERO_AND_RETURN
.endproc

.proc sub_resolve_frame_type: near
   lda v16_chunkType+1
   cmp #$F1
   bne @mismatch
   lda v16_chunkType+0
   SET_OFFSET_AND_RETURN_IF_MATCH $FA, $02 ; FRAME_TYPE
@mismatch:
   SET_OFFSET_TO_ZERO_AND_RETURN
.endproc

.proc sub_shuffle_preamble: near
   U8_COPY_VAR v32_chunkSize+0, v32_chunkSize+1 ; otherwise, shift all bytes
   U8_COPY_VAR v32_chunkSize+1, v32_chunkSize+2 ; over by one and slurp in
   U8_COPY_VAR v32_chunkSize+2, v32_chunkSize+3 ; the next byte, then try
   U8_COPY_VAR v32_chunkSize+3, v16_chunkType+0 ; again
   U8_COPY_VAR v16_chunkType+0, v16_chunkType+1
   SIP_INTO_U8 v16_chunkType+1
   rts
.endproc

