.export test_suite_2

.import func_find_arg
.import func_open_inputstream
.import func_close_inputstream
.import func_slurp_header
.import func_slurp_chunk
.import handle_invalid
.import handle_unsupported
.import handle_frame_type
.import handle_color_256
.import handle_color_64
.import handle_delta_fli
.import handle_black
.import handle_byte_run
.import handle_fli_copy
.import func_load_palette

.include "../include/global.inc"
.include "../include/math.inc"
.include "../include/math2.inc"
.include "../include/vera.inc"
.include "../include/xunit.inc"

.segment "RODATA"     ; Read-Only data

fn_header_x: .asciiz "headerx.bin,r"
fn_frame:    .asciiz "frame.bin,r"
fn_color_x:  .asciiz "colorx.bin,r"



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

; for unit tests we need to preserve .A .X .Y
.macro OPEN_INPUTSTREAM_R filenameLabel, replacementOffset, replacementChar
   pha
      phx
         phy
            U8_COPY_IMM filenameLabel+replacementOffset, replacementChar
            ldx #<filenameLabel
            ldy #>filenameLabel
            jsr func_open_inputstream
         ply
      plx
   pla
.endmacro

.macro OPEN_INPUTSTREAM filenameLabel
   pha
      phx
         phy
            ldx #<filenameLabel
            ldy #>filenameLabel
            jsr func_open_inputstream
         ply
      plx
   pla
.endmacro

; for unit tests we need to preserve .A .X .Y
.macro CLOSE_INPUTSTREAM
   pha
      phx
         phy
            jsr func_close_inputstream
         ply
      plx
   pla
.endmacro

; set palette buffer to all zeros
.proc sub_prep_palette_buffer: near
   SET_VERA_ADDR24_IMM $01, VRAM_PALETTE_BUFFER, $10
   ldx #0
:  stx VERA_DATA1
   stx VERA_DATA1
   inx
   bne :-
   rts
.endproc

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
   OPEN_INPUTSTREAM_R fn_header_x, 6, '0'
   jsr func_slurp_header
   CLOSE_INPUTSTREAM
   ASSERT_A_EQUALS_IMM       $3000,        RC_SUCCESS
   ASSERT_VAR_U16_EQUALS_IMM $3001, $04A1, ZP16_delaySyncs
   ASSERT_VAR_U16_EQUALS_IMM $3002, $0024, ZP16_numFrames
   ASSERT_VAR_U16_EQUALS_IMM $3003, $0140, ZP16_width
   ASSERT_VAR_U8_EQUALS_IMM  $3004, $C8,   ZP8_height
   ASSERT_VAR_U8_EQUALS_IMM  $3005, $08,   ZP8_depth
   ASSERT_VAR_U8_EQUALS_IMM  $3006, $00,   ZP8_activeLayer
   
   OPEN_INPUTSTREAM_R fn_header_x, 6, '1'
   jsr func_slurp_header
   CLOSE_INPUTSTREAM
   ASSERT_A_EQUALS_IMM $3010, RC_UNSUPPORTED_FILE_TYPE
   ASSERT_X_EQUALS_IMM $3011, $12 
   ASSERT_Y_EQUALS_IMM $3012, $AF

   OPEN_INPUTSTREAM_R fn_header_x, 6, '2'
   jsr func_slurp_header
   CLOSE_INPUTSTREAM
   ASSERT_A_EQUALS_IMM $3020, RC_WIDTH_TOO_BIG
   ASSERT_X_EQUALS_IMM $3021, $80
   ASSERT_Y_EQUALS_IMM $3022, $02

   OPEN_INPUTSTREAM_R fn_header_x, 6, '3'
   jsr func_slurp_header
   CLOSE_INPUTSTREAM
   ASSERT_A_EQUALS_IMM $3030, RC_HEIGHT_TOO_BIG
   ASSERT_X_EQUALS_IMM $3031, $B0
   ASSERT_Y_EQUALS_IMM $3032, $0B

   OPEN_INPUTSTREAM_R fn_header_x, 6, '4'
   jsr func_slurp_header
   CLOSE_INPUTSTREAM
   ASSERT_A_EQUALS_IMM $3040, RC_DEPTH_TOO_BIG
   ASSERT_X_EQUALS_IMM $3041, $B0
   ASSERT_Y_EQUALS_IMM $3042, $0B

   OPEN_INPUTSTREAM_R fn_header_x, 6, '5'
   jsr func_slurp_header
   CLOSE_INPUTSTREAM
   ASSERT_A_EQUALS_IMM $3050, RC_SPEED_TOO_HIGH
   ASSERT_X_EQUALS_IMM $3051, $12
   ASSERT_Y_EQUALS_IMM $3052, $34

   ;---------------------------------------------------------------------------
   ; TEST 31 - handle_invalid
   ;           handle_unsupported
   ;           handle_frame_type
   ;---------------------------------------------------------------------------
   U16_COPY_IMM ZP16_chunkType, $AABB
   jsr handle_invalid
   ASSERT_A_EQUALS_IMM $3100, RC_INVALID_CHUNK_TYPE
   ASSERT_X_EQUALS_IMM $3101, $BB
   ASSERT_Y_EQUALS_IMM $3102, $AA

   jsr handle_unsupported
   ASSERT_A_EQUALS_IMM $3103, RC_UNSUPPORTED_CHUNK_TYPE
   ASSERT_X_EQUALS_IMM $3104, $BB
   ASSERT_Y_EQUALS_IMM $3105, $AA

   OPEN_INPUTSTREAM fn_frame
   jsr handle_frame_type
   CLOSE_INPUTSTREAM
   ASSERT_A_EQUALS_IMM $3106, RC_SUCCESS
   ASSERT_VAR_U16_EQUALS_IMM $3107, $3412, ZP16_numSubChunks

   ;---------------------------------------------------------------------------
   ; TEST 32 - handle_color_64
   ;           handle_color_256
   ;
   ; COLOR0.BIN is tested once with 64 color parsing, and once with 256.
   ; This proves that skips and bit shuffling works fine.
   ;
   ; COLOR1.BIN tests that a single packet with copy count 256 works fine.
   ; COLOR2.BIN tests that 256 packets of copy  count 1 works fine. This is a
   ; ridiculous edge case that probably no encoder would use, but it's legal. 
   ;---------------------------------------------------------------------------
   OPEN_INPUTSTREAM_R fn_color_x, 5, '0'
   jsr sub_prep_palette_buffer
   jsr handle_color_64
   CLOSE_INPUTSTREAM
   ASSERT_A_EQUALS_IMM $3200, RC_SUCCESS
   SET_VERA_ADDR24_IMM $01, VRAM_PALETTE_BUFFER, $10
   ASSERT_VRAM_U16_EQUALS_IMM $3201, $0000 ; color 0 skip
   ASSERT_VRAM_U16_EQUALS_IMM $3202, $0101 ; color 1 skip
   ASSERT_VRAM_U16_EQUALS_IMM $3203, $0EA7 ; color 2
   ASSERT_VRAM_U16_EQUALS_IMM $3204, $0303 ; color 3 skip
   ASSERT_VRAM_U16_EQUALS_IMM $3205, $0666 ; color 4
   ASSERT_VRAM_U16_EQUALS_IMM $3206, $0BBB ; color 5
   ASSERT_VRAM_U16_EQUALS_IMM $3207, $0606 ; color 6 untouched
   
   OPEN_INPUTSTREAM_R fn_color_x, 5, '0'
   jsr sub_prep_palette_buffer
   jsr handle_color_256
   CLOSE_INPUTSTREAM
   ASSERT_A_EQUALS_IMM $3210, RC_SUCCESS
   SET_VERA_ADDR24_IMM $01, VRAM_PALETTE_BUFFER, $10
   ASSERT_VRAM_U16_EQUALS_IMM $3211, $0000 ; color 0 skip
   ASSERT_VRAM_U16_EQUALS_IMM $3212, $0101 ; color 1 skip
   ASSERT_VRAM_U16_EQUALS_IMM $3213, $0321 ; color 2
   ASSERT_VRAM_U16_EQUALS_IMM $3214, $0303 ; color 3 skip
   ASSERT_VRAM_U16_EQUALS_IMM $3215, $0111 ; color 4
   ASSERT_VRAM_U16_EQUALS_IMM $3216, $0222 ; color 5
   ASSERT_VRAM_U16_EQUALS_IMM $3217, $0606 ; color 6 untouched

   OPEN_INPUTSTREAM_R fn_color_x, 5, '1'
   jsr sub_prep_palette_buffer
   jsr handle_color_256
   CLOSE_INPUTSTREAM
   ASSERT_A_EQUALS_IMM $3220, RC_SUCCESS
   SET_VERA_ADDR24_IMM $01, VRAM_PALETTE_BUFFER, $10
   lda #0
@test32_copy_packet_count_loop:
   ASSERT_VRAM_U16_EQUALS_IMM $3221, $0111  ; color 0,2,4,etc
   ASSERT_VRAM_U16_EQUALS_IMM $3222, $0222  ; color 1,3,5,etc
   iny
   cpy #128
   bne @test32_copy_packet_count_loop

   
   OPEN_INPUTSTREAM_R fn_color_x, 5, '2'
   jsr sub_prep_palette_buffer
   jsr handle_color_256
   CLOSE_INPUTSTREAM
   ASSERT_A_EQUALS_IMM $3230, RC_SUCCESS
   SET_VERA_ADDR24_IMM $01, VRAM_PALETTE_BUFFER, $10
   lda #0
@test32_verify_packet_count_loop:
   ASSERT_VRAM_U16_EQUALS_IMM $3231, $0111  ; color 0,2,4,etc
   ASSERT_VRAM_U16_EQUALS_IMM $3232, $0222  ; color 1,3,5,etc
   iny
   cpy #128
   bne @test32_verify_packet_count_loop

   ;---------------------------------------------------------------------------
   ; TEST 33 - func_load_palette
   ;---------------------------------------------------------------------------
   jsr sub_prep_palette_buffer
   jsr func_load_palette
   SET_VERA_ADDR24_IMM $01, $1FA00, $10
   ASSERT_VRAM_U16_EQUALS_IMM $3300, $0000
   ASSERT_VRAM_U16_EQUALS_IMM $3301, $0101
   ASSERT_VRAM_U16_EQUALS_IMM $3302, $0202
   SET_VERA_ADDR24_IMM $01, $1FB00, $10
   ASSERT_VRAM_U16_EQUALS_IMM $3303, $8080
   ASSERT_VRAM_U16_EQUALS_IMM $3304, $8181
   ASSERT_VRAM_U16_EQUALS_IMM $3305, $8282
   SET_VERA_ADDR24_IMM $01, $1FBFA, $10
   ASSERT_VRAM_U16_EQUALS_IMM $3306, $FDFD
   ASSERT_VRAM_U16_EQUALS_IMM $3307, $FEFE
   ASSERT_VRAM_U16_EQUALS_IMM $3308, $FFFF
   
   


   ;---------------------------------------------------------------------------
   ; TEST 34 - 
   ;---------------------------------------------------------------------------

   ;---------------------------------------------------------------------------
   ; TEST 35 - 
   ;---------------------------------------------------------------------------

   ;---------------------------------------------------------------------------
   ; TEST 36 - 
   ;---------------------------------------------------------------------------

         
   PASS

.endproc


