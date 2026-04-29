.export test_suite_1

.import func_open_inputstream
.import func_close_inputstream
.import func_strlen

.segment "RODATA"

test_filename: .asciiz "test.txt,r"
expect_varsa:  .byte $61,$62,$63,$64,$65,$66,$67,$68,$69,$6A,$6B,$00
expect_array:  .byte $6C,$6D,$6E,$6F,$70,$00
expect_comma:  .byte $6C,$6D,$6E,$6F,$70,$2C,$57,$00 ; ,w

.segment "CODE"

.include "../include/file.inc"
.include "../include/global.inc"
.include "../include/math.inc"
.include "../include/math2.inc"
.include "../include/xunit.inc"

.proc test_suite_1: near

   ;---------------------------------------------------------------------------
   ; TEST 10 (math2 stuff)
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

   ;---------------------------------------------------------------------------
   ; TEST 11 (file stuff)
   ;
   ; func_open_inputstream
   ; func_close_inputstream
   ;
   ; APPEND_ACCESS_MODE_TO_FILENAME
   ; SLURP_INTO_A  
   ; SLURP_ARRAY
   ; SLURP_VAR8
   ; SLURP_VAR16
   ; SLURP_VAR24
   ; SLURP_VAR32
   ;---------------------------------------------------------------------------
   ldx #<test_filename
   ldy #>test_filename
   jsr func_open_inputstream

   SLURP_VAR32 ZP_VOLATILE_ABCD   ; first for chars are "abcd"
   SLURP_VAR16 ZP_VOLATILE_EF     ; next 2 chars are "ef"
   SLURP_VAR24 ZP_VOLATILE_GHI    ; next 3 chars are "ghi"
   SLURP_VAR8  ZP_VOLATILE_J      ; next 1 char is "j"
   SLURP_INTO_A                   ; next 1 char is "k"
   sta ZP_VOLATILE_K  
   lda #5
   SLURP_ARRAY RAM_VOLATILE_BUF   ; next 5 chars are "lmnop"
   jsr func_close_inputstream

   ; values A to J loaded into the "vars", and K was plunked in
   ; right after that, so we can validate in one contiguous chunk    
   ASSERT_RAM_EQUALS_ARRAY $1100, $0A, expect_varsa, ZP_VOLATILE_A
   
   ; values L to O went to the array
   ASSERT_RAM_EQUALS_ARRAY $1101, $04, expect_array, RAM_VOLATILE_BUF

   ; important: this next test assumes the previous one established that
   ; RAM_VOLATILE_BUF has the expected content. It's just missing a NULL
   ; which we need for the next test, so we'll just slap a NULL in there.
   stz RAM_VOLATILE_BUF+5
   APPEND_ACCESS_MODE_TO_FILENAME RAM_VOLATILE_BUF, 'w'
   ASSERT_RAM_EQUALS_ARRAY $1102, $06, expect_comma, RAM_VOLATILE_BUF
   
   
   ;---------------------------------------------------------------------------
   ; TEST 12 (string stuff)
   ;
   ; func_strlen
   ;---------------------------------------------------------------------------
   ldx #<expect_array
   ldy #>expect_array
   jsr func_strlen
   ASSERT_A_EQUALS_IMM $1200, $05

   PASS

.endproc

