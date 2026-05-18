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
   ; max value is equivalent to almost 2 years.  That's just plain silly. Every
   ; FLI I've seen in the wild always has a speed less than 297 (4 seconds), so
   ; to keep things simple, we'll just truncate any value more than 297 to 297.
   ; Nobody should ever notice, and it keeps our math simple.
   ;
   ; Only the lower 2 bytes will be overwritten in this situation, since the
   ; follow-up math is all 16-bit (it will never look into the upper 2 bytes
   ; of the speed value)
   ;---------------------------------------------------------------------------
   U32_CMP_IMM dwordPointerSpeed, 297
   bcc @speed_is_cool
   U16_COPY_IMM dwordPointerSpeed, 297
@speed_is_cool:

   ;---------------------------------------------------------------------------
   ; convert speed (seventieths) to sixtieths
   ;
   ; basically multiply by 6 then divide by 7.  We already ensured the value is
   ; less than 256, so there's plenty of room to do the multiply. Performance
   ; is slow, but this is a one-time calculation before anything is rendered on
   ; screen, so the size cost of a lookup table does not seem justified.
   ;
   ; Since the effective speed is guaranteed to be 297 or less, the result must
   ; be even less than 6/7 of that (which is less than 256). So, we only need
   ; to squirrel away the lower byte for future runtime calculations.
   ;---------------------------------------------------------------------------
   varTemp       = ZP_VOLATILE_AB
   varDivisor    = ZP_VOLATILE_CD
   varMultiplier = ZP_VOLATILE_E
   varQuotient   = ZP_VOLATILE_GH

   U8_COPY_IMM varMultiplier, 6
   U16_SLOW_MULTIPLY varTemp, dwordPointerSpeed, varMultiplier
   U16_COPY_IMM varDivisor, 7
   U16_SLOW_DIVIDE varQuotient, varTemp, varDivisor

   ;---------------------------------------------------------------------------
   ; store variables
   ;---------------------------------------------------------------------------
   U8_COPY_VAR  ZP8_speedLimitVSyncs, varQuotient+0

   rts
.endproc



