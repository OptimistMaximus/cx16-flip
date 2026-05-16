.export bsod
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

.proc bsod: near
   phy
      phx
         pha
            jsr func_vera_restore ; restore vera to text mode
            PRINT PETSCII_RETURN
         pla
         jsr func_print_hex
         PRINT PETSCII_SPACE
      pla ; pull .X directly into .A
      jsr func_print_hex
      PRINT PETSCII_SPACE
   pla ; pull .Y directly into .A
   jsr func_print_hex
      
:  jsr KERNAL_GETIN      ; i.e. press any key to continue
   beq :-                ; (leaving last image still on-screen)

   jmp KERNAL_ENTER_BASIC
.endproc
