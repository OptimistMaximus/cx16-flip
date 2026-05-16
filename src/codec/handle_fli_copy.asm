.export handle_fli_copy
.import handle_unsupported

.segment "CODE"

.include "../include/global.inc"

.proc handle_fli_copy: near
   jsr handle_unsupported
.endproc
