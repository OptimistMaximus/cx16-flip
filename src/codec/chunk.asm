.segment "CODE"

.export func_slurp_chunk

.import func_slurp_into_buffer
.import func_slurp_into_a
.import handle_invalid
.import handle_frame_type
.import handle_color_256
.import handle_color_64
.import handle_delta_fli
.import handle_black
.import handle_byte_run
.import handle_fli_copy

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
.word handle_invalid
.word handle_frame_type    ; $F1FA FRAME_TYPE
.word handle_delta_fli     ; $0C   DELTA_FLI  delta image, byte oriented RLE
.word handle_color_64      ; $0B   COLOR_64   64-level color palette
.word handle_color_256     ; $04   COLOR_256  256-level color palette
.word handle_byte_run      ; $0F   BYTE_RUN   full image, byte oriented RLE
.word handle_fli_copy      ; $10   FLI_COPY   uncompressed image (rare)
.word handle_black         ; $0D   BLACK      full black frame (rare)

.segment "CODE"

.include "../include/global.inc"
.include "../include/kernal.inc"
.include "../include/math.inc"
.include "../include/math2.inc"
.include "../include/petscii.inc"

;==============================================================================
; func_slurp_chunk
;
; reads the chunk size and type off the input stream, then decides which
; chunk slurping subroutine to call.  Ideally this should detect invalid
; chunk types like $00EE (beyond the jump table) or $1234 (totally bogus)
; but to keep things simple for now, just assume the data is well-formed.
;==============================================================================
.proc func_slurp_chunk: near

   lda #6 ; 32-bit chunk size, followed by 16-bit chunk type
   jsr func_slurp_into_buffer
   U16_COPY_VAR GOLDEN_chunkType, RAM_VOLATILE_BUF+4

   jsr func_resolve_chunk_type

   ; If the resolved type is zero it means it didn't match anything.
   ; That can happen if a chunk was padded with an extra zero.  If so
   ; we need to offset by one in the volatile buffer, then read one more
   ; byte and stuff it into the chunk type's high byte. Then try again.
   cpx #0
   bne @resolved
   lda RAM_VOLATILE_BUF+5
   sta GOLDEN_chunkType+0
   jsr func_slurp_into_a
   sta GOLDEN_chunkType+1
   jsr func_resolve_chunk_type
@resolved:

   jmp (chunk_type_jump_table,x)

.endproc

.macro SET_OFFSET_AND_RETURN_IF_MATCH chunkTypeLowerByte, jumpTableOffset
   cmp #chunkTypeLowerByte
   bne :+
   ldx #jumpTableOffset
   rts
:
.endmacro

.macro SET_OFFSET_TO_ZERO_AND_RETURN
   ldx #$00
   rts
.endmacro

; @param GOLDEN_chunkType holds the chunk type
; @effect .X holds the jump table offset to the handler
.proc func_resolve_chunk_type: near
   lda GOLDEN_chunkType+1
   beq @check_types_with_high_byte_00
   cmp #$F1
   beq @check_types_with_high_byte_F1
   SET_OFFSET_TO_ZERO_AND_RETURN

@check_types_with_high_byte_F1:
   lda GOLDEN_chunkType+0
   SET_OFFSET_AND_RETURN_IF_MATCH $FA, $02 ; FRAME_TYPE
   SET_OFFSET_TO_ZERO_AND_RETURN

@check_types_with_high_byte_00:
   lda GOLDEN_chunkType+0
   SET_OFFSET_AND_RETURN_IF_MATCH $0C, $04 ; DELTA_FLI
   SET_OFFSET_AND_RETURN_IF_MATCH $0B, $06 ; COLOR_64
   SET_OFFSET_AND_RETURN_IF_MATCH $04, $08 ; COLOR_256
   SET_OFFSET_AND_RETURN_IF_MATCH $0F, $0A ; BYTE_RUN
   SET_OFFSET_AND_RETURN_IF_MATCH $10, $0C ; FLI_COPY
   SET_OFFSET_AND_RETURN_IF_MATCH $0D, $0E ; BLACK
   SET_OFFSET_TO_ZERO_AND_RETURN
.endproc
