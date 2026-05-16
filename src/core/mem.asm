.export func_stash_zeropage
.export func_unstash_zeropage

.segment "CODE"

.include "../include/kernal.inc"
.include "../include/global.inc"
.include "../include/petscii.inc"
.include "../include/zeropage.inc"

.macro SHUFFLE targetAddr, sourceAddr
   ldx #0
@loop:
   lda sourceAddr,x
   sta targetAddr,x
   inx
   bne @loop
.endmacro

;==============================================================================
; func_stash_zeropage
;
; This frees up some extra space in Zero Page for use by the running program.
; The address range is $D4 to $FF inclusive, based on CX16 Memory Map.
; Make sure to restore it via func_restore_zp_basic before returning to BASIC.
;
; 0D 08 08 D0 C5 00 00 00
; 00 00 00 01 08 00 9F 00
; 00 00 00 E6 EE D0 02 E6
; E9 D0 60 20
;
; @effect .X
;==============================================================================
.proc func_stash_zeropage: near
   SHUFFLE GOLDEN_ZP_STASH, $D4
   rts
.endproc

;==============================================================================
; func_unstash_zeropage
;
; This restores what was done by func_stash_zeropage
;
; @effect .X
;==============================================================================
.proc func_unstash_zeropage: near
   SHUFFLE $D4, GOLDEN_ZP_STASH 
   rts
.endproc
   
