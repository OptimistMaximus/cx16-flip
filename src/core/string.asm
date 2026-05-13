.segment "CODE"

.export func_strlen

.include "../include/global.inc"
.include "../include/kernal.inc"
.include "../include/petscii.inc"

;==============================================================================
; func_strlen
;
; @param  .X holds the low byte of the address of the string
; @param  .Y holds the high byte of the address of the string
; @effect .A holds the string length
;==============================================================================
.proc func_strlen: near
   stx ZP_VOLATILE_A
   sty ZP_VOLATILE_B
   phy
   ldy #0
@loop:
   lda (ZP_VOLATILE_AB),y
   beq @loop_done
   iny
   bra @loop
@loop_done:
   tya
   ply
   rts
.endproc
