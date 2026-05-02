.segment "CODE"

.export func_slurp_chunk

.import handle_invalid
.import handle_unsupported
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

chunk_type_jump_table:
.word handle_invalid       ; $00
.word handle_invalid       ; $01
.word handle_invalid       ; $02
.word handle_unsupported   ; $03 CEL_DATA    (FLC only)
.word handle_color_256     ; $04 COLOR_256   256-level colour palette
.word handle_invalid       ; $05
.word handle_invalid       ; $06
.word handle_unsupported   ; $07 DELTA_FLC   (FLC only)
.word handle_invalid       ; $08
.word handle_invalid       ; $09
.word handle_invalid       ; $0A
.word handle_color_64      ; $0B COLOR_64    64-level colour palette
.word handle_delta_fli     ; $0C DELTA_FLI   delta image, byte oriented RLE
.word handle_black         ; $0D BLACK       full black frame (rare)
.word handle_invalid       ; $0E
.word handle_byte_run      ; $0F BYTE_RUN    full image, byte oriented RLE
.word handle_fli_copy      ; $10 FLI_COPY    uncompressed image (rare)

.segment "CODE"

.include "../include/file.inc"
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
;
; @effect .A .X .Y per RTS_xxx_DETAIL semantics
;==============================================================================
.proc func_slurp_chunk: near

   SLURP_VAR32 ZP32_chunkSize
   SLURP_VAR16 ZP16_chunkType

   ;---------------------------------------------------------------------------
   ; High byte $00 means we can use the jump table.  The low byte should be a
   ; value from $00 to $2B, so we can safely multiply it by 2 to get the jump
   ; table offset. The FLI subset of chunk types is $10 or less.
   ;
   ; We only get as far as parsing chunks if we already passed header
   ; validation. Header validation already made sure the type was FLI, not FLC.
   ; We'll trust that the file was properly encoded, so only FLI chunk types
   ; will be encountered.
   ;---------------------------------------------------------------------------
   lda ZP16_chunkType+1
   bne @two_byte_chunk_type
   lda ZP16_chunkType+0
   asl
   tax
   jmp (chunk_type_jump_table,x)

@two_byte_chunk_type:
   ;---------------------------------------------------------------------------
   ; There are 5 chunk types whose value is more than $FF, and only one of them
   ; is valid for FLI files. In keeping with the "trust me, bro" mentality,
   ; we assume the file was properly encoded. That means any chunk type whose
   ; high byte wasn't zero MUST be the $F1FA chunk. 
   ;---------------------------------------------------------------------------
   jmp handle_frame_type

.endproc
