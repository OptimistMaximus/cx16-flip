.export test_suite_1

.import func_open_inputstream
.import func_close_inputstream
.import func_calc_delta_line_addr
.import func_load_image
.import func_load_palette
.import func_cache_read_into_vram
.import func_cache_dupe_into_vram
.import func_print_hex
.import func_cache_init
.import smc_anchor_for_cache_size

.segment "RODATA"

test_filename: .asciiz "slurp.bin,r"
test_filename_end:

expect_aaa_buffer: .byte $61,$62,$63,$64,$2C,$57,$00 ; abcd,w

test12_expect_1111: .byte $00,$11,$11,$00
test12_expect_2222: .byte $00,$22,$22,$00
test12_expect_3333: .byte $00,$33,$33,$00
test12_expect_4444: .byte $00,$44,$44,$00

test13_expect: .byte $11,$00,$00,$22,$33,$44,$44,$44

test14_expect:
.byte $11,$22,$22,$22,$33,$44,$55,$66,$77,$88,$99,$AA,$BB,$CC,$DD,$EE
.byte $FF,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$1A,$1B,$1C,$1D,$1E
.byte $1F,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$2A,$2B,$2C,$2D,$2E
.byte $2F,$30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3A,$3B,$3C,$3D,$3E
.byte $3F,$40,$41,$42,$43,$44,$45,$46,$47

.segment "DATA"

actual_aaa_buffer: .byte $61,$62,$63,$64,$00,$00,$00 ; abcd

u24VeraAddr: .res 3, $00

u8data1: .res 1, $00
u8data2: .res 1, $00
u16data: .res 2, $00
u24data: .res 3, $00
u32data: .res 4, $00
u64data: .res 8, $00

.segment "CODE"

.include "../include/global.inc"
.include "../include/math.inc"
.include "../include/math2.inc"
.include "../include/petscii.inc"
.include "../include/slurp.inc"
.include "../include/video.inc"
.include "../include/xunit.inc"

VRAM_IMAGE_LINE_0  := $00000
VRAM_IMAGE_LINE_1  := $00140
VRAM_IMAGE_LINE_2  := $00280
VRAM_IMAGE_LINE_3  := $003C0
VRAM_IMAGE_LINE_4  := $00500

VRAM_BUFFER_LINE_0 := $0FA00 + VRAM_IMAGE_LINE_0
VRAM_BUFFER_LINE_1 := $0FA00 + VRAM_IMAGE_LINE_1
VRAM_BUFFER_LINE_2 := $0FA00 + VRAM_IMAGE_LINE_2
VRAM_BUFFER_LINE_3 := $0FA00 + VRAM_IMAGE_LINE_3
VRAM_BUFFER_LINE_4 := $0FA00 + VRAM_IMAGE_LINE_4

.macro BURN_THEN_WRITE value
   lda VERA_DATA0 ; burn
   lda #value
   sta VERA_DATA0
   sta VERA_DATA0
.endmacro

.proc test_suite_1: near

   ;---------------------------------------------------------------------------
   ; TEST 10 (math2 stuff)
   ;
   ; U16_SLOW_MULTIPLY
   ; U16_SLOW_DIVIDE
   ;---------------------------------------------------------------------------
   U16_COPY_IMM GR16_scratch1, $4444
   U8_COPY_IMM GR8_scratch1, $03
   U16_SLOW_MULTIPLY GR16_scratch2, GR16_scratch1, GR8_scratch1
   ASSERT_VAR_U16_EQUALS_IMM $1000, $CCCC, GR16_scratch2 ; result

   U16_COPY_IMM GR16_scratch1, $2222
   U16_COPY_IMM GR16_scratch2, $0777
   U16_SLOW_DIVIDE GR16_scratch3, GR16_scratch1, GR16_scratch2
   ASSERT_VAR_U16_EQUALS_IMM $1001, $0004, GR16_scratch3 ; result
   ASSERT_VAR_U16_EQUALS_IMM $1002, $0446, GR16_scratch1 ; remainder

   ;---------------------------------------------------------------------------
   ; TEST 11 (file stuff)
   ;
   ; func_open_inputstream
   ; func_close_inputstream
   ;---------------------------------------------------------------------------
   lda #(test_filename_end - test_filename)
   ldx #<test_filename
   ldy #>test_filename
   jsr func_open_inputstream
   jsr KERNAL_ACPTR               ; should get first value 00
   sta u8data1
   jsr KERNAL_ACPTR               ; should get next value 11
   sta u8data2
   jsr func_close_inputstream

   ASSERT_VAR_U8_EQUALS_IMM $1100, $00, u8data1
   ASSERT_VAR_U8_EQUALS_IMM $1101, $11, u8data2

   ;---------------------------------------------------------------------------
   ; TEST 12 (video stuff)
   ;
   ; CALCULATE_VRAM_LINE_ADDR
   ; ESTABLISH_LINE_FOR_FULL
   ; ESTABLISH_LINE_FOR_DELTA
   ; ADVANCE_LINE_FOR_DELTA
   ;
   ; func_load_stage
   ; func_load_palette
   ;---------------------------------------------------------------------------
   jsr sub_init_stages

   ldx #0 ; line skip
   jsr CALCULATE_VRAM_LINE_ADDR GR16_scratch1
   ASSERT_VAR_U24_EQUALS_IMM $1200, $00000, ZP24_vramOffset

   ldx #4 ; line skip
   jsr CALCULATE_VRAM_LINE_ADDR GR16_scratch1
   ASSERT_VAR_U24_EQUALS_IMM $1201, $05000, ZP24_vramOffset



   ESTABLISH_LINE_FOR_FULL

   .scope test12_write_to_stage_line_0
      ldx #0 ; line skip
      jsr CALCULATE_VRAM_LINE_ADDR GR16_scratch1
      ASSERT_VAR_U24_EQUALS_IMM $1200, $0FA00, ZP24_vramOffset

      lda #$AA
      sta VERA_DATA0
      SET_VERA_ADDR24_IMM $00, $0FA00, $10
      ASSERT_VRAM_U8_EQUALS_IMM $1201, $AA
      ASSERT_VRAM_U8_EQUALS_IMM $1202, $00
   .endscope

   .scope test12_write_to_stage_line_4
      ldx #4 ; line skip
      jsr func_calc_delta_line_addr
      ASSERT_VAR_U24_EQUALS_IMM $1210, $0FF00, ZP24_vramOffset

      lda #$BB
      sta VERA_DATA0
      SET_VERA_ADDR24_IMM $00, $0FEFF, $10
      ASSERT_VRAM_U8_EQUALS_IMM $1211, $00
      ASSERT_VRAM_U8_EQUALS_IMM $1212, $BB
      ASSERT_VRAM_U8_EQUALS_IMM $1213, $00
   .endscope

   .scope test12_load_staged_lines_3_to_5
      ldx #3 ; line skip
      lda #4 ; line count
      jsr func_load_image

      SET_VERA_ADDR24_IMM $00, $00000, $10
      ASSERT_VRAM_U8_EQUALS_IMM $1220, $00 ; verify untouched
      ASSERT_VRAM_U8_EQUALS_IMM $1221, $00

      SET_VERA_ADDR24_IMM $00, $004FF, $10 ; verify line 4 copied
      ASSERT_VRAM_U8_EQUALS_IMM $1222, $00
      ASSERT_VRAM_U8_EQUALS_IMM $1223, $BB
      ASSERT_VRAM_U8_EQUALS_IMM $1224, $00
   .endscope

   .scope test12_load_palette
      SET_VERA_ADDR24_IMM $00, $1FA00, $10 ; source
      SET_VERA_ADDR24_IMM $01, $1F400, $10 ; target
      ldx #0                               ; copy sys palette to staging area
   :  lda VERA_DATA0
      sta VERA_DATA1
      lda VERA_DATA0
      sta VERA_DATA1
      dex
      bne :-

      SET_VERA_ADDR24_IMM $00, $1F500, $10 ; now zero out a non-zero color
      stz VERA_DATA0
      stz VERA_DATA0

      jsr func_load_palette                ; then copy it back
      SET_VERA_ADDR24_IMM $00, $1FB00, $10 ; and verify sys palette now has
      ASSERT_VRAM_U8_EQUALS_IMM $1231, $00 ; that corresponding color zeroed
      ASSERT_VRAM_U8_EQUALS_IMM $1232, $00
   .endscope

   ;---------------------------------------------------------------------------
   ; TEST 13
   ;---------------------------------------------------------------------------

   ;---------------------------------------------------------------------------
   ; TEST 14 (slurp 'n skip)
   ;
   ; SLURP_INTO_A
   ; func_cache_read_into_vram
   ; func_cache_dupe_into_vram
   ; SLURP_INTO_U8
   ; SLURP_INTO_U16
   ; SLURP_INTO_U24
   ; SLURP_INTO_U32
   ; SKIP_PIXELS
   ;---------------------------------------------------------------------------
   jsr sub_init_stages_line0
   SET_VERA_ADDR24_IMM $00, VRAM_IMAGE_LINE_0, $10

   ldx #<test_filename
   ldy #>test_filename
   jsr func_open_inputstream
   jsr func_cache_init

   SLURP_INTO_A ; burn first byte 00
   SLURP_INTO_A ; VRAM gains 11
   sta VERA_DATA0
   lda #2                    ; VRAM skips ahead 2 bytes
   SKIP_PIXELS
   lda #2                    ; VRAM gains 2233
   jsr func_cache_read_into_vram
   lda #3                    ; VRAM gains 444444
   jsr func_cache_dupe_into_vram

   SLURP_INTO_OBLIVION 1     ; discard 55

   SLURP_INTO_U8  u8data2    ; var set to 66
   SLURP_INTO_U16 u16data    ; var set to 7788
   SLURP_INTO_U24 u24data    ; var set to 99AABB
   SLURP_INTO_U32 u32data    ; var set to CCDDEEFF

   jsr func_close_inputstream

   ASSERT_VAR_U8_EQUALS_IMM  $1401, $66, u8data2
   ASSERT_VAR_U16_EQUALS_IMM $1402, $8877, u16data
   ASSERT_VAR_U24_EQUALS_IMM $1403, $BBAA99, u24data
   ASSERT_VAR_U16_EQUALS_IMM $1404, $DDCC, u32data+0 ; low half
   ASSERT_VAR_U16_EQUALS_IMM $1405, $FFEE, u32data+2 ; high half

   SET_VERA_ADDR24_IMM $00, VRAM_IMAGE_LINE_0, $10
   ASSERT_VRAM_EQUALS_ARRAY $1410, 7, test13_expect

   ;---------------------------------------------------------------------------
   ; Test 15 (cache stuff)
   ;
   ; This test is most effective when running on the emulator using the host FS
   ; because there, MACPTR seems to very predictably always read the exact
   ; number of bytes asked for. So our test logic here can be very confident
   ; that page loads are happening based on a precise set of test requests.
   ; This might not be true on real hardware, so when this test runs on real
   ; hardware it will just be generally exercising cache, covering a
   ; non-deterministic subset of scenarios and edge cases.
   ;---------------------------------------------------------------------------
   lda #16
   sta smc_anchor_for_cache_size+1 ; force cache size for test convenience

   jsr sub_init_stages_line0
   SET_VERA_ADDR24_IMM $00, VRAM_IMAGE_LINE_0, $10

   ldx #<test_filename
   ldy #>test_filename
   jsr func_open_inputstream
   jsr func_cache_init

   ;
   ; single read, cache hit scenario with bytes remaining
   ;
   SLURP_INTO_A
   SLURP_INTO_A
   sta VERA_DATA0

   ;
   ; single read/dupe, cache hit scenario with bytes remaining
   ;
   lda #3
   jsr func_cache_dupe_into_vram

   ;
   ; multi read, cache hit scenario with bytes remaining
   ; (prior to this we read 3 bytes, so 12 more is 15, leaving 1 remaining)
   ;
   lda #12
   jsr func_cache_read_into_vram

   ;
   ; single read, cache hit but it's an edge-case: the last byte
   ;
   SLURP_INTO_A
   sta VERA_DATA0

   ;
   ; single read, cache miss, should load 16 fresh, leaving 15 remaining
   ;
   SLURP_INTO_A
   sta VERA_DATA0

   ;
   ; now another edge case case: multi-read equal to remaining
   ;
   lda #15
   jsr func_cache_read_into_vram

   ;
   ; edge case, handling a multi-read while cache is exhausted, also
   ; preps for final test by reading 8 bytes, leaving 8 remaining
   ;
   lda #8
   jsr func_cache_read_into_vram

   ;
   ; test split read scenario where we ask for more than is remaining.
   ; at this time there are 8 remaining so we'll ask for 32.  This should
   ; cause 2 page loads behind the scenes.
   lda #32
   jsr func_cache_read_into_vram

   jsr func_close_inputstream

   SET_VERA_ADDR24_IMM $00, VRAM_IMAGE_LINE_0, $10
   ASSERT_VRAM_EQUALS_ARRAY $1508, $48, test14_expect


   PASS

.endproc

; zero out both stages, then reset VERA addresses to line 0
.proc sub_init_stages: near
   jsr sub_init_vera_addresses
   ldx #200
@row_loop:
   jsr sub_init_line
   dex
   bne @row_loop
   rts
.endproc

; zero out only line 0 in both stages, then reset VERA addresses to line 0
.proc sub_init_stages_line0: near
   jsr sub_init_vera_addresses
   jsr sub_init_line
   rts
.endproc

.proc sub_init_vera_addresses: near
   SET_VERA_ADDR24_IMM $00, VRAM_IMAGE_LINE_0, $10
   SET_VERA_ADDR24_IMM $01, VRAM_BUFFER_LINE_0, $10
.endproc

.proc sub_init_line: near
   ldy #160
   lda #0
@column_loop:
   sta VERA_DATA0
   sta VERA_DATA0
   sta VERA_DATA1
   sta VERA_DATA1
   dey
   bne @column_loop
   rts
.endproc