.segment "CODE"

.export func_slurp_chunk

.segment "RODATA"

;##############################################################################
; there are some "holes" in the frame type identifiers.  These are
; represented by a jump to a subroutine that always returns an error.
;
; For now, we only support the subset for FLI files.  Basic FLC might
; be supported next. It's unlikely any of the fancy extensions will
; be supported, but just in case, they are all listed here with placeholders.
;##############################################################################

chunk_type_jump_table:
.word handle_invalid       ; $00
.word handle_invalid       ; $01
.word handle_invalid       ; $02
.word handle_unsupported   ; $03 CEL_DATA    registration and transparency
.word handle_color_256     ; $04 COLOR_256   256-level colour palette
.word handle_invalid       ; $05
.word handle_invalid       ; $06
.word handle_unsupported   ; $07 DELTA_FLC   delta image, word oriented RLE
.word handle_invalid       ; $08
.word handle_invalid       ; $09
.word handle_invalid       ; $0A
.word handle_color_64      ; $0B COLOR_64    64-level colour palette
.word handle_delta_fli     ; $0C DELTA_FLI   delta image, byte oriented RLE
.word handle_black         ; $0D BLACK       full black frame (rare)
.word handle_invalid       ; $0E
.word handle_byte_run      ; $0F BYTE_RUN    full image, byte oriented RLE
.word handle_fli_copy      ; $10 FLI_COPY    uncompressed image (rare)
.word handle_invalid       ; $11
.word handle_unsupported   ; $12 PSTAMP      postage stamp
.word handle_invalid       ; $13
.word handle_invalid       ; $14
.word handle_invalid       ; $15
.word handle_invalid       ; $16
.word handle_invalid       ; $17
.word handle_invalid       ; $18
.word handle_unsupported   ; $19 DTA_BRUN    full image, pixel oriented RLE
.word handle_unsupported   ; $1A DTA_COPY    uncompressed image
.word handle_unsupported   ; $1B DTA_LC      delta image, pixel oriented RLE
.word handle_invalid       ; $1C
.word handle_invalid       ; $1D
.word handle_invalid       ; $1E
.word handle_unsupported   ; $1F LABEL       frame label
.word handle_unsupported   ; $20 BMP_MASK    bitmap mask
.word handle_unsupported   ; $21 MLEV_MASK   multilevel mask
.word handle_unsupported   ; $22 SEGMENT     segment information
.word handle_unsupported   ; $23 KEY_IMAGE   key image
.word handle_unsupported   ; $24 KEY_PAL     key palette
.word handle_unsupported   ; $25 REGION      region of frame differences
.word handle_unsupported   ; $26 WAVE        digitized audio
.word handle_unsupported   ; $27 USERSTRING  general purpose user data
.word handle_unsupported   ; $28 RGN_MASK    region mask
.word handle_unsupported   ; $29 LABELEX     extended frame label
.word handle_unsupported   ; $2A SHIFT       scanline delta shifts
.word handle_unsupported   ; $2B PATHMAP     path map

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
   ; table offset.
   ;--------------------------------------------------------------------------- 
   lda ZP16_chunkType+1
   bne @fancy_f1_type
   lda ZP16_chunkType+0
   asl
   tax
   jmp (chunk_type_jump_table,x)
   
@fancy_f1_type:
   ;--------------------------------------------------------------------------- 
   ; If the high byte wasn't zero, we'll assume it was $F1, so we only need to
   ; check the low byte to see how to handle it.  Since this isn't a simple
   ; jump table, we'll check in order of popularity.
   ;--------------------------------------------------------------------------- 
   lda ZP16_chunkType+0
   cmp #$FA                        ; $F1FA FRAME_TYPE     frame chunk
   bne :+
   jmp handle_frame_type  
:
      
   cmp #$00                        ; $F100 PREFIX_TYPE
   bne :+
   jmp handle_unsupported  
:

   cmp #$FC                        ; $F1FC HUFFMAN_TABLE
   bne :+
   jmp handle_unsupported  
:

   cmp #$E0                        ; $F1F0 SCRIPT_CHUNK
   bne :+
   jmp handle_unsupported  
:

   cmp #$FB                        ; $F1FB SEGMENT_TABLE
   bne :+
   jmp handle_unsupported  
:
   
   jmp handle_unsupported

.endproc

.proc handle_invalid: near
   RTS_VAR16_DETAIL RC_INVALID_CHUNK_TYPE, ZP16_chunkType 
.endproc

.proc handle_unsupported: near
   RTS_VAR16_DETAIL RC_UNSUPPORTED_CHUNK_TYPE, ZP16_chunkType 
.endproc

.proc handle_frame_type: near
   RTS_VAR16_DETAIL RC_UNSUPPORTED_CHUNK_TYPE, ZP16_chunkType 
.endproc

.proc handle_color_256: near
   RTS_VAR16_DETAIL RC_UNSUPPORTED_CHUNK_TYPE, ZP16_chunkType 
.endproc

.proc handle_color_64: near
   RTS_VAR16_DETAIL RC_UNSUPPORTED_CHUNK_TYPE, ZP16_chunkType 
.endproc

.proc handle_delta_fli: near
   RTS_VAR16_DETAIL RC_UNSUPPORTED_CHUNK_TYPE, ZP16_chunkType 
.endproc

.proc handle_black: near
   RTS_VAR16_DETAIL RC_UNSUPPORTED_CHUNK_TYPE, ZP16_chunkType 
.endproc

.proc handle_byte_run: near
   RTS_VAR16_DETAIL RC_UNSUPPORTED_CHUNK_TYPE, ZP16_chunkType 
.endproc

.proc handle_fli_copy: near
   RTS_VAR16_DETAIL RC_UNSUPPORTED_CHUNK_TYPE, ZP16_chunkType 
.endproc
