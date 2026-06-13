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
; U16_STZ                                                             [TEST 00]
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
; U24_STZ                                                             [TEST 00]
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
; U8_COPY_IMM                                                         [TEST 00]
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
; U16_COPY_IMM                                                        [TEST 00]
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
; U24_COPY_IMM                                                        [TEST 00]
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
; U8_COPY_VAR                                                         [TEST 00]
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
; U16_COPY_VAR                                                        [TEST 00]
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
; U24_COPY_VAR                                                         TEST 00]
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
; U16_ADD_A                                                           [TEST 01]
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
; U24_ADD_IMM                                                         [TEST 01]
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
; U16_ADD_VAR                                                         [TEST 01]
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
; U16_SUB_VAR                                                         [TEST 01]
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
; U16_INC                                                             [TEST 02]
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
; U16_CMP_IMM                                                         [TEST 03]
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
; U16_CMP_VAR                                                         [TEST 03]
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
; U16_ASL                                                             [TEST 04]
;==============================================================================
.macro U16_ASL targetAddr
   asl targetAddr+0
   rol targetAddr+1
.endmacro

;==============================================================================
; U16_LSR
;==============================================================================
.macro U16_LSR targetAddr
   lsr targetAddr+1
   ror targetAddr+0
.endmacro

;==============================================================================
; ONES_COMPLIMENT_A                                                   [TEST ??]
;
; transforms .A into the one's compliment of .A
;==============================================================================
.macro ONES_COMPLIMENT_A
   eor #$FF
.endmacro

;==============================================================================
; TWOS_COMPLIMENT_A                                                   [TEST 08]
;
; transforms .A into the two's compliment of .A
;==============================================================================
.macro TWOS_COMPLIMENT_A
   ONES_COMPLIMENT_A
   inc
.endmacro

.endif