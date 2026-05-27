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
; ASSERT_BEQ - assert .P flag Z is set, such that a beq would branch
;=============================================================================
.macro ASSERT_BEQ testId
    beq :+
    FAIL testId
:
.endmacro

;=============================================================================
; ASSERT_BCS - assert .P flag C is set, such that a bcs would branch
;=============================================================================
.macro ASSERT_BCS testId
    bcs :+
    FAIL testId
:
.endmacro

;=============================================================================
; ASSERT_BCC - assert .P flag C is clear, such that a bcc would branch
;=============================================================================
.macro ASSERT_BCC testId
    bcc :+
    FAIL testId
:
.endmacro

;=============================================================================
; ASSERT_A_EQUALS_IMM - assert .A
;                       equals the specified immediate value
;=============================================================================
.macro ASSERT_A_EQUALS_IMM testId, expectValue
   cmp #expectValue
   beq :+
   FAIL testId
:
.endmacro

;=============================================================================
; ASSERT_A_EQUALS_VAR - assert .A
;                       equals the value at the specified immediate address
;=============================================================================
.macro ASSERT_A_EQUALS_VAR testId, expectAddr
   cmp expectAddr
   beq :+
   FAIL testId
:
.endmacro

;=============================================================================
; ASSERT_X_EQUALS_IMM - assert .X
;                       equals the specified immediate value
;=============================================================================
.macro ASSERT_X_EQUALS_IMM testId, expectValue
   cpx #expectValue
   beq :+
   FAIL testId
:
.endmacro

;=============================================================================
; ASSERT_Y_EQUALS_IMM - assert .Y
;                       equals the specified immediate value
;=============================================================================
.macro ASSERT_Y_EQUALS_IMM testId, expectValue
   cpy #expectValue
   beq :+
   FAIL testId
:
.endmacro

;=============================================================================
; ASSERT_VAR_U8_EQUALS_IMM - assert 8-bit value at addr
;                            equals the specified immediate value
;=============================================================================
.macro ASSERT_VAR_U8_EQUALS_IMM testId, expectValue, actualAddr
   lda #expectValue
   cmp actualAddr
   beq :+
   FAIL testId
:
.endmacro

;=============================================================================
; ASSERT_VAR_U16_EQUALS_IMM - assert 16-bit value at addr
;                             equals the specified immediate value
;=============================================================================
.macro ASSERT_VAR_U16_EQUALS_IMM testId, expectValue, actualAddr
   lda actualAddr+0
   cmp #<expectValue
   beq :+
   FAIL testId
:
   lda actualAddr+1
   cmp #>expectValue
   beq :+
   FAIL testId
:
.endmacro

;=============================================================================
; ASSERT_VAR_U24_EQUALS_IMM - assert 24-bit value at addr
;                             equals the specified immediate value
;=============================================================================
.macro ASSERT_VAR_U24_EQUALS_IMM testId,expectValue,actualAddr
   lda actualAddr+0
   cmp #<expectValue
   beq :+
   FAIL testId
:
   lda actualAddr+1
   cmp #>expectValue
   beq :+
   FAIL testId
:
   lda actualAddr+2
   cmp #^expectValue
   beq :+
   FAIL testId
:
.endmacro

;=============================================================================
; ASSERT_VAR_U32_EQUALS_IMM - assert 32-bit value at addr
;                             equals the specified immediate value
;
; Note, ca65 does not offers any syntax for extracting the most significant
;       byte, so we'll specify 32-bit values as their MSB and the remaining
;       24 bits as a 24-bit value (big endian)
;=============================================================================
.macro ASSERT_VAR_U32_EQUALS_IMM testId, msb, expectValue, actualAddr
   lda actualAddr+0
   cmp #<expectValue
   beq :+
   FAIL testId
:
   lda actualAddr+1
   cmp #>expectValue
   beq :+
   FAIL testId
:
   lda actualAddr+2
   cmp #^expectValue
   beq :+
   FAIL testId
:
   lda actualAddr+3
   cmp #msb
   beq :+
   FAIL testId
:
.endmacro

;=============================================================================
; ASSERT_RAM_EQUALS_ARRAY_INDIRECT
; @param expectAddr is an absolute address in RAM
; @param actualPtr  is a zero-page pointer holding address of actual data
;=============================================================================
.macro ASSERT_RAM_EQUALS_ARRAY_INDIRECT testId, maxOffset, expectAddr, actualPtr
   phy
   ldy #0
:  lda (actualPtr),y
   cmp expectAddr,y
   bne :+
   cpy #maxOffset
   beq :++
   iny
   bra :-
:  plx
   FAIL testId
:  ply
.endmacro

;=============================================================================
; ASSERT_RAM_EQUALS_ARRAY
; @param expectAddr is an absolute address in RAM
; @param actualAddr is an absolute address in RAM
;=============================================================================
.macro ASSERT_RAM_EQUALS_ARRAY testId, maxOffset, expectAddr, actualAddr
   phx
   ldx #0
:  lda actualAddr,x
   cmp expectAddr,x
   bne :+
   cpx #maxOffset
   beq :++
   inx
   bra :-
:  plx
   FAIL testId
:  plx
.endmacro

;=============================================================================
; ASSERT_VRAM_EQUALS_ARRAY
;
; This assumes VERA address is established, data channel 0, stride 1
;=============================================================================
.macro ASSERT_VRAM_EQUALS_ARRAY testId, maxOffset, expectAddr
   ldx #0
:  lda VERA_DATA0
   cmp expectAddr,x
   beq :+
   FAIL testId
:
   cpx #maxOffset
   beq :+
   inx
   bra :--
:
.endmacro

;=============================================================================
; ASSERT_VRAM_U8_EQUALS_IMM
;
; This assumes VERA address is established, data channel 0, stride 1
;=============================================================================
.macro ASSERT_VRAM_U8_EQUALS_IMM testId, expectValue
   lda VERA_DATA0
   ASSERT_A_EQUALS_IMM testId, expectValue
.endmacro

;=============================================================================
; ASSERT_VRAM_U8_EQUALS_VAR
;
; This assumes VERA address is established, data channel 0, stride 1
;=============================================================================
.macro ASSERT_VRAM_U8_EQUALS_VAR testId, expectAddr
   lda VERA_DATA0
   ASSERT_A_EQUALS_VAR testId, expectAddr
.endmacro

;=============================================================================
; ASSERT_VRAM_U16_EQUALS_IMM
;
; This assumes VERA address is established, data channel 0, stride 1
;=============================================================================
.macro ASSERT_VRAM_U16_EQUALS_IMM testId, expectValue
   lda VERA_DATA0
   ASSERT_A_EQUALS_IMM testId, <expectValue
   lda VERA_DATA0
   ASSERT_A_EQUALS_IMM testId, >expectValue
.endmacro

;=============================================================================
; ASSERT_VPEEK_EQUALS_IMM
;=============================================================================
.macro ASSERT_VPEEK_EQUALS_IMM testId, expectValue, actualAddr
   VPEEK actualAddr
   ASSERT_A_EQUALS_IMM testId, expectValue
.endmacro


.endif

