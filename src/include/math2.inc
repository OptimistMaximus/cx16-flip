.ifndef MATH2_INC
        MATH2_INC = 1
        
        
.include "math.inc"

;#############################################################################        
; Similar to "math.inc", these are macros that provide conveniences for doing
; basic 16, 24, and 32 bit stuff. But, they are built upon the macros in
; "math.inc" so they are in a separate file for organizational purposes.
;#############################################################################        

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

   U16_SUB_VAR dividendAddr, divisorAddr
   U16_INC quotientAddr
   bra @slow_divide_loop

@slow_divide_done:
.endmacro





.endif