.export test_suite_0

.segment "RODATA"

test_array_data: .byte $11,$22,$33,$44

.segment "CODE"

.include "../include/global.inc"
.include "../include/math.inc"
.include "../include/xunit.inc"
.include "../include/zeropage.inc"

;##############################################################################
; Although all the things tested in this test have no dependencies, some of
; them are so fundamental that they are useful to use when writing other tests.
; Hence, they are tested here in a very carefully chosen order.
;
; It is critical that a test never uses production code until AFTER it that
; production code has itself been tested. Every test suite hereafter should
; ideally only depend on things tested in an earlier suite.
;##############################################################################
.proc test_suite_0: near

   ;---------------------------------------------------------------------------
   ; TEST 00 (simple macros that everything else depends upon)
   ;
   ;            U8_COPY_IMM     U8_COPY_VAR
   ; U16_STZ    U16_COPY_IMM    U16_COPY_VAR
   ; U24_STZ    U24_COPY_IMM    U24_COPY_VAR
   ; U32_STZ                    U32_COPY_VAR
   ;
   ; ARRAY_COPY
   ;---------------------------------------------------------------------------
   lda #$55
   sta ZP_VOLATILE_A
   sta ZP_VOLATILE_B
   U16_STZ ZP_VOLATILE_AB
   ASSERT_VAR_U16_EQUALS_IMM $0000, $0000, ZP_VOLATILE_AB

   lda #$55
   sta ZP_VOLATILE_A
   sta ZP_VOLATILE_B
   sta ZP_VOLATILE_C
   U24_STZ ZP_VOLATILE_ABC
   ASSERT_VAR_U24_EQUALS_IMM $0001, $000000, ZP_VOLATILE_ABC

   lda #$55
   sta ZP_VOLATILE_A
   sta ZP_VOLATILE_B
   sta ZP_VOLATILE_C
   sta ZP_VOLATILE_D
   U32_STZ ZP_VOLATILE_ABCD
   ASSERT_VAR_U16_EQUALS_IMM $0002, $0000, ZP_VOLATILE_AB
   ASSERT_VAR_U16_EQUALS_IMM $0003, $0000, ZP_VOLATILE_CD

   stz ZP_VOLATILE_A
   U8_COPY_IMM ZP_VOLATILE_A, $AA
   ASSERT_VAR_U8_EQUALS_IMM $0010, $AA, ZP_VOLATILE_A

   U16_STZ ZP_VOLATILE_AB
   U16_COPY_IMM ZP_VOLATILE_AB, $AABB
   ASSERT_VAR_U16_EQUALS_IMM $0011, $AABB, ZP_VOLATILE_AB

   U24_STZ ZP_VOLATILE_ABC
   U24_COPY_IMM ZP_VOLATILE_ABC, $AABBCC
   ASSERT_VAR_U24_EQUALS_IMM $0012, $AABBCC, ZP_VOLATILE_ABC

   U16_COPY_IMM ZP_VOLATILE_EF, $AABB
   U16_COPY_IMM ZP_VOLATILE_GH, $CCDD
   U24_COPY_IMM ZP_VOLATILE_JKL, $FACADE

   stz ZP_VOLATILE_A
   U8_COPY_VAR ZP_VOLATILE_B, ZP_VOLATILE_E
   ASSERT_VAR_U8_EQUALS_IMM $0020, $BB, ZP_VOLATILE_B

   U16_STZ ZP_VOLATILE_AB
   U16_COPY_VAR ZP_VOLATILE_AB, ZP_VOLATILE_EF
   ASSERT_VAR_U16_EQUALS_IMM $0021, $AABB, ZP_VOLATILE_AB

   U24_STZ ZP_VOLATILE_ABC
   U24_COPY_VAR ZP_VOLATILE_ABC, ZP_VOLATILE_JKL
   ASSERT_VAR_U24_EQUALS_IMM $0022, $FACADE, ZP_VOLATILE_ABC

   U32_STZ ZP_VOLATILE_ABCD
   U32_COPY_VAR ZP_VOLATILE_ABCD, ZP_VOLATILE_EFGH
   ASSERT_VAR_U16_EQUALS_IMM $0023, $AABB, ZP_VOLATILE_AB
   ASSERT_VAR_U16_EQUALS_IMM $0024, $CCDD, ZP_VOLATILE_CD
   
   ;---------------------------------------------------------------------------
   ; TEST 01 (add, subtract)
   ;
   ; U16_ADD_IMM   U16_ADD_VAR   U16_SUB_IMM   U16_SUB_VAR
   ;---------------------------------------------------------------------------
   U16_COPY_IMM ZP_VOLATILE_AB, $00FE
   U16_COPY_IMM ZP_VOLATILE_CD, $0004

   U16_ADD_IMM ZP_VOLATILE_AB, $0004
   ASSERT_VAR_U16_EQUALS_IMM $0100, $0102, ZP_VOLATILE_AB

   U16_SUB_IMM ZP_VOLATILE_AB, $0004
   ASSERT_VAR_U16_EQUALS_IMM $0101, $00FE, ZP_VOLATILE_AB

   U16_ADD_VAR ZP_VOLATILE_AB, ZP_VOLATILE_CD
   ASSERT_VAR_U16_EQUALS_IMM $0102, $0102, ZP_VOLATILE_AB

   U16_SUB_VAR ZP_VOLATILE_AB, ZP_VOLATILE_CD
   ASSERT_VAR_U16_EQUALS_IMM $0103, $00FE, ZP_VOLATILE_AB

   PASS
.endproc

