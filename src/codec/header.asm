.segment "CODE"

.export func_slurp_header

.include "../include/file.inc"
.include "../include/global.inc"
.include "../include/kernal.inc"
.include "../include/math.inc"
.include "../include/petscii.inc"

;==============================================================================
; func_slurp_header
;
; @effect .A .X .Y holds validation status (maps 1:1 with return codes)
;==============================================================================
.proc func_slurp_header: near

   varSpeed     = ZP_VOLATILE_ABCD
   varHeight    = ZP_VOLATILE_EF
   varDepth     = ZP_VOLATILE_GH
   varTemp1     = ZP_VOLATILE_IJ
   varTemp2     = ZP_VOLATILE_KL

   lda #128 ; header is always 128 bytes
   SLURP_ARRAY RAM_stagingArea
   
   U16_COPY_VAR RAM16_fileType,   RAM_stagingArea+4
   U16_COPY_VAR ZP16_numFrames,   RAM_stagingArea+6
   U16_COPY_VAR ZP16_width,       RAM_stagingArea+8
   U16_COPY_VAR varHeight,        RAM_stagingArea+10 ; for validation
   U8_COPY_VAR  ZP8_height,       RAM_stagingArea+10
   U16_COPY_VAR varDepth,         RAM_stagingArea+12 ; for validation
   U8_COPY_VAR  ZP8_depth,        RAM_stagingArea+12
   U32_COPY_VAR varSpeed,         RAM_stagingArea+16

   ;---------------------------------------------------------------------------
   ; validate file type
   ;
   ; for now, only FLI is supported, so we can just either bail or keep going.
   ; eventually we probably want a ZPBOOL flag where b7 means FLI and b6 means
   ; FLC
   ;---------------------------------------------------------------------------
   U16_CMP_IMM RAM16_fileType, FILE_TYPE_FLI
   beq @fileType_is_cool
   RTS_VAR16_DETAIL RC_UNSUPPORTED_FILE_TYPE, RAM16_fileType
@fileType_is_cool:
   
   ;---------------------------------------------------------------------------
   ; validate width
   ;---------------------------------------------------------------------------
   U16_CMP_IMM ZP16_width, 321
   bcc @width_is_cool
   RTS_VAR16_DETAIL RC_WIDTH_TOO_BIG, ZP16_width
@width_is_cool:

   ;---------------------------------------------------------------------------
   ; validate height
   ;---------------------------------------------------------------------------
   U16_CMP_IMM varHeight, 201
   bcc @height_is_cool
   RTS_VAR16_DETAIL RC_HEIGHT_TOO_BIG, varHeight
@height_is_cool:

   ;---------------------------------------------------------------------------
   ; validate depth
   ;---------------------------------------------------------------------------
   U16_CMP_IMM varDepth, 256
   bcc @depth_is_cool
   RTS_VAR16_DETAIL RC_DEPTH_TOO_BIG, varDepth
@depth_is_cool:

   ;---------------------------------------------------------------------------
   ; validate speed
   ;
   ; FLI has a 32-bit speed variable whose unit is seventieth-of-a-second. The
   ; max value is equivalent to almost 2 years.  That's just plain silly. We'll
   ; make sure it is within reason: 2293 seventieths is 32 seconds.
   ;
   ; TODO: for eventual FLC support, make this check conditional on FLI type.
   ;       for FLC, the delay time (in millis) overrides the speed.
   ;---------------------------------------------------------------------------
   U32_CMP_IMM varSpeed, 2293
   bcc @speed_is_cool
   RTS_VAR16_DETAIL RC_SPEED_TOO_HIGH, varSpeed
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
   ; the upper 2 bytes are zeros, and we only care about the lower 2 anyway.   
   ;---------------------------------------------------------------------------
   U16_COPY_IMM varTemp1, 6
   U16_SLOW_MULTIPLY varTemp2, varSpeed, varTemp1
   U16_COPY_IMM varTemp1, 7
   U16_SLOW_DIVIDE ZP16_delaySyncs, varTemp2, varTemp1

   RTS_NO_DETAIL RC_SUCCESS
.endproc


   
