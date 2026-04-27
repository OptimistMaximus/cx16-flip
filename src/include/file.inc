.ifndef FILE_INC
.define FILE_INC = 1

.include "kernal.inc"
.include "math.inc"

;------------------------------------------------------------------------------
; SLURP_INTO_A
;
; Slurp 1 byte into .A
;------------------------------------------------------------------------------
.macro SLURP_INTO_A targetAddr
   jsr KERNAL_ACPTR
.endmacro

;------------------------------------------------------------------------------
; SLURP_ARRAY
;
; Reads a number of bytes specified in .A into memory at the target address.
;
; This does a PHX/PHY/PLY/PLX which costs 14 cycles, so slurping into an array
; of length 1 is slower than using SLURP_VAR8. Slurping into an array of
; length 2 is faster than using SLURP_VAR16 since 2 SLURP_INTO_A calls would
; require two JSR/RTS which is already 18 cycles. 
;
; @param .A holds the number of bytes to read
; @param targetAddr is the destination address
;------------------------------------------------------------------------------
.macro SLURP_ARRAY targetAddr
   phx
      phy
         clc                ; clear means advance destination after each read
         ldx #<targetAddr   ; X is the low byte of where to write into memory
         ldy #>targetAddr   ; Y is the high byte of where to write into memory
         jsr KERNAL_MACPTR  ; read multiple bytes from input channel to memory
      ply
   plx
.endmacro

;------------------------------------------------------------------------------
; SLURP_VAR8
;
; Slurp 1 byte into the target address
;------------------------------------------------------------------------------
.macro SLURP_VAR8 targetAddr
   SLURP_INTO_A
   sta targetAddr
.endmacro

;------------------------------------------------------------------------------
; SLURP_VAR16
;
; Slurp 2 byte into the target address
;------------------------------------------------------------------------------
.macro SLURP_VAR16 targetAddr
   lda #2
   SLURP_ARRAY targetAddr
.endmacro

;------------------------------------------------------------------------------
; SLURP_VAR24
;
; Slurp 3 byte into the target address
;------------------------------------------------------------------------------
.macro SLURP_VAR24 targetAddr
   lda #3
   SLURP_ARRAY targetAddr
.endmacro

;------------------------------------------------------------------------------
; SLURP_VAR32
;
; Slurp 4 byte into the target address
;------------------------------------------------------------------------------
.macro SLURP_VAR32 targetAddr
   lda #4
   SLURP_ARRAY targetAddr
.endmacro

;------------------------------------------------------------------------------
; APPEND_ACCESS_MODE_TO_FILENAME
;
; Appends a comma and the "WARM" access mode character to a filename.
;
; PETSCII_LOWER_W for Writing
; PETSCII_LOWER_A for Appending
; PETSCII_LOWER_R for Reading
; PETSCII_LOWER_M for Modifying
;
; @param targetAddr holds the address of the string to append to
; @param accessMode holds the access mode petscii character
; @effect .Y holds the new length of the string
;------------------------------------------------------------------------------
.macro APPEND_ACCESS_MODE_TO_FILENAME targetAddr, accessMode
   U16_COPY_IMM ZP_VOLATILE_AB, targetAddr ; targetAddr might not be zero page
                                           ; so we need to squirrel it into ZP
                                           ; (immediate, so it points properly)

   ldy #$FF
@append_access_mode_loop:               ; this loop advances us to the
   iny                                  ; position of the NULL terminator
   lda (ZP_VOLATILE_AB),y
   bne @append_access_mode_loop
   lda #PETSCII_COMMA
   sta (ZP_VOLATILE_AB),y
   iny
   lda #accessMode
   sta (ZP_VOLATILE_AB),y
   iny
   lda #PETSCII_NULL
   sta (ZP_VOLATILE_AB),y
.endmacro

.endif