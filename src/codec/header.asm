.export func_slurp_header

.import func_slurp_into_buffer

.include "../include/global.inc"
.include "../include/kernal.inc"
.include "../include/math.inc"
.include "../include/math2.inc"
.include "../include/petscii.inc"

FILE_TYPE_FLI := $AF11

;==============================================================================
; func_slurp_header
;
; @effect .A .X .Y per RTS_xxx_DETAIL semantics
;==============================================================================
.proc func_slurp_header: near

   lda #128 ; header is 128 bytes
   jsr func_slurp_into_buffer

   ;---------------------------------------------------------------------------
   ; Rather than waste time copying values only to bail out during validation,
   ; first just use symbols as effective pointers into the header buffer.
   ; These will be used for validation. After that, we can copy stuff into ZP.
   ;---------------------------------------------------------------------------
   wordPointerFileType  =         RAM_VOLATILE_BUF+4  ; pointer to file type
   wordPointerNumFrames =         RAM_VOLATILE_BUF+6  ; pointer to frames
   wordPointerWidth     =         RAM_VOLATILE_BUF+8  ; pointer to width
   wordPointerHeight    =         RAM_VOLATILE_BUF+10 ; pointer to height
   wordPointerDepth     =         RAM_VOLATILE_BUF+12 ; pointer to depth
   dwordPointerSpeed    =         RAM_VOLATILE_BUF+16 ; pointer to speed

   ;---------------------------------------------------------------------------
   ; validate file type
   ;
   ; This is a bit of overkill since we don't support FLC yet, but just for
   ; fun we'll establish the FLI vs FLC bit in the flags now.
   ;---------------------------------------------------------------------------
   U16_CMP_IMM wordPointerFileType, FILE_TYPE_FLI
   beq @fileType_is_fli
   RTS_VAR16_DETAIL RC_UNSUPPORTED_FILE_TYPE, wordPointerFileType
@fileType_is_fli:

   ;---------------------------------------------------------------------------
   ; validate width
   ;---------------------------------------------------------------------------
   U16_CMP_IMM wordPointerWidth, 321
   bcc @width_is_cool
   RTS_VAR16_DETAIL RC_WIDTH_TOO_BIG, wordPointerWidth
@width_is_cool:

   ;---------------------------------------------------------------------------
   ; validate height
   ;---------------------------------------------------------------------------
   U16_CMP_IMM wordPointerHeight, 201
   bcc @height_is_cool
   RTS_VAR16_DETAIL RC_HEIGHT_TOO_BIG, wordPointerHeight
@height_is_cool:

   ;---------------------------------------------------------------------------
   ; validate depth
   ;---------------------------------------------------------------------------
   U16_CMP_IMM wordPointerDepth, 256
   bcc @depth_is_cool
   RTS_VAR16_DETAIL RC_DEPTH_TOO_BIG, wordPointerDepth
@depth_is_cool:

   ;---------------------------------------------------------------------------
   ; validate speed
   ;
   ; FLI has a 32-bit speed variable whose unit is seventieth-of-a-second. The
   ; max value is equivalent to almost 2 years.  That's just plain silly. We'll
   ; make sure it is within reason: 2293 seventieths is 32 seconds.
   ;---------------------------------------------------------------------------
   U32_CMP_IMM dwordPointerSpeed, 2293
   bcc @speed_is_cool
   RTS_VAR16_DETAIL RC_SPEED_TOO_HIGH, dwordPointerSpeed
@speed_is_cool:

   ;---------------------------------------------------------------------------
   ; convert speed (seventieths) to sixtieths
   ;
   ; basically multiply by 6 then divide by 7.  We already validated that the
   ; value is less than 2293, so there's plenty of room to do the multiply.
   ; Performance is horrendous, but we're only doing this once as we read the
   ; header, so it should not be noticeable.
   ;
   ; We'll keep using the 32-bit variable, which will be fine because we know
   ; the upper 2 bytes are zeros (having just done a validation above).
   ;---------------------------------------------------------------------------
   varTemp      = ZP_VOLATILE_AB
   varDivisor   = ZP_VOLATILE_CD
   varMultiplier = ZP_VOLATILE_E

   U8_COPY_IMM varMultiplier, 6
   U16_SLOW_MULTIPLY varTemp, dwordPointerSpeed, varMultiplier
   U16_COPY_IMM varDivisor, 7
   U16_SLOW_DIVIDE ZP16_delaySyncs, varTemp, varDivisor

   ;---------------------------------------------------------------------------
   ; copy important data out of the volatile buffer and into our ZP vars
   ;---------------------------------------------------------------------------
   U16_COPY_VAR ZP16_numFrames,   wordPointerNumFrames
   U16_COPY_VAR ZP16_width,       wordPointerWidth
   U8_COPY_VAR  ZP8_height,       wordPointerHeight ; copy height (low byte)
   U8_COPY_VAR  ZP8_depth,        wordPointerDepth  ; copy depth (low byte)

   RTS_NO_DETAIL RC_SUCCESS
.endproc



