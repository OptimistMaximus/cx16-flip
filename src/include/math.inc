.ifndef MATH_INC
        MATH_INC = 1

;#############################################################################
; This file has macros for 16, 24, and 32 bit math, and also some convenient
; macros for copying 16, 24, and 32 bit values.  This makes the code less
; cluttered when doing simple straightforward things.
;
; Every macro in this file is an island, dependency-wise. No macro in here
; depends on any other macro.
;
; Some of these macros use anonymous labels. It's best to avoid them if your
; calling code also uses anonymous labels, since keeping track of the :+++
; and :-- references will be a nightmare.
;#############################################################################

;==============================================================================
; TWOS_COMPLIMENT_A
;
; transforms .A into the two's compliment of .A
;==============================================================================
.macro TWOS_COMPLIMENT_A
   eor #$FF
   inc
.endmacro

;==============================================================================
; U16_STZ
;
; Zero the value in a 16-bit variable
;
; @param targetAddr the value's address
; @effect .A
;==============================================================================
.macro U16_STZ targetAddr
   lda #0
   sta targetAddr+0
   sta targetAddr+1
.endmacro

;==============================================================================
; U24_STZ
;
; Zero the value in a 24-bit variable
;
; @param targetAddr the value's address
; @effect .A
;==============================================================================
.macro U24_STZ targetAddr
   lda #0
   sta targetAddr+0
   sta targetAddr+1
   sta targetAddr+2
.endmacro

;==============================================================================
; U32_STZ
;
; Zero the value in a 32-bit variable
;
; @param targetAddr the value's address
; @effect .A
;==============================================================================
.macro U32_STZ targetAddr
   lda #0
   sta targetAddr+0
   sta targetAddr+1
   sta targetAddr+2
   sta targetAddr+3
.endmacro

;==============================================================================
; U16_ASL
;
; Left-Shift the value in a 16-bit variable
;
; @param targetAddr the value's address
;==============================================================================
.macro U16_ASL targetAddr
   asl targetAddr+0
   rol targetAddr+1
.endmacro

;==============================================================================
; U8_COPY_IMM
;
; Add into a target variable an immediate value
;
; @param targetAddr the target address
; @param sourceValue the value to copy into the target address
;==============================================================================
.macro U8_COPY_IMM targetAddr, sourceValue
   lda #sourceValue
   sta targetAddr
.endmacro

;==============================================================================
; U16_COPY_IMM
;
; Add into a target variable an immediate value
;
; @param targetAddr the target address
; @param sourceValue the value to copy into the target address
;==============================================================================
.macro U16_COPY_IMM targetAddr, sourceValue
   lda #<sourceValue
   sta targetAddr+0
   lda #>sourceValue
   sta targetAddr+1
.endmacro

;==============================================================================
; U24_COPY_IMM
;
; Add into a target variable an immediate value
;
; @param targetAddr the target address
; @param sourceValue the value to copy into the target address
;==============================================================================
.macro U24_COPY_IMM targetAddr, sourceValue
   lda #<sourceValue
   sta targetAddr+0
   lda #>sourceValue
   sta targetAddr+1
   lda #^sourceValue
   sta targetAddr+2
.endmacro

;==============================================================================
; U8_COPY_VAR
;
; Add into a target variable the value in another variable
;
; @param targetAddr the target address
; @param sourceAddr the source address
;==============================================================================
.macro U8_COPY_VAR targetAddr, sourceAddr
   lda sourceAddr
   sta targetAddr
.endmacro

;==============================================================================
; U16_COPY_VAR
;
; Add into a target variable the value in another variable
;
; @param targetAddr the target address
; @param sourceAddr the source address
;==============================================================================
.macro U16_COPY_VAR targetAddr,sourceAddr
   lda sourceAddr+0
   sta targetAddr+0
   lda sourceAddr+1
   sta targetAddr+1
.endmacro

;==============================================================================
; U24_COPY_VAR
;
; Add into a target variable the value in another variable
;
; @param targetAddr the target address
; @param sourceAddr the source address
;==============================================================================
.macro U24_COPY_VAR targetAddr,sourceAddr
   lda sourceAddr+0
   sta targetAddr+0
   lda sourceAddr+1
   sta targetAddr+1
   lda sourceAddr+2
   sta targetAddr+2
.endmacro

;==============================================================================
; U32_COPY_VAR
;
; Add into a target variable the value in another variable
;
; @param targetAddr the target address
; @param sourceAddr the source address
;==============================================================================
.macro U32_COPY_VAR targetAddr, sourceAddr
   lda sourceAddr+0
   sta targetAddr+0
   lda sourceAddr+1
   sta targetAddr+1
   lda sourceAddr+2
   sta targetAddr+2
   lda sourceAddr+3
   sta targetAddr+3
.endmacro

;==============================================================================
; U16_ADD_IMM
;
; Add into a target variable an immediate value
;
; @param targetAddr the target value's address
; @param otherValue  the other value
;
; Note, this macro will clear the carry bit before adding.
;==============================================================================
.macro U16_ADD_IMM targetAddr, otherValue
   clc
   lda targetAddr+0
   adc #<otherValue
   sta targetAddr+0
   lda targetAddr+1
   adc #>otherValue
   sta targetAddr+1
.endmacro

;==============================================================================
; U16_ADD_A
;
; Add into a target variable the value in .A
;
; @param targetAddr the target value's address
;
; Note, this macro will clear the carry bit before adding.
;==============================================================================
.macro U16_ADD_A targetAddr
   clc
   adc targetAddr+0
   sta targetAddr+0
   lda targetAddr+1
   adc #0
   sta targetAddr+1
.endmacro

;==============================================================================
; U16_INC
;
; Increment the value in a variable
;
; @param targetAddr the value's address
;==============================================================================
.macro U16_INC targetAddr
    inc targetAddr+0
    bne :+
    inc targetAddr+1
:
.endmacro

;==============================================================================
; U32_INC
;
; Increment the value in a variable
;
; @param targetAddr the value's address
;
; @cycles  8 if ZP and no low rollover
;         16 if ZP and low rollover
;         24 if ZP and mid rollover
;         32 if ZP and high rollover
;==============================================================================
.macro U32_INC targetAddr
    inc targetAddr+0
    bne :+
    inc targetAddr+1
    bne :+
    inc targetAddr+2
    bne :+
    inc targetAddr+3
:
.endmacro

;==============================================================================
; U16_SUB_IMM
;
; Subtract out of a target variable an immediate value
;
; @param targetAddr the target value's address
; @param otherValue the other value
;
; Note, this macro will set the carry bit before subtracting.
;==============================================================================
.macro U16_SUB_IMM targetAddr, otherValue
   sec
   lda targetAddr+0
   sbc #<otherValue
   sta targetAddr+0
   lda targetAddr+1
   sbc #>otherValue
   sta targetAddr+1
.endmacro

;==============================================================================
; U16_ADD_VAR
;
; Add into a target variable the value in another 16-bit variable
;
; @param targetAddr the target value's address
; @param otherAddr  the other value's address
;
; Note, this macro will clear the carry bit before adding.
;==============================================================================
.macro U16_ADD_VAR targetAddr, valueAddress
   clc
   lda targetAddr+0
   adc valueAddress+0
   sta targetAddr+0
   lda targetAddr+1
   adc valueAddress+1
   sta targetAddr+1
.endmacro

;==============================================================================
; U24_ADD_VAR
;
; Add into a target 24-bit variable the value in another 24-bit variable
;
; @param targetAddr the target value's address
; @param otherAddr  the other value's address
;
; Note, this macro will clear the carry bit before adding.
;==============================================================================
.macro U24_ADD_VAR targetAddr, valueAddress
   clc
   lda targetAddr+0
   adc valueAddress+0
   sta targetAddr+0
   lda targetAddr+1
   adc valueAddress+1
   sta targetAddr+1
   lda targetAddr+2
   adc valueAddress+2
   sta targetAddr+2
.endmacro

;==============================================================================
; U24_ADD_IMM
;
; Add into a target 24-bit variable an immediate 24-bit variable
;
; @param targetAddr the target value's address
; @param otherValue  the other value
;
; Note, this macro will clear the carry bit before adding.
;==============================================================================
.macro U24_ADD_IMM targetAddr, otherValue
   clc
   lda targetAddr+0
   adc #<otherValue
   sta targetAddr+0
   lda targetAddr+1
   adc #>otherValue
   sta targetAddr+1
   lda targetAddr+2
   adc #^otherValue
   sta targetAddr+2
.endmacro

;==============================================================================
; U16_ADD_VAR8
;
; Add into a target variable the value in an 8-bit variable
;
; @param targetAddr the target value's address
; @param otherAddr  the other value's address
;
; Note, this macro will clear the carry bit before adding.
;==============================================================================
.macro U16_ADD_VAR8 targetAddr, valueAddress
   clc
   lda targetAddr+0
   adc valueAddress+0
   sta targetAddr+0
   lda targetAddr+1
   adc #0
   sta targetAddr+1
.endmacro

;==============================================================================
; U32_ADD_A
;
; Add into a target variable the value in a .A
;
; @param targetAddr the target value's address
; @cycles 34 if ZP
;
; Note, this macro will clear the carry bit before adding.
;==============================================================================
.macro U32_ADD_A targetAddr
   clc
   adc targetAddr+0
   sta targetAddr+0
   lda targetAddr+1
   adc #0
   sta targetAddr+1
   lda targetAddr+2
   adc #0
   sta targetAddr+2
   lda targetAddr+3
   adc #0
   sta targetAddr+3
.endmacro



;==============================================================================
; U16_SUB_VAR
;
; Subtract out of a target variable the value in another variable
;
; @param targetAddr the target value's address
; @param otherAddr  the other value's address
;
; Note, this macro will set the carry bit before subtracting.
;==============================================================================
.macro U16_SUB_VAR targetAddr, valueAddress
   sec
   lda targetAddr+0
   sbc valueAddress+0
   sta targetAddr+0
   lda targetAddr+1
   sbc valueAddress+1
   sta targetAddr+1
.endmacro

;==============================================================================
; U16_CMP_IMM
;
; This works the same as an 8-bit CMP, except instead of comparing .A against
; another value, we compare a 16-bit value at a target address.
;
; Carry (C)  1 means value >= other
;            0 means value <  other
; Zero (Z)   1 means value == other
;            0 means value != other
; Neg (N)    Reflects bit 7 of the (value − other) result
;
; @param valueAddr the value's address
; @param otherValue the argument
;==============================================================================
.macro U16_CMP_IMM targetAddr, otherValue
   lda targetAddr+1
   cmp #>otherValue
   bne :+
   lda targetAddr+0
   cmp #<otherValue
:
.endmacro

;==============================================================================
; U16_CMP_IMM
;
; This works the same as an 8-bit CMP, except instead of comparing .A against
; another value, we compare a 16-bit value at a target address.
;
; Carry (C)  1 means value >= other
;            0 means value <  other
; Zero (Z)   1 means value == other
;            0 means value != other
; Neg (N)    Reflects bit 7 of the (value − other) result
;
; @param valueAddr the value's address
; @param otherValue the argument
;==============================================================================
.macro U16_CMP_VAR targetAddr, otherAddr
   lda targetAddr+1
   cmp otherAddr+1
   bne :+
   lda targetAddr+0
   cmp otherAddr+0
:
.endmacro

;==============================================================================
; U32_CMP_IMM
;
; @param valueAddr the value's address
; @param otherValue the argument (must be 24-bit)
;
; The immediate argument is limited to 24-bit because the ca65 assembler does
; not give us the syntax to ask for the MSB of a 32-bit number.
;==============================================================================
.macro U32_CMP_IMM targetAddr, otherValue
   lda targetAddr+3
   cmp #0
   bne :+
   lda targetAddr+2
   cmp #^otherValue
   bne :+
   lda targetAddr+1
   cmp #>otherValue
   bne :+
   lda targetAddr+0
   cmp #<otherValue
:
.endmacro

;==============================================================================
; U32_CMP_VAR
;
; @param valueAddr the value's address
; @param otherValue the argument
;==============================================================================
.macro U32_CMP_VAR targetAddr, otherAddr
   lda targetAddr+3
   cmp otherAddr+3
   bne :+
   lda targetAddr+2
   cmp otherAddr+2
   bne :+
   lda targetAddr+1
   cmp otherAddr+1
   bne :+
   lda targetAddr+0
   cmp otherAddr+0
:
.endmacro

.endif