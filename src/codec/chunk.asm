.export func_slurp_chunk
.export sub_resolve_chunk_type ; exported for unit test purpose only

.import handle_invalid
.import handle_frame_type
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
.word handle_frame_type    ; $F1FA FRAME_TYPE frame with subchunks
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
; for the chunk type and invokes it.
;==============================================================================
.proc func_slurp_chunk: near
   RTS_IF_NO_MORE_BYTES
   SLURP_INTO_U32 GR32_chunkSize
   SLURP_INTO_U16 GR16_chunkType
@resolve_loop:
   jsr sub_resolve_chunk_type       ; resolve
   cpx #0                           ; compare to 0 (invalid) ...
   bne @resolution_done             ; ... if not invalid, we're done!
   lda ZP8_cacheRemaining           ; if no bytes remaining
   beq @resolution_done             ; ... we're also done

   U8_COPY_VAR GR32_chunkSize+0, GR32_chunkSize+1 ; otherwise, shift all bytes
   U8_COPY_VAR GR32_chunkSize+1, GR32_chunkSize+2 ; over by one and slurp in
   U8_COPY_VAR GR32_chunkSize+2, GR32_chunkSize+3 ; the next byte, then try
   U8_COPY_VAR GR32_chunkSize+3, GR16_chunkType+0 ; again
   U8_COPY_VAR GR16_chunkType+0, GR16_chunkType+1
   SLURP_INTO_U8 GR16_chunkType+1
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
; @param GR32_chunkSize holds the chunk size
; @param GR16_chunkType holds the chunk type
; @effect .X holds the jump table offset to the handler (zero means invalid)
;------------------------------------------------------------------------------
.proc sub_resolve_chunk_type: near
   U32_CMP_IMM GR32_chunkSize, 6   ; if chunk size is less than 5,
   bcc @neither_byte_is_cool       ; the type can't possibly be legit

   lda GR16_chunkType+1
   beq @high_byte_is_cool
   cmp #$F1
   beq @high_byte_is_cool
   bra @neither_byte_is_cool

@high_byte_is_cool:
   lda GR16_chunkType+0
   SET_OFFSET_AND_RETURN_IF_MATCH $FA, $02 ; FRAME_TYPE
   SET_OFFSET_AND_RETURN_IF_MATCH $0C, $04 ; DELTA_FLI
   SET_OFFSET_AND_RETURN_IF_MATCH $0B, $06 ; COLOR_64
   SET_OFFSET_AND_RETURN_IF_MATCH $04, $08 ; COLOR_256
   SET_OFFSET_AND_RETURN_IF_MATCH $0F, $0A ; BYTE_RUN
   SET_OFFSET_AND_RETURN_IF_MATCH $10, $0C ; FLI_COPY
   SET_OFFSET_AND_RETURN_IF_MATCH $0D, $0E ; BLACK

@neither_byte_is_cool:
   SET_OFFSET_TO_ZERO_AND_RETURN
.endproc




