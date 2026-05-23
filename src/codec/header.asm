.export func_slurp_header

.import bsod

.include "../include/global.inc"
.include "../include/kernal.inc"
.include "../include/math.inc"
.include "../include/math2.inc"
.include "../include/petscii.inc"
.include "../include/slurp.inc"

FILE_TYPE_FLI := $AF11

;==============================================================================
; func_slurp_header
;
; This must be the very first thing called after opening the file input stream.
; It sets the frameIndex and the frameCount, which the main logic will use to
; iterate over all the frames.
;==============================================================================
.proc func_slurp_header: near

   varFileType = ZP_VOLATILE_AB

   SLURP_INTO_OBLIVION 4       ; dword size (file size)
   SLURP_INTO_U16 varFileType  ;  word type (file type)

   ;---------------------------------------------------------------------------
   ; validate file type
   ;---------------------------------------------------------------------------
   U16_CMP_IMM varFileType, FILE_TYPE_FLI
   beq @fileType_is_fli
   BSOD RC_UNSUPPORTED_FILE_TYPE, varFileType
@fileType_is_fli:

   U16_STZ        GR16_frameIndex
   SLURP_INTO_U16 GR16_frameCount
   SLURP_INTO_OBLIVION 8  ; width, height, depth, flags

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
   varSpeed = GR32_scratch1
   SLURP_INTO_U32 varSpeed ; dword speed
   U32_CMP_IMM varSpeed, 297
   bcc @speed_is_cool
   U16_COPY_IMM varSpeed, 297
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
   varTemp       = ZP_VOLATILE_EF
   varDivisor    = ZP_VOLATILE_GH
   varMultiplier = ZP_VOLATILE_I
   varQuotient   = ZP_VOLATILE_KL

   U8_COPY_IMM varMultiplier, 6
   U16_SLOW_MULTIPLY varTemp, varSpeed, varMultiplier
   U16_COPY_IMM varDivisor, 7
   U16_SLOW_DIVIDE varQuotient, varTemp, varDivisor
   U8_COPY_VAR GR8_speedLimitVSyncs, varQuotient+0

   ;---------------------------------------------------------------------------
   ; burn remaining bytes of header
   ;---------------------------------------------------------------------------
   SLURP_INTO_OBLIVION 108

   rts
.endproc



