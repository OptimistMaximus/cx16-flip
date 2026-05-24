.export debug_print_istring
.export debug_print_string
.export debug_print_space
.export debug_print_hex_a
.export debug_print_hex_x
.export debug_print_hex_y
.export debug_print_hex_p
.export debug_print_newline

.include "../include/global.inc"
.include "../include/kernal.inc"
.include "../include/math.inc"
.include "../include/petscii.inc"
.include "../include/stack.inc"
.include "../include/zeropage.inc"

.import func_print_hex

.segment "CODE"

;-----------------------------------------------------------------------------
; debug_print_istring
;
; @param inlined, for example
;
;           jsr debug_print_istring
;           .asciiz "hello"
;
; @effect .Y
;-----------------------------------------------------------------------------
.proc debug_print_istring : near
   inlineAddr = ZP_VOLATILE_PTR

   U16_STACK_PULL_RETURN_ADDR_INTO_INLINED_ARG_ADDR inlineAddr
   ldy #0
@print_loop:
   lda (inlineAddr),y
   beq @print_done
   jsr KERNAL_CHROUT
   iny
   bra @print_loop
@print_done:
   iny ; add 1 to account for null terminator
   U16_STACK_PUSH_RETURN_ADDR_FROM_INLINED_ARG_ADDR inlineAddr
   rts
.endproc

;-----------------------------------------------------------------------------
; debug_print_string
;
; prep: .X holds low byte of string address
; prep: .Y holds high byte of string address
;
; effects .A, .Y
;
;    jsr debug_print_istring
;    .asciiz "hello"
;-----------------------------------------------------------------------------
.proc debug_print_string : near
   stringAddr = ZP_VOLATILE_PTR

   stx stringAddr+0
   sty stringAddr+1

   ldy #0
@print_loop:
   lda (stringAddr),y
   beq @print_done
   jsr KERNAL_CHROUT
   iny
   bra @print_loop
@print_done:
    rts
.endproc

.proc debug_print_space: near
   pha
   lda #PETSCII_SPACE
   jsr KERNAL_CHROUT
   pla
   rts
.endproc

.proc debug_print_newline: near
   pha
   lda #PETSCII_RETURN
   jsr KERNAL_CHROUT
   pla
   rts
.endproc

.proc debug_print_hex_a : near
   pha
   jsr func_print_hex
   pla
   rts
.endproc

.proc debug_print_hex_x : near
   pha
   txa
   jsr func_print_hex
   pla
   rts
.endproc

.proc debug_print_hex_y : near
   pha
   tya
   jsr func_print_hex
   pla
   rts
.endproc

.proc debug_print_hex_p : near
   pha
   php ; push .P
   pla ; pull .A ... i.e. transfer P to A
   jsr func_print_hex
   pla
   rts
.endproc
