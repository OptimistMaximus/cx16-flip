.export test_suite_2

.import func_find_arg
.import func_open_inputstream
.import func_close_inputstream
.import func_slurp_header

.include "../include/global.inc"
.include "../include/math.inc"
.include "../include/math2.inc"
.include "../include/xunit.inc"

.segment "RODATA"     ; Read-Only data

fn_header_x: .asciiz "headerx.bin,r"



; "RUN" results in tokenized $8A
test_basic_buffer_no_args:
.byte $8A,$00

; "RUN:REM AA BB" results in tokenized $8A and $8F
test_basic_buffer_compact:
.byte $8A,$3A,$8F,$20,$41,$41,$20,$42,$42,$00

; " RUN  :  REM  AA  BB  " results in trimmed string with inner spaces
test_basic_buffer_spaced_out:
.byte $8A,$20,$20,$3A,$20,$20,$8F,$20,$20,$41,$41,$20,$42,$42,$00

test_arg_expect_aa: .asciiz "aa"
test_arg_expect_bb: .asciiz "bb"

.segment "CODE"

.macro PREP_BASIC_BUFFER sourceLabel
   ldy #$FF
:  iny
   lda sourceLabel,y
   sta $200,y
   bne :-
.endmacro

.macro FIND_ARG arg
   lda #arg
   ldx #<RAM_VOLATILE_BUF
   ldy #>RAM_VOLATILE_BUF
   jsr func_find_arg
.endmacro

.macro PREP_HEADER_FILENAME number
   U8_COPY_IMM fn_header_x+6, '0'
   ldx #<fn_header_x
   ldy #>fn_header_x
.endmacro

.proc test_suite_2: near

   ;---------------------------------------------------------------------------
   ; TEST 20 - func_find_arg
   ;
   ; White box testing: We know func_find_arg parses the BASIC buffer.  We know
   ; the BASIC buffer is located at $200 to $281, including the NULL terminator.
   ; We know the buffer holds tokenized BASIC, left and right trimmed.
   ;---------------------------------------------------------------------------
   PREP_BASIC_BUFFER test_basic_buffer_no_args
   FIND_ARG 0
   ASSERT_BCS $2000

   PREP_BASIC_BUFFER test_basic_buffer_compact
   FIND_ARG 0
   ASSERT_BCC $2010
   ASSERT_RAM_EQUALS_ARRAY $2011, 2, test_arg_expect_aa, RAM_VOLATILE_BUF

   FIND_ARG 1
   ASSERT_BCC $2012
   ASSERT_RAM_EQUALS_ARRAY $2013, 2, test_arg_expect_bb, RAM_VOLATILE_BUF

   FIND_ARG 2
   ASSERT_BCS $2014

   PREP_BASIC_BUFFER test_basic_buffer_spaced_out
   FIND_ARG 0
   ASSERT_BCC $2020
   ASSERT_RAM_EQUALS_ARRAY $2021, 2, test_arg_expect_aa, RAM_VOLATILE_BUF

   FIND_ARG 1
   ASSERT_BCC $2022
   ASSERT_RAM_EQUALS_ARRAY $2023, 2, test_arg_expect_bb, RAM_VOLATILE_BUF

   FIND_ARG 2
   ASSERT_BCS $2024
   
   ;---------------------------------------------------------------------------
   ; TEST 30 - slurp_header
   ;---------------------------------------------------------------------------
   PREP_HEADER_FILENAME '0'
   jsr func_open_inputstream
   jsr func_slurp_header
   jsr func_close_inputstream
   ASSERT_A_EQUALS_IMM       $3000,        RC_SUCCESS
   ASSERT_VAR_U16_EQUALS_IMM $3001, $04A1, ZP16_delaySyncs
   ASSERT_VAR_U16_EQUALS_IMM $3002, $0024, ZP16_numFrames
   ASSERT_VAR_U16_EQUALS_IMM $3003, $0140, ZP16_width
   ASSERT_VAR_U8_EQUALS_IMM  $3004, $C8,   ZP8_height
   ASSERT_VAR_U8_EQUALS_IMM  $3005, $08,   ZP8_depth
   ASSERT_VAR_U8_EQUALS_IMM  $3006, $00,   ZP8_activeLayer
   
   PREP_HEADER_FILENAME '1'
   jsr func_open_inputstream
   jsr func_slurp_header
   jsr func_close_inputstream
   ASSERT_A_EQUALS_IMM $3010, RC_DEPTH_TOO_BIG
   ASSERT_X_EQUALS_IMM $3011, $B0
   ASSERT_Y_EQUALS_IMM $3012, $0B

   PREP_HEADER_FILENAME '2'
   jsr func_open_inputstream
   jsr func_slurp_header
   jsr func_close_inputstream
   ASSERT_A_EQUALS_IMM $3020, RC_HEIGHT_TOO_BIG
   ASSERT_X_EQUALS_IMM $3021, $B0
   ASSERT_Y_EQUALS_IMM $3022, $0B

   PREP_HEADER_FILENAME '3'
   jsr func_open_inputstream
   jsr func_slurp_header
   jsr func_close_inputstream
   ASSERT_A_EQUALS_IMM $3030, RC_SPEED_TOO_HIGH
   ASSERT_X_EQUALS_IMM $3031, $12
   ASSERT_Y_EQUALS_IMM $3032, $34

   PREP_HEADER_FILENAME '4'
   jsr func_open_inputstream
   jsr func_slurp_header
   jsr func_close_inputstream
   ASSERT_A_EQUALS_IMM $3040, RC_UNSUPPORTED_FILE_TYPE
   ASSERT_X_EQUALS_IMM $3041, $12 
   ASSERT_Y_EQUALS_IMM $3042, $AF

   PREP_HEADER_FILENAME '5'
   jsr func_open_inputstream
   jsr func_slurp_header
   jsr func_close_inputstream
   ASSERT_A_EQUALS_IMM $3050, RC_WIDTH_TOO_BIG
   ASSERT_X_EQUALS_IMM $3051, $80
   ASSERT_Y_EQUALS_IMM $3052, $02



   PASS

.endproc

