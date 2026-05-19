.segment "CODE"

.export func_slurp_chunk

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
.include "../include/slurp.inc"

;==============================================================================
; func_slurp_chunk
;
; Reads the chunk size and chunk type, then looks up the appropriate handler
; for the chunk type and invokes it.  If it encountered EOF while reading the
; size and type, it sets the ZPBOOL_flags to indicate that EOF is encountered,
; then returns.
;==============================================================================
.proc func_slurp_chunk: near

   jsr sub_slurp_chunk_preamble
   bit ZPBOOL_flags          ; b7=1 means we hit EOF while reading preamble
   bpl @preamble_slurped     ; so we fall through and return (calling code
   rts                       ; should also check the flags and react), else
@preamble_slurped:           ; preamble was good and it's safe to proceed

   stz ZP8_imageVSyncsElapsed
   jmp (chunk_type_jump_table,x)
.endproc

;==============================================================================
; sub_slurp_chunk_preamble
;
; @effect .X holds the chunk handler jump table offset
;         ZPBOOL_flags b7 set if we hit EOF while reading the chunk preamble
;==============================================================================
.proc sub_slurp_chunk_preamble

   SLURP_INTO_U32 ZP_VOLATILE_ABCD
   SLURP_INTO_U16 GR16_chunkType
   
   jsr KERNAL_READST
   bne @eof ; ACPTR/MACPTR sets read status, which we can check via READST

   jsr func_resolve_chunk_type
   cpx #0
   beq @cannot_resolve_chunk_type
   rts

   ;---------------------------------------------------------------------------
   ; If we get here, it means we couldn't resolve the chunk type. Either the
   ; file is malformed (unlikely), or we are one-byte-off because the previous
   ; chunk had a padding byte that we incorrectly read into the 32-bit chunk
   ; size value, and which has made us one-byte-off in the chunk type too. This
   ; is the most likely (and frequently occurring) situation, so we'll shuffle
   ; the chunk type's high byte into its low byte and then sip another byte off
   ; the stream and put it into the high byte. Then we'll try to resolve again.
   ; If that didn't work, then we weren't in the padding/off-by-one situation
   ; so we'll just proceed with the jump table offset indicating invalid.
   ;---------------------------------------------------------------------------
@cannot_resolve_chunk_type:
   lda GR16_chunkType+1
   sta GR16_chunkType+0
   SLURP_INTO_A
   sta GR16_chunkType+1
   jmp func_resolve_chunk_type

@eof:
   lda #%10000000
   tsb ZPBOOL_flags
   rts
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
   beq @check_types_with_high_byte_00
   cmp #$F1
   beq @check_types_with_high_byte_F1
   SET_OFFSET_TO_ZERO_AND_RETURN

@check_types_with_high_byte_F1:
   lda GR16_chunkType+0
   SET_OFFSET_AND_RETURN_IF_MATCH $FA, $02 ; FRAME_TYPE
   SET_OFFSET_TO_ZERO_AND_RETURN

@check_types_with_high_byte_00:
   lda GR16_chunkType+0
   SET_OFFSET_AND_RETURN_IF_MATCH $0C, $04 ; DELTA_FLI
   SET_OFFSET_AND_RETURN_IF_MATCH $0B, $06 ; COLOR_64
   SET_OFFSET_AND_RETURN_IF_MATCH $04, $08 ; COLOR_256
   SET_OFFSET_AND_RETURN_IF_MATCH $0F, $0A ; BYTE_RUN
;   SET_OFFSET_AND_RETURN_IF_MATCH $10, $0C ; FLI_COPY
   SET_OFFSET_AND_RETURN_IF_MATCH $0D, $0E ; BLACK
   SET_OFFSET_TO_ZERO_AND_RETURN
.endproc
