.export func_slurp_frame
.export func_slurp_chunk

.import handle_invalid
.import handle_color_256
.import handle_color_64
.import handle_delta_fli
.import handle_black
.import handle_byte_run
.import handle_fli_copy
.import bsod

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
.include "../include/slurp.inc"

;==============================================================================
; func_slurp_frame
;
; Reads the next 16 bytes assuming it MUST be a FRAME_TYPE chunk.  Since only
; FLI is supported, this is a reasonable assumption.  The chunk type will be
; sanity-checked, and the chunks field is used to iterate over the sub-chunks.
; After each subchunk, the read tracker is compared against the expected
; chunk size, and the stream is advanced beyond any inferred padding.
;==============================================================================
.proc func_slurp_frame: near
   SLURP_INTO_U32 GR32_chunkSize
   SLURP_INTO_U16 GR16_chunkType
   U16_CMP_IMM GR16_chunkType, $F1FA
   beq @assumption_met
   BSOD RC_UNEXPECTED_CHUNK_TYPE, GR16_chunkType
@assumption_met:

   U16_STZ        GR16_chunkIndex
   SLURP_INTO_U16 GR16_chunkCount
   SLURP_INTO_OBLIVION 8

@subchunk_loop:
   U16_CMP_VAR GR16_chunkIndex, GR16_chunkCount  ; check first in case zero
   beq @subchunk_loop_done
   U32_STZ ZP32_chunkReads
   jsr func_slurp_chunk
   jsr sub_mitigate_padding
   U16_INC     GR16_chunkIndex
   bra @subchunk_loop
@subchunk_loop_done:
   rts
.endproc

.proc sub_mitigate_padding: near
   U32_CMP_VAR ZP32_chunkReads, GR32_chunkSize
   bcc @handle_padding
   rts
@handle_padding:
   SLURP_INTO_A
   U32_CMP_VAR ZP32_chunkReads, GR32_chunkSize
   bne @handle_padding
   rts
.endproc

;==============================================================================
; func_slurp_chunk
;
; Reads the chunk size and chunk type, then looks up the appropriate handler
; for the chunk type and invokes it.
;==============================================================================
.proc func_slurp_chunk: near

   stz ZP8_imageVSyncsElapsed
   U32_STZ ZP32_chunkReads
   SLURP_INTO_U32 GR32_chunkSize
   SLURP_INTO_U16 GR16_chunkType
   jsr func_resolve_chunk_type
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

; @param GR16_chunkType holds the chunk type
; @effect .X holds the jump table offset to the handler
.proc func_resolve_chunk_type: near
   lda GR16_chunkType+1
   bne @invalid_chunk_type

   lda GR16_chunkType+0
   SET_OFFSET_AND_RETURN_IF_MATCH $0C, $02 ; DELTA_FLI
   SET_OFFSET_AND_RETURN_IF_MATCH $0B, $04 ; COLOR_64
   SET_OFFSET_AND_RETURN_IF_MATCH $04, $06 ; COLOR_256
   SET_OFFSET_AND_RETURN_IF_MATCH $0F, $08 ; BYTE_RUN
   SET_OFFSET_AND_RETURN_IF_MATCH $10, $0A ; FLI_COPY
   SET_OFFSET_AND_RETURN_IF_MATCH $0D, $0C ; BLACK
@invalid_chunk_type:
   SET_OFFSET_TO_ZERO_AND_RETURN
.endproc
