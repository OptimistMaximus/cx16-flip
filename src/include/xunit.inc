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

;=============================================================================
; ASSERT_BCS - assert .P flag C is set, such that a bcs would branch
;=============================================================================
.macro ASSERT_BCS testId
.scope
    bcs @ok
    FAIL testId
@ok:
.endscope
.endmacro

;=============================================================================
; ASSERT_BCC - assert .P flag C is clear, such that a bcc would branch
;=============================================================================
.macro ASSERT_BCC testId
.scope
    bcc @ok
    FAIL testId
@ok:
.endscope
.endmacro

;=============================================================================
; ASSERT_A_EQUALS_IMM - assert .A
;                       equals the specified immediate value
;=============================================================================
.macro ASSERT_A_EQUALS_IMM testId, expectValue
.scope
   cmp #expectValue
   beq @ok
   FAIL testId
@ok:
.endscope
.endmacro

;=============================================================================
; ASSERT_VAR_U8_EQUALS_IMM - assert 8-bit value at addr
;                            equals the specified immediate value
;=============================================================================
.macro ASSERT_VAR_U8_EQUALS_IMM testId, expectValue, actualAddr
.scope
   lda #expectValue
   cmp actualAddr
   beq @ok
   FAIL testId
@ok:
.endscope
.endmacro

;=============================================================================
; ASSERT_VAR_U16_EQUALS_IMM - assert 16-bit value at addr
;                             equals the specified immediate value
;=============================================================================
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

;=============================================================================
; ASSERT_VAR_U24_EQUALS_IMM - assert 24-bit value at addr
;                             equals the specified immediate value
;=============================================================================
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

;=============================================================================
; ASSERT_RAM_EQUALS_ARRAY - assumes addresses are absolute addresses
;=============================================================================
.macro ASSERT_RAM_EQUALS_ARRAY testId, maxOffset, expectAddr, actualAddr
   phx
   ldx #0
:
   lda actualAddr,x
   cmp expectAddr,x
   bne :+
   cpx #maxOffset
   beq :++
   inx
   bra :-
:
   plx
   FAIL testId
:  plx
.endmacro

.endif

