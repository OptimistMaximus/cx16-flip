.segment "CODE"

.export func_slurp_chunk_delta_fli
.export func_slurp_chunk_frame_type
.export func_slurp_chunk_byte_run
.export func_slurp_chunk_color_256
.export func_slurp_chunk_color_64
.export func_slurp_chunk_fli_copy
.export func_slurp_chunk_black

.include "../include/file.inc"
.include "../include/global.inc"
.include "../include/kernal.inc"
.include "../include/math.inc"
.include "../include/math2.inc"
.include "../include/petscii.inc"

;==============================================================================
; func_slurp_chunk
;
; @effect .A .X .Y per RTS_xxx_DETAIL semantics
;==============================================================================
.proc func_slurp_chunk: near

   SLURP_VAR32 ZP32_chunkSize
   SLURP_VAR16 ZP16_chunkType
   
   ; Check the chunk type in order of most popular to least.
   U16_CMP_IMM ZP16_chunkType, CHUNK_DELTA_FLI
   bne :+
   jmp func_slurp_chunk_delta_fli
:

   U16_CMP_IMM ZP16_chunkType, FRAME_TYPE
   bne :+
   jmp func_slurp_chunk_frame_type
:

   U16_CMP_IMM ZP16_chunkType, CHUNK_BYTE_RUN
   bne :+
   jmp func_slurp_chunk_byte_run
:

   U16_CMP_IMM ZP16_chunkType, CHUNK_COLOR_256
   bne :+
   jmp func_slurp_chunk_color_256
:

   U16_CMP_IMM ZP16_chunkType, CHUNK_COLOR_64
   bne :+
   jmp func_slurp_chunk_color_64
:

   U16_CMP_IMM ZP16_chunkType, CHUNK_FLI_COPY
   bne :+
   jmp func_slurp_chunk_fli_copy
:

   U16_CMP_IMM ZP16_chunkType, CHUNK_BLACK
   bne :+
   jmp func_slurp_chunk_black
:

   RTS_VAR16_DETAIL RC_UNSUPPORTED_CHUNK_TYPE, ZP16_chunkType 

.endproc

.proc func_slurp_chunk_delta_fli: near
   RTS_NO_DETAIL RC_SUCCESS
.endproc

.proc func_slurp_chunk_frame_type: near
   RTS_NO_DETAIL RC_SUCCESS
.endproc

.proc func_slurp_chunk_byte_run: near
   RTS_NO_DETAIL RC_SUCCESS
.endproc

.proc func_slurp_chunk_color_256: near
   RTS_NO_DETAIL RC_SUCCESS
.endproc

.proc func_slurp_chunk_color_64: near
   RTS_NO_DETAIL RC_SUCCESS
.endproc

.proc func_slurp_chunk_fli_copy: near
   RTS_NO_DETAIL RC_SUCCESS
.endproc

.proc func_slurp_chunk_black: near
   RTS_NO_DETAIL RC_SUCCESS
.endproc





