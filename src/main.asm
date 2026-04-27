.org $080D            ; specify where in memory our code will live
.segment "STARTUP"    ; declare segments
.segment "INIT"
.segment "ONCE"
.segment "CODE"

.import func_find_arg
.import func_open_inputstream
.import func_close_inputstream
.import func_print_hex
.import func_vera_setup
.import func_vera_restore

.import func_slurp_header

.include "include/file.inc"
.include "include/global.inc"
.include "include/kernal.inc"
.include "include/petscii.inc"
.include "include/vera.inc"
.include "include/zeropage.inc"

   jmp start

default_image_filename: .asciiz "image.fli,r"

.macro PRINT petscii
   lda #petscii
   jsr KERNAL_CHROUT
.endmacro

;------------------------------------------------------------------------------
; RTS_BSOD (BASIC Screen of Death)
;
; Call this to return to BASIC, assuming .A .X and .Y were already set with
; the return status and detail.  This restores VERA  back to default
; and prints the return status and detail as text.
;------------------------------------------------------------------------------
.macro RTS_BSOD
   phy
      phx
         pha
            jsr func_vera_restore
            PRINT PETSCII_RETURN
            PRINT PETSCII_LOWER_E
            PRINT PETSCII_LOWER_R
            PRINT PETSCII_LOWER_R
            PRINT PETSCII_LOWER_O
            PRINT PETSCII_LOWER_R
            PRINT PETSCII_SPACE
         pla
         jsr func_print_hex
         PRINT PETSCII_SPACE
         PRINT PETSCII_OPEN_SQUARE
      plx
      txa
      jsr func_print_hex
   ply
   tya
   jsr func_print_hex
   PRINT PETSCII_CLOSE_SQUARE
   PRINT PETSCII_RETURN
   PRINT PETSCII_RETURN
   rts
.endmacro

start:

   ;---------------------------------------------------------------------------
   ; Establish the filename by looking for a custom argument. If no such arg
   ; was found, then we'll use our default value.  Then, open the file.
   ;---------------------------------------------------------------------------
   lda #0
   ldx #<RAM_VOLATILE_BUF
   ldy #>RAM_VOLATILE_BUF
   jsr func_find_arg
   bcc @arg_was_cool              ; .C=0 means it was found
   ldx #<default_image_filename
   ldy #>default_image_filename
   bra @filename_established
@arg_was_cool:
   APPEND_ACCESS_MODE_TO_FILENAME RAM_VOLATILE_BUF, PETSCII_LOWER_R
   tya ; new string length
   ldx #<RAM_VOLATILE_BUF
   ldy #>RAM_VOLATILE_BUF
@filename_established:

   ;---------------------------------------------------------------------------
   ; Open the file as an input stream
   ;---------------------------------------------------------------------------
   jsr func_open_inputstream
   beq @inputstream_is_cool
   RTS_BSOD
@inputstream_is_cool:

   ;---------------------------------------------------------------------------
   ; Now we can enter the main part of the program.
   ;---------------------------------------------------------------------------
   jsr func_slurp_header
   beq @header_is_cool
   RTS_BSOD
@header_is_cool:

   jsr func_vera_setup





   ;---------------------------------------------------------------------------
   ; Finally, close the file stream, wait for "any key" then return to BASIC
   ;---------------------------------------------------------------------------
   jsr func_close_inputstream

:  jsr KERNAL_GETIN             ; i.e. press any key to continue
   beq :-                       ; (leaving last image still on-screen)

   jsr func_vera_restore        ; restore vera to text mode
   RTS_NO_DETAIL RC_SUCCESS
