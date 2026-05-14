.export handle_black
.import handle_unsupported

.segment "CODE"

.include "../include/global.inc"

.proc handle_black: near
   jmp handle_unsupported
.endproc
