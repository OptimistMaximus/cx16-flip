.export func_slurp_header

.import bsod
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
; This must be the very first thing called after opening the file input stream
;==============================================================================
.proc func_slurp_header: near

   U32_STZ ZP32_totalTracker

   lda #128 ; header is 128 bytes
   jsr func_slurp_into_buffer

   ;---------------------------------------------------------------------------
   ; Rather than waste time copying values only to bail out during validation,
   ; first just use symbols as effective pointers into the header buffer.
   ; These will be used for validation. After that, we can copy stuff into ZP.
   ;---------------------------------------------------------------------------
   dwordPointerFileSize =         RAM_VOLATILE_BUF+0  ; pointer to file size
   wordPointerFileType  =         RAM_VOLATILE_BUF+4  ; pointer to file type
   dwordPointerSpeed    =         RAM_VOLATILE_BUF+16 ; pointer to speed

   ;---------------------------------------------------------------------------
   ; validate file type
   ;---------------------------------------------------------------------------
   U16_CMP_IMM wordPointerFileType, FILE_TYPE_FLI
   beq @fileType_is_fli
   BSOD RC_UNSUPPORTED_FILE_TYPE, wordPointerFileType
@fileType_is_fli:

   ;---------------------------------------------------------------------------
   ; validate width and height
   ;
   ; A properly encoded FLI should have these set to zero, since FLI files are
   ; all implicitly 320 x 200.  But it seems that many encoders will set them
   ; to 320 and 200 anyway. We'll tolerate either zeros or 320 x 200.
   ;---------------------------------------------------------------------------

   ; TODO: validate height and width

   ;---------------------------------------------------------------------------
   ; validate speed
   ;
   ; FLI has a 32-bit speed variable whose unit is seventieth-of-a-second. The
   ; max value is equivalent to almost 2 years.  That's just plain silly. We'll
   ; make sure it is within reason: 2293 seventieths is 32 seconds.
   ;---------------------------------------------------------------------------
   U32_CMP_IMM dwordPointerSpeed, 2293
   bcc @speed_is_cool
   BSOD RC_SPEED_TOO_HIGH, dwordPointerSpeed
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
   ; store variables
   ;---------------------------------------------------------------------------
   U32_COPY_VAR ZP32_totalSize, dwordPointerFileSize

   rts
.endproc



