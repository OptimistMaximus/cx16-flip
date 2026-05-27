.export bsod
.export smc_anchor_for_bsod

.import func_print_hex
.import func_vera_restore

.segment "RODATA"

.segment "CODE"

.include "../include/global.inc"
.include "../include/kernal.inc"
.include "../include/petscii.inc"

.macro PRINT petscii
   lda #petscii
   jsr KERNAL_CHROUT
.endmacro

.macro PRINT_U16_HEX addr
   lda addr+1
   jsr func_print_hex
   lda addr+0
   jsr func_print_hex
.endmacro

.macro PRINT_U8_HEX addr
   lda addr
   jsr func_print_hex
.endmacro

bsod:
   jsr func_vera_restore ; restore vera to text mode
   PRINT PETSCII_RETURN
   PRINT_U8_HEX GR8_returnCode

   PRINT PETSCII_SPACE
   PRINT_U16_HEX GR16_returnDetail

   PRINT PETSCII_SPACE
   PRINT_U16_HEX GR16_frameIndex

   PRINT PETSCII_SPACE
   PRINT_U16_HEX GR16_chunkIndex

   ;---------------------------------------------------------------------------
   ; This label serves two purposes. In production, it is used to wait for the
   ; user to hit a key (since the screen will be wiped as soon as we jump back
   ; to basic). In unit tests, this is used as a self-modifying-code anchor so
   ; that the JSR can be replaced with an RTS, allowing the unit test to
   ; verify the return code and details without interactivity, and without
   ; actually ending the unit test program.
   ;---------------------------------------------------------------------------
smc_anchor_for_bsod:
   jsr KERNAL_GETIN        ; i.e. press any key to continue
   beq smc_anchor_for_bsod
   jmp KERNAL_ENTER_BASIC

