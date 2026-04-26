.org $080D            ; specify where in memory our code will live
.segment "STARTUP"    ; declare segments
.segment "INIT"
.segment "ONCE"
.segment "CODE"

.import func_find_arg
.import func_open_inputstream
.import func_close_inputstream
.import func_print_hex

.import func_slurp_header

.include "include/file.inc"
.include "include/global.inc"
.include "include/kernal.inc"
.include "include/petscii.inc"
.include "include/vera.inc"
.include "include/zeropage.inc"

   jmp start

default_image_filename: .asciiz "image.fli,r"

;------------------------------------------------------------------------------
; MACRO: BSOD (BASIC Screen of Death)
;
; Call this to return to BASIC, with .A set to the return code.  This macro
; assumes you will only ever call it in a situation where RTS would indeed
; return to basic.
;
; @param rc  the return code     assumed to be an immediate value
;------------------------------------------------------------------------------
.macro BSOD rc
   lda #rc
   ldx #0
   ldy #0
   rts
.endmacro

;------------------------------------------------------------------------------
; MACRO: BSOD (BASIC Screen of Death)
;
; Call this to return to BASIC, with .A set to the return code, and .X and .Y
; set to the details of the error code. Similar to BSOD, only call this when
; an RTS would actually return you to BASIC.
;
; @param rc     the return code     assumed to be an immediate value
; @param detail detail              assumed to be the address of a 16-bit value
;------------------------------------------------------------------------------
.macro BSOD_VAR16 rc, detail
   lda #rc
   ldx detail+0
   ldy detail+1
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
   APPEND_ACCESS_MODE_TO_FILENAME PETSCII_UPPER_R
   ldx #<RAM_VOLATILE_BUF
   ldy #>RAM_VOLATILE_BUF
@filename_established:

   jsr func_open_inputstream
   tya
   beq @open_success
   BSOD RC_CANNOT_OPEN_FILE
@open_success:

   txa
   beq @chkin_success
   BSOD RC_CANNOT_OPEN_FILE
@chkin_success:

   ;---------------------------------------------------------------------------
   ; Now we can enter the main part of the program
   ;---------------------------------------------------------------------------
   jsr func_slurp_header
   stp
   nop
   nop
   beq @header_is_cool
   rts ; ERROR! return to basic, retaining .A, .X, .Y
@header_is_cool:
 
   ;---------------------------------------------------------------------------
   ; Finally, close the file stream and return   
   ;---------------------------------------------------------------------------
   jsr func_close_inputstream
   BSOD RC_SUCCESS
