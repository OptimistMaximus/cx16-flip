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

bsod:
   jsr func_vera_restore ; restore vera to text mode
   PRINT PETSCII_RETURN
   lda GOLDEN_returnCode
   jsr func_print_hex
   PRINT PETSCII_SPACE
   lda GOLDEN_returnDetail+0
   jsr func_print_hex
   lda GOLDEN_returnDetail+1
   jsr func_print_hex

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

