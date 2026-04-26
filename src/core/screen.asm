.export func_print_hex

.segment "CODE"

.include "../include/petscii.inc"
.include "../include/kernal.inc"

;-----------------------------------------------------------------------------
; print byte as hex text to screen
;
; @param: .A holds the hex value to be printed to the current cursor position
; @effect: A
;-----------------------------------------------------------------------------
.proc func_print_hex: near
   pha               ; push A onto stack
      lsr            ; shift left 4 times, i.e.  A = A >> 4
      lsr            ;  the end result is the high nibble is
      lsr            ;  now in the low nibble
      lsr
      jsr sub_print_hex_nibble
   pla
   and #$0F          ; the end result is the high nibble is gone
   jmp sub_print_hex_nibble ; final jsr optimized to jmp
.endproc

sub_print_hex_nibble:
   cmp #$0A          ; compare with $0A
   bcs @letter       ; i.e. (A >= 10) then A must be a letter
   ora #$30          ; else it's a digit, convert to PETSCII by adding $30
   bra @print        ; jump ahead to print
@letter:
   clc
   adc #$37          ; convert to PETSCII ... A=$41, B=$42, etc
@print:
   jsr KERNAL_CHROUT ; print whatever's in A
   rts
