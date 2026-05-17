.org $080D

.import func_open_inputstream
.import func_close_inputstream
.import func_slurp_into_a
.import func_slurp_into_buffer
.import func_print_hex
.import debug_print_string

.segment "INIT"
.segment "STARTUP"
.segment "ONCE"
.segment "CODE"

.include "include/global.inc"
.include "include/kernal.inc"
.include "include/petscii.inc"
.include "include/xunit.inc"

.macro NEWLINE
   lda #PETSCII_RETURN
   jsr KERNAL_CHROUT
.endmacro

   jmp start

test_filename: .asciiz "slurp.bin,r"

start:

; READST for Serial Bus:
;   b7 device not present
;   b6 EOI line
;   b1 timeout read
;   b0 timeout write

   ldx #<test_filename
   ldy #>test_filename
   jsr debug_print_string
   NEWLINE

   ldx #<test_filename
   ldy #>test_filename
   jsr func_open_inputstream

   lda #4
   jsr func_slurp_into_buffer     ; should get first 4 chars "abcd"
   jsr KERNAL_READST
   jsr func_print_hex
   txa
   jsr func_print_hex
   tya
   jsr func_print_hex
   NEWLINE

   lda #9
   jsr func_slurp_into_buffer     ; should get first 4 chars "abcd"
   jsr KERNAL_READST
   jsr func_print_hex
   txa
   jsr func_print_hex
   tya
   jsr func_print_hex
   NEWLINE



   jsr func_slurp_into_a          ; should get the next char "e"
   pha
      jsr KERNAL_READST
      jsr func_print_hex
      NEWLINE
      jsr func_close_inputstream
   pla
   jsr func_print_hex

   :  jsr KERNAL_GETIN             ; i.e. press any key to continue
   beq :-                       ; (leaving last image still on-screen)

   rts
