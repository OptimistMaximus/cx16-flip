.export test_suite_2

.segment "CODE"

.include "../include/kernal.inc"
.include "../include/global.inc"
.include "../include/xunit.inc"

.proc test_suite_2: near
   ASSERT_FAIL $20, $01
   rts
.endproc

