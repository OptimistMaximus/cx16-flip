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
   stringAddr = ZP_VOLATILE_PTR
   stx stringAddr+0
   sty stringAddr+1
   phy
   ldy #0
@loop:
   lda (stringAddr),y
   beq @loop_done
   iny
   bra @loop
@loop_done:
   tya
   ply
   rts
.endproc
