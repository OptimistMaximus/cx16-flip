.export func_detect_filename

.segment "RODATA"

default_filename: .asciiz "image.fli,r"
default_filename_end:

.segment "CODE"

.include "../include/global.inc"
.include "../include/kernal.inc"
.include "../include/math.inc"
.include "../include/petscii.inc"
.include "../include/zeropage.inc"

BASIC_BUFFER      := $0200
BASIC_TOKEN_RUN   := $8A
BASIC_TOKEN_REM   := $8F
MAX_OFFSET        := 77  ; enough room to add ",R" and be within 80 chars

;==============================================================================
; func_detect_filename
;
; This simplistic implementation looks in the BASIC buffer to find the string
; that potentially exists after a REM token.  If it finds it, it uses this as
; the filename (and appends comma and file access mode to it)
;
; If there was no REM token, or no arg after the REM or there was an arg but
; it was so close to the end of the BASIC buffer that we couldn't safely append
; the access mode, then it will return the default filename.
;
; e.g. this:  "RUN:REM FOO.FLI BAR" results in "FOO.FLI,R"
; and this:   "RUN  :  REM  FOO.FLI" results in "FOO.FLI,R"
;
; @effect .A is the length of the filename (include access mode)
; @effect .X is the low byte of the filename address
; @effect .Y is the high byte of the filename address
;==============================================================================
.proc func_detect_filename: near

   ldx #$FF       ; start at -1 because we INX first

@rem_loop:
   inx
   lda BASIC_BUFFER,x
   beq @cannot_find_arg
   cmp #BASIC_TOKEN_REM
   bne @rem_loop

@space_loop:
   inx
   lda BASIC_BUFFER,x
   beq @cannot_find_arg
   cmp #PETSCII_SPACE
   beq @space_loop

   U16_COPY_IMM ZP_VOLATILE_PTR, BASIC_BUFFER
   txa
   U16_ADD_A    ZP_VOLATILE_PTR

   ldy #0 ; tracks string length
@arg_loop:
   inx
   iny
   lda BASIC_BUFFER,x
   beq @found_end_of_arg
   cmp #PETSCII_SPACE
   bne @arg_loop
@found_end_of_arg:

   cpx #MAX_OFFSET
   bcs @cannot_find_arg

   lda #PETSCII_COMMA
   sta BASIC_BUFFER,x
   inx
   iny
   lda #PETSCII_LOWER_R
   sta BASIC_BUFFER,x
   inx
   iny
   lda #PETSCII_NULL
   sta BASIC_BUFFER,x

   tya
   ldx ZP_VOLATILE_PTR+0
   ldy ZP_VOLATILE_PTR+1
   rts

@cannot_find_arg:
   lda #(default_filename_end - default_filename - 1)
   ldx #<default_filename
   ldy #>default_filename
   rts
.endproc
