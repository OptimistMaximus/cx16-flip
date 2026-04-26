.segment "CODE"

.export func_strlen

.include "../include/global.inc"
.include "../include/kernal.inc"
.include "../include/petscii.inc"


.proc func_strlen: near

   stx ZP16_VOLATILE_AB+0
   sty ZP16_VOLATILE_AB+1

   phy
      ldy #0
   @loop:
      lda (ZP16_VOLATILE_AB),y
      beq @loop_done
      iny
      bra @loop
   @loop_done:
      tya
   ply   
   rts
.endproc
