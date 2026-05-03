.ifndef FILE_INC
.define FILE_INC = 1

.include "kernal.inc"
.include "math.inc"
.include "petscii.inc"

;==============================================================================
; SLURP_INTO_A
;
; Note that unlike opcodes (e.g. LDA) the status flags aren't set based on
; what just got loaded into .A
;
; @effect  .A holds the slurped byte
; @cycles 9 + whatever KERNAL's ACPTR uses
;==============================================================================
.macro SLURP_INTO_A
   jsr KERNAL_ACPTR
.endmacro

;==============================================================================
; SLURP_ARRAY
;
; Reads a number of bytes specified in .A into memory at the target address.
;
; @param  .A holds the number of bytes to read
; @param  targetAddr is the destination address
; @effect .X clobbered
; @effect .Y clobbered
; @cycles 14 + whatever KERNAL's MACPTR uses
;==============================================================================
.macro SLURP_ARRAY targetAddr
   clc                ; clear means advance destination after each read
   ldx #<targetAddr   ; X is the low byte of where to write into memory
   ldy #>targetAddr   ; Y is the high byte of where to write into memory
   jsr KERNAL_MACPTR  ; read multiple bytes from input channel to memory
.endmacro

;==============================================================================
; SLURP_ARRAY_IMM
;
; Reads an immediate number of bytes (convenience macro calling SLURP_ARRAY)
;
; @param  length the number of bytes to read
; @param  targetAddr is the destination address
; @effect .X clobbered
; @effect .Y clobbered
; @cycles 16 + whatever KERNAL's MACPTR uses
;==============================================================================
.macro SLURP_ARRAY_IMM length, targetAddr
   lda #length
   SLURP_ARRAY targetAddr
.endmacro

;==============================================================================
; SLURP_VAR8
;
; @param  targetAddr is where the 1 byte will be slurped into
; @cycles 16 + whatever KERNAL's MACPTR uses
;==============================================================================
.macro SLURP_VAR8 targetAddr
   SLURP_INTO_A
   sta targetAddr
.endmacro

;==============================================================================
; SLURP_VAR16 (little endian)
;
; @param  targetAddr is where the 2 bytes will be slurped into
; @effect .X clobbered
; @effect .Y clobbered
;==============================================================================
.macro SLURP_VAR16 targetAddr
   SLURP_ARRAY_IMM 2, targetAddr
.endmacro

;==============================================================================
; SLURP_VAR24 (little endian)
;
; @param  targetAddr is where the 3 bytes will be slurped into
; @effect .X clobbered
; @effect .Y clobbered
;==============================================================================
.macro SLURP_VAR24 targetAddr
   SLURP_ARRAY_IMM 3, targetAddr
.endmacro

;==============================================================================
; SLURP_VAR32 (little endian)
;
; @param  targetAddr is where the 4 bytes will be slurped into
; @effect .X clobbered
; @effect .Y clobbered
;==============================================================================
.macro SLURP_VAR32 targetAddr
   SLURP_ARRAY_IMM 4, targetAddr
.endmacro

;==============================================================================
; APPEND_ACCESS_MODE_TO_FILENAME
;
; Appends a comma and the "WARM" access mode character to a filename.
;
;   use PETSCII_LOWER_W for Writing
;   use PETSCII_LOWER_A for Appending
;   use PETSCII_LOWER_R for Reading
;   use PETSCII_LOWER_M for Modifying
;
; @param  targetAddr holds the address of the string to append to
; @param  accessMode holds one of the "WARM" petscii characters (see above)
; @effect .Y holds the new length of the string
;==============================================================================
.macro APPEND_ACCESS_MODE_TO_FILENAME targetAddr, accessMode
   U16_COPY_IMM ZP_VOLATILE_AB, targetAddr ; ensure we have a ZP pointer
   ldy #$FF
@append_access_mode_loop:                  ; this loop advances us to the
   iny                                     ; position of the NULL terminator
   lda (ZP_VOLATILE_AB),y
   bne @append_access_mode_loop

   lda #PETSCII_COMMA                      ; now append the access mode
   sta (ZP_VOLATILE_AB),y
   iny
   lda #accessMode
   sta (ZP_VOLATILE_AB),y
   iny
   lda #PETSCII_NULL
   sta (ZP_VOLATILE_AB),y
.endmacro

.endif