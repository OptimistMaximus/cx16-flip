.export test_suite_1

.segment "CODE"

.include "../include/global.inc"
.include "../include/math.inc"
.include "../include/math2.inc"
.include "../include/xunit.inc"

.proc test_suite_1: near

   ;---------------------------------------------------------------------------
   ; TEST 10
   ;
   ; U16_SLOW_MULTIPLY
   ; U16_SLOW_DIVIDE
   ;---------------------------------------------------------------------------
   U16_COPY_IMM ZP_VOLATILE_AB, $4444
   U8_COPY_IMM ZP_VOLATILE_C, $03
   U16_SLOW_MULTIPLY ZP_VOLATILE_OP, ZP_VOLATILE_AB, ZP_VOLATILE_C
   ASSERT_VAR_U16_EQUALS_IMM $1000, $CCCC, ZP_VOLATILE_OP ; result

   U16_COPY_IMM ZP_VOLATILE_AB, $2222
   U16_COPY_IMM ZP_VOLATILE_CD, $0777
   U16_SLOW_DIVIDE ZP_VOLATILE_OP, ZP_VOLATILE_AB, ZP_VOLATILE_CD
   ASSERT_VAR_U16_EQUALS_IMM $1001, $0004, ZP_VOLATILE_OP ; result
   ASSERT_VAR_U16_EQUALS_IMM $1002, $0446, ZP_VOLATILE_AB ; remainder




   PASS

.endproc

