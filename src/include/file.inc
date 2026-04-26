.ifndef FILE_INC
.define FILE_INC = 1

.include "kernal.inc"

;------------------------------------------------------------------------------
; SLURP_A
;
; Reads a number of bytes specified in .A into memory at the target address.
;
; prep: .A holds the number of bytes to read
;------------------------------------------------------------------------------
.macro SLURP_A targetAddr
   clc                     ; clear means advance destination after each read
   ldx #<ARRAY_stagingArea ; X is the low byte of where to write into memory
   ldy #>ARRAY_stagingArea ; Y is the high byte of where to write into memory
   jsr KERNAL_MACPTR       ; read multiple bytes from input channel to memory
.endmacro

;------------------------------------------------------------------------------
; SLURP_VAR8
;
; Slurp 1 byte into the target address
;------------------------------------------------------------------------------
.macro SLURP_VAR8 targetAddr
   jsr KERNAL_ACPTR
   sta targetAddr
.endmacro

;------------------------------------------------------------------------------
; SLURP_VAR16
;
; Slurp 2 byte into the target address
;------------------------------------------------------------------------------
.macro SLURP_VAR16 targetAddr
   lda #2
   SLURP_A targetAddr
.endmacro

;------------------------------------------------------------------------------
; SLURP_VAR24
;
; Slurp 3 byte into the target address
;------------------------------------------------------------------------------
.macro SLURP_VAR16 targetAddr
   lda #3
   SLURP_A targetAddr
.endmacro

;------------------------------------------------------------------------------
; SLURP_VAR32
;
; Slurp 4 byte into the target address
;------------------------------------------------------------------------------
.macro SLURP_VAR16 targetAddr
   lda #4
   SLURP_A targetAddr
.endmacro

.endif