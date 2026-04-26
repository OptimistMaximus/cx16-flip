.ifndef MATH_INC
        MATH_INC = 1
;
; Note, several macros here use anonymous labels (:) so do not use them in
; code that also uses anonymous labels, since you won't be able to keep the
; :+++ and :--- style counts straight.
;

;-----------------------------------------------------------------------------
; Store Zero (16-bit)                                               [Test 1-8]
;-----------------------------------------------------------------------------
.macro U16_STZ targetAddr
   stz targetAddr+0
   stz targetAddr+1
.endmacro

;-----------------------------------------------------------------------------
; Store Zero (24-bit)                                               [Test 1-8]
;-----------------------------------------------------------------------------
.macro U24_STZ targetAddr
   stz targetAddr+0
   stz targetAddr+1
   stz targetAddr+2
.endmacro

;-----------------------------------------------------------------------------
; Store an 8 bit var based on an immediate value                    [Test 1-9]
;
; effects: .A
;-----------------------------------------------------------------------------
.macro U8_COPY_IMM targetAddr, immediateValue
   lda #immediateValue
   sta targetAddr
.endmacro

;-----------------------------------------------------------------------------
; Store a 16 bit var based on an immediate value    (10 cycles)     [Test 1-9]
;
; effects: .A
;-----------------------------------------------------------------------------
.macro U16_COPY_IMM targetAddr, immediateValue
   lda #<immediateValue
   sta targetAddr+0
   lda #>immediateValue
   sta targetAddr+1
.endmacro

;-----------------------------------------------------------------------------
; Store a 24 bit var based on an immediate value                    [Test 1-9]
;
; effects: .A
;-----------------------------------------------------------------------------
.macro U24_COPY_IMM targetAddr, immediateValue
   lda #<immediateValue
   sta targetAddr+0
   lda #>immediateValue
   sta targetAddr+1
   lda #^immediateValue
   sta targetAddr+2
.endmacro

;-----------------------------------------------------------------------------
; Copy (8-bit) var based on another var                            [Test 1-10]
;
; effects: .A
;-----------------------------------------------------------------------------
.macro U8_COPY_VAR targetAddr,sourceAddr
   lda sourceAddr
   sta targetAddr
.endmacro

;-----------------------------------------------------------------------------
; Copy (16-bit) var based on another var                           [Test 1-10]
;
; effects: .A
; cycles:  6+6 = 12 (assuming both params are zero page)
;          6+8 = 14 (assuming one absolute and one zp)
;          8+8 = 16 (assuming both params are absolute)
;-----------------------------------------------------------------------------
.macro U16_COPY_VAR targetAddr,sourceAddr
   lda sourceAddr+0
   sta targetAddr+0
   lda sourceAddr+1
   sta targetAddr+1
.endmacro

;-----------------------------------------------------------------------------
; Copy (32-bit) var based on another var
;
; effects: .A
;-----------------------------------------------------------------------------
.macro U32_COPY_VAR targetAddr,sourceAddr
   lda sourceAddr+0
   sta targetAddr+0
   lda sourceAddr+1
   sta targetAddr+1
   lda sourceAddr+2
   sta targetAddr+2
   lda sourceAddr+3
   sta targetAddr+3
.endmacro

;-----------------------------------------------------------------------------
; Add (into a 16-bit var) an immediate 16-bit value                [Test 1-11]
;
; effects: .A
; cycles:  18  (assuming zero page)
;-----------------------------------------------------------------------------
.macro U16_ADD_IMM targetAddr, immediateValue
   clc
   lda targetAddr+0
   adc #<immediateValue
   sta targetAddr+0
   lda targetAddr+1
   adc #>immediateValue
   sta targetAddr+1
.endmacro

;-----------------------------------------------------------------------------
; Add (into a 24-bit var) an immediate 24-bit value                [Test 1-11]
;
; effects: .A
;-----------------------------------------------------------------------------
.macro U24_ADD_IMM targetAddr, immediateValue
   clc
   lda targetAddr+0
   adc #<immediateValue
   sta targetAddr+0
   lda targetAddr+1
   adc #>immediateValue
   sta targetAddr+1
   lda targetAddr+2
   adc #^immediateValue
   sta targetAddr+2
.endmacro

;-----------------------------------------------------------------------------
; Add (into a 16-bit var) the value at an address                  [Test 1-12]
;-----------------------------------------------------------------------------
.macro U16_ADD_VAR targetAddr, valueAddress
   clc
   lda targetAddr+0
   adc valueAddress+0
   sta targetAddr+0
   lda targetAddr+1
   adc valueAddress+1
   sta targetAddr+1
.endmacro

;-----------------------------------------------------------------------------
; Add (into a 24-bit var) the value at an address                  [Test 1-12]
;
; effects: .A
;-----------------------------------------------------------------------------
.macro U24_ADD_VAR targetAddr, valueAddr
   clc
   lda targetAddr+0
   adc valueAddr+0
   sta targetAddr+0
   lda targetAddr+1
   adc valueAddr+1
   sta targetAddr+1
   lda targetAddr+2
   adc valueAddr+2
   sta targetAddr+2
.endmacro

;-----------------------------------------------------------------------------
; Subtract (into a 16-bit var) an immediate 16-bit value           [Test 1-13]
;
; effects: .A
;
; cycles: 18
;-----------------------------------------------------------------------------
.macro U16_SUBTRACT_IMM targetAddr, immediateValue
   sec
   lda targetAddr+0
   sbc #<immediateValue
   sta targetAddr+0
   lda targetAddr+1
   sbc #>immediateValue
   sta targetAddr+1
.endmacro

;-----------------------------------------------------------------------------
; Subtract (into a 16-bit var) the value at the specified address  [Test 1-14]
;
; effects: .A
;-----------------------------------------------------------------------------
.macro U16_SUBTRACT_VAR targetAddr, valueAddress
   sec
   lda targetAddr+0
   sbc valueAddress+0
   sta targetAddr+0
   lda targetAddr+1
   sbc valueAddress+1
   sta targetAddr+1
.endmacro

;-----------------------------------------------------------------------------
; Subtract (into a 32-bit var) the value at the specified address  [Test 1-24]
;
; effects: .A
;-----------------------------------------------------------------------------
.macro U32_SUBTRACT_VAR targetAddr, valueAddress
   sec
   lda targetAddr+0
   sbc valueAddress+0
   sta targetAddr+0
   lda targetAddr+1
   sbc valueAddress+1
   sta targetAddr+1
   lda targetAddr+2
   sbc valueAddress+2
   sta targetAddr+2
   lda targetAddr+3
   sbc valueAddress+3
   sta targetAddr+3
.endmacro

;-----------------------------------------------------------------------------
; Increment (16-bit)                                               [Test 1-15]
;
; cycles: 8 if no carry, 12 if carry
;-----------------------------------------------------------------------------
.macro U16_INC targetAddr
    inc targetAddr+0
    bne :+
    inc targetAddr+1
:
.endmacro

;-----------------------------------------------------------------------------
; Increment (24-bit)                                               [Test 1-15]
;-----------------------------------------------------------------------------
.macro U24_INC targetAddr
    inc targetAddr+0
    bne :+
    inc targetAddr+1
    bne :+
    inc targetAddr+2
:
.endmacro

;-----------------------------------------------------------------------------
; Decrement (16-bit)                                               [Test 1-16]
;
; There's no clever trick for decrement. This macro is just for convenience.
;-----------------------------------------------------------------------------
.macro U16_DEC targetAddr
   U16_SUBTRACT_IMM targetAddr, 1   ; INC trick doesn't work for DEC
.endmacro

;-----------------------------------------------------------------------------
; Shift Left (16-bit) i.e. multiply by 2                           [Test 1-17]
;
; cycles:  10 (assuming zero page)
;-----------------------------------------------------------------------------
.macro U16_ASL targetAddr
   asl targetAddr+0
   rol targetAddr+1
.endmacro

;-----------------------------------------------------------------------------
; Shift Left (24-bit) i.e. multiply by 2                           [Test 1-17]
;
; cycles:  10 (assuming zero page)
;-----------------------------------------------------------------------------
.macro U24_ASL targetAddr
   asl targetAddr+0
   rol targetAddr+1
   rol targetAddr+2
.endmacro

;-----------------------------------------------------------------------------
; Shift Right (16-bit)                                             [Test 1-18]
;-----------------------------------------------------------------------------
.macro U16_LSR targetAddr
   lsr targetAddr+1
   ror targetAddr+0
.endmacro

;-----------------------------------------------------------------------------
; Rotate Left (16-bit)                                             [Test 1-19]
;
; prep: set carry bit as desired
;-----------------------------------------------------------------------------
.macro U16_ROL targetAddr
   rol targetAddr+0
   rol targetAddr+1
.endmacro

;-----------------------------------------------------------------------------
; Rotate Right (16-bit)                                            [Test 1-20]
;
; prep: set carry bit as desired
;-----------------------------------------------------------------------------
.macro U16_ROR targetAddr
   ror targetAddr+1
   ror targetAddr+0
.endmacro

;-----------------------------------------------------------------------------
; Compare (16-bit) against immediate value
;
; @effect is same as CMP instruction ...
;
; Carry (C)  1 means target >= other
;            0 means target <  other
; Zero (Z)   1 means target == other
;            0 means target != other
; Neg (N)    Reflects bit 7 of the (target − other) result
;-----------------------------------------------------------------------------
.macro U16_CMP_IMM targetAddr, otherValue
   lda targetAddr+1
   cmp #>otherValue
   bne :+
   lda targetAddr+0
   cmp #<otherValue
:
.endmacro

;-----------------------------------------------------------------------------
; Compare (32-bit) against immediate 24-bit value
;-----------------------------------------------------------------------------
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


;-----------------------------------------------------------------------------
; Compare (16-bit) against another variable                        [Test 1-22]
;
; cycles: 3+3+3 =  9 (if upper byte not equal (assuming both zero page))
;         6+6+2 = 14 (if upper byte was equal (assuming both zero page))
;-----------------------------------------------------------------------------
.macro U16_CMP_VAR targetAddr, otherAddr
   lda targetAddr+1
   cmp otherAddr+1
   bne :+
   lda targetAddr+0
   cmp otherAddr+0
:
.endmacro

;-----------------------------------------------------------------------------
; Multiply by 5 (16-bit)
;
; The value must be $3333 or less so that multiplying by 5 doesn't rollover.
;
; param: targetAddr is the address of both the input and output
; param: scratchAddr is the address of a 16 bit scratch area
;
; This is a fast way to multiply something by five. We need it because we'll
; do exactly this quite frequently as part of multipying by five-thirds when
; converting VSync counts (at 60 Hz) into hundredths of a second (the unit
; used for GIF delays, and the unit supported by our sleep subroutine).
;
; This works by virtue of the target already holding its value, so all we need
; to do is add in the value of (target * 4) which we calculate in scratch.
;-----------------------------------------------------------------------------
.macro U16_MULTIPLY_BY_FIVE targetAddr, scratchAddr
   U16_COPY_VAR scratchAddr, targetAddr
   U16_ASL      targetAddr
   U16_ASL      targetAddr
   U16_ADD_VAR  targetAddr, scratchAddr
.endmacro

;-----------------------------------------------------------------------------
; Divide by 3 (16-bit)
;
; param: targetAddr is the address of both the input and output
; param: scratchTotalAddr is the address of a 24-bit scratch area
; param: scratchPartialAddr is the address of another 24-bit scratch area
; effect: .X
;
; This is a fast way to divide something by three. It is essential to the
; afore-mentioned "multiply by five-thirds" trick we need to do often.
;
; $55 / $100 is roughly one third.  Note, $55 is %0101 0101
;
; So, we can multiply by $5555 then divide by $10000 and it will be the same
; as multiplying by 1 and dividing by 3.
;
; The trick is to do "partial products" for each "on" bit in $55 and
; accumulate them into the output.
;
; Basic logic is:
;   scratch = target
;   total = target           ...  now total has b0's place
;   total += (scratch << 2)  ...  accumulate b2's place
;   total += (scratch << 2)  ...  accumulate b4's place
;   total += (scratch << 2)  ...  accumulate b6's place
;   target = total / $100    ...  upper 2 bytes of 24-bit total
;
; note that we keep re-using scratch because we WANT the side-effect of
; having left-shifted it two times in the previous step.
;
; Since 24-bit operations are bulky machine-code-wise, we can save space
; in the resulting executable by doing that shift-then-add stuff in a loop
; of three.
;-----------------------------------------------------------------------------
.macro U16_DIVIDE_BY_THREE targetAddr, scratchTotalAddr, scratchPartialAddr
   lda targetAddr+0
   sta scratchTotalAddr+0
   sta scratchPartialAddr+0
   lda targetAddr+1
   sta scratchTotalAddr+1
   sta scratchPartialAddr+1
   stz scratchTotalAddr+2
   stz scratchPartialAddr+2

   ldx #3
:  U24_ASL scratchPartialAddr
   U24_ASL scratchPartialAddr
   U24_ADD_VAR scratchTotalAddr, scratchPartialAddr
   dex
   bne :-

   lda scratchTotalAddr+1
   sta targetAddr+0
   lda scratchTotalAddr+2
   sta targetAddr+1
.endmacro

;==============================================================================
; U16_SLOW_MULTIPLY
;
; A crude multiply implementation based on an addition loop.  Only use this
; in situations where performance is not an issue.  This is seriously slow.
;
; It also assumes the result won't rollover 16 bits.
;
; @param  resultAddr     address where the 16-bit result goes
; @param  valueAddr      address of the value to multiply
; @param  multiplierAddr address of the 8-bit multiplier
;
; @effect valueAddr      holds the result
; @effect multiplierAddr value gets clobbered
;==============================================================================
.macro U16_SLOW_MULTIPLY resultAddr, valueAddr, multiplierAddr
   U16_COPY_VAR resultAddr, valueAddr
   phy
      ldy multiplierAddr
@slow_multiply_loop:
      dey
      beq @slow_multiply_done
      U16_ADD_VAR resultAddr, valueAddr
      bra @slow_multiply_loop
@slow_multiply_done:
   ply
.endmacro   


;==============================================================================
; U16_SLOW_DIVIDE
;
; A crude division implementation based on a subtraction loop.  Only use this
; in situations where performance is not an issue.  This is seriously slow.
;
; @param  quotientAddr the address where the 16-bit quotient goes
; @param  dividendAddr the address holding the 16-bit dividend
; @param  divisorAddr  the address holding the 16-bit divisor
; @effect dividendAddr holds the 16-bit remainder
;==============================================================================
.macro U16_SLOW_DIVIDE quotientAddr, dividendAddr, divisorAddr
   U16_STZ quotientAddr

@slow_divide_loop:
   U16_CMP_VAR dividendAddr, divisorAddr
   bcc @slow_divide_done

   U16_SUBTRACT_VAR dividendAddr, divisorAddr
   U16_INC quotientAddr
   bra @slow_divide_loop

@slow_divide_done:
.endmacro   





.endif