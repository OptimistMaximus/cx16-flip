.ifndef XUNIT_INC
        XUNIT_INC = 1

;#############################################################################
;
; All tests are assumed to have a 16-bit "id" in which the high byte is the
; test number, and the low byte is the assertion number within the test. Due
; to the simplicity of the logic that prints test status to screen (upon
; failure), please make sure that all values use only digits 0-9.  For example
; $1234 is Test 12's 34th assertion.
; 
;#############################################################################
        
;=============================================================================
; ASSERT_PASS
;
; Pass unconditionally.
;
; @effect Carry bit clear, indicating success
;=============================================================================
.macro PASS
   ldx #0
   ldy #0
   clc
   rts
.endmacro

;=============================================================================
; FAIL
;
; Fail unconditionally
;
; @param  testId the test id
; @effect .X holds the test number
; @effect .Y holds the assertion number
; @effect Carry bit set, indicating failure
;=============================================================================
.macro FAIL testId
   ldx #>testId
   ldy #<testId
   sec
   rts
.endmacro

;-----------------------------------------------------------------------------
; ASSERT_VAR_U8_EQUALS_IMM - assert 8-bit value at addr
;                            equals the specified immediate value
;-----------------------------------------------------------------------------
.macro ASSERT_VAR_U8_EQUALS_IMM testId, expectValue, actualAddr
.scope
   lda #expectValue
   cmp actualAddr
   beq @ok
   FAIL testId
@ok:
.endscope
.endmacro

;-----------------------------------------------------------------------------
; ASSERT_VAR_U16_EQUALS_IMM - assert 16-bit value at addr
;                             equals the specified immediate value
;-----------------------------------------------------------------------------
.macro ASSERT_VAR_U16_EQUALS_IMM testId, expectValue, actualAddr
.scope
   lda actualAddr+0
   cmp #<expectValue
   beq @ok_low
   FAIL testId
@ok_low:
   lda actualAddr+1
   cmp #>expectValue
   beq @ok_high
   FAIL testId
@ok_high:
.endscope
.endmacro

;-----------------------------------------------------------------------------
; ASSERT_VAR_U24_EQUALS_IMM - assert 24-bit value at addr
;                             equals the specified immediate value
;-----------------------------------------------------------------------------
.macro ASSERT_VAR_U24_EQUALS_IMM testId,expectValue,actualAddr
.scope
   lda actualAddr+0
   cmp #<expectValue
   beq @ok_low
   FAIL testId
@ok_low:
   lda actualAddr+1
   cmp #>expectValue
   beq @ok_mid
   FAIL testId
@ok_mid:
   lda actualAddr+2
   cmp #^expectValue
   beq @ok_high
   FAIL testId
@ok_high:
.endscope
.endmacro



.endif

