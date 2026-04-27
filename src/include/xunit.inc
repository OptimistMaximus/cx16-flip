.ifndef XUNIT_INC
        XUNIT_INC = 1

;-----------------------------------------------------------------------------
; ASSERT_PASS
;
; Pass unconditionally.
;
; @effect Carry bit clear, indicating success
;-----------------------------------------------------------------------------
.macro ASSERT_PASS
   ldx #0
   ldy #0
   clc
   rts
.endmacro

;-----------------------------------------------------------------------------
; ASSERT_FAIL
;
; Fail unconditionally
;
; @effect .X holds the test number
; @effect .Y holds the assertion number
; @effect Carry bit set, indicating failure
;-----------------------------------------------------------------------------
.macro ASSERT_FAIL testNumber, assertionNumber
   ldx #testNumber
   ldy #assertionNumber
   sec
   rts
.endmacro

.endif

