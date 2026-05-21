.export test_suite_1

.import func_open_inputstream
.import func_close_inputstream
.import func_append_access_mode
.import func_strlen
.import func_prep_for_active_buffering
.import func_vera_flip_stage
.import func_cache_init
.import func_cache_read_into_a
.import func_cache_read_into_vram
.import func_cache_dupe_into_vram
.import smc_anchor_for_cache_size

.segment "RODATA"

test_filename: .asciiz "slurp.bin,r"

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

VRAM_BUFFER_LINE_0 := $0FA00 + VRAM_IMAGE_LINE_0
VRAM_BUFFER_LINE_1 := $0FA00 + VRAM_IMAGE_LINE_1
VRAM_BUFFER_LINE_2 := $0FA00 + VRAM_IMAGE_LINE_2
VRAM_BUFFER_LINE_3 := $0FA00 + VRAM_IMAGE_LINE_3

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
   U16_COPY_IMM ZP_VOLATILE_AB, $4444
   U8_COPY_IMM ZP_VOLATILE_C, $03
   U16_SLOW_MULTIPLY ZP_VOLATILE_EF, ZP_VOLATILE_AB, ZP_VOLATILE_C
   ASSERT_VAR_U16_EQUALS_IMM $1000, $CCCC, ZP_VOLATILE_EF ; result

   U16_COPY_IMM ZP_VOLATILE_AB, $2222
   U16_COPY_IMM ZP_VOLATILE_CD, $0777
   U16_SLOW_DIVIDE ZP_VOLATILE_EF, ZP_VOLATILE_AB, ZP_VOLATILE_CD
   ASSERT_VAR_U16_EQUALS_IMM $1001, $0004, ZP_VOLATILE_EF ; result
   ASSERT_VAR_U16_EQUALS_IMM $1002, $0446, ZP_VOLATILE_AB ; remainder

   ;---------------------------------------------------------------------------
   ; TEST 11 (file stuff)
   ;
   ; func_open_inputstream
   ; func_close_inputstream
   ;---------------------------------------------------------------------------
   ldx #<test_filename
   ldy #>test_filename
   jsr func_open_inputstream

   jsr KERNAL_ACPTR               ; should get first value 00
   sta u8data1

   lda #4
   ldx #<RAM_VOLATILE_BUF
   ldy #>RAM_VOLATILE_BUF
   jsr KERNAL_MACPTR              ; should get next 4 values 11223344

   jsr KERNAL_ACPTR               ; should get next value 55
   sta u8data2
   jsr func_close_inputstream

   ASSERT_VAR_U8_EQUALS_IMM $1105, $00, u8data1
   ASSERT_VAR_U8_EQUALS_IMM $1101, $11, RAM_VOLATILE_BUF+0
   ASSERT_VAR_U8_EQUALS_IMM $1102, $22, RAM_VOLATILE_BUF+1
   ASSERT_VAR_U8_EQUALS_IMM $1103, $33, RAM_VOLATILE_BUF+2
   ASSERT_VAR_U8_EQUALS_IMM $1104, $44, RAM_VOLATILE_BUF+3
   ASSERT_VAR_U8_EQUALS_IMM $1105, $55, u8data2

   ;---------------------------------------------------------------------------
   ; TEST 12 (video stuff)
   ;
   ; func_prep_for_active_buffering
   ; ADVANCE_LINE_FOR_ACTIVE_BUFFERING
   ; func_vera_flip_stage
   ;---------------------------------------------------------------------------
   jsr sub_init_stages
   lda #0                                       ; prep for line 0
   jsr func_prep_for_active_buffering
   lda VERA_DATA0
   lda #$AA
   sta VERA_DATA0

   ADVANCE_LINE_FOR_ACTIVE_BUFFERING            ; line 1 skipped
   ADVANCE_LINE_FOR_ACTIVE_BUFFERING            ; line 2
   lda VERA_DATA0
   lda #$BB
   sta VERA_DATA0

   lda #1                                       ; prep for line 1
   jsr func_prep_for_active_buffering
   lda VERA_DATA0
   lda #$CC
   sta VERA_DATA0

   SET_VERA_ADDR24_IMM $00, VRAM_BUFFER_LINE_0, $10
   ASSERT_VRAM_U8_EQUALS_IMM $1200, $00
   ASSERT_VRAM_U8_EQUALS_IMM $1201, $AA
   ASSERT_VRAM_U8_EQUALS_IMM $1202, $00

   SET_VERA_ADDR24_IMM $00, VRAM_BUFFER_LINE_1, $10
   ASSERT_VRAM_U8_EQUALS_IMM $1203, $00
   ASSERT_VRAM_U8_EQUALS_IMM $1204, $CC
   ASSERT_VRAM_U8_EQUALS_IMM $1205, $00

   SET_VERA_ADDR24_IMM $00, VRAM_BUFFER_LINE_2, $10
   ASSERT_VRAM_U8_EQUALS_IMM $1206, $00
   ASSERT_VRAM_U8_EQUALS_IMM $1207, $BB
   ASSERT_VRAM_U8_EQUALS_IMM $1208, $00

   jsr func_vera_flip_stage                     ; flip buffer to image

   SET_VERA_ADDR24_IMM $00, VRAM_IMAGE_LINE_0, $10
   ASSERT_VRAM_U8_EQUALS_IMM $1210, $00
   ASSERT_VRAM_U8_EQUALS_IMM $1211, $AA
   ASSERT_VRAM_U8_EQUALS_IMM $1212, $00

   SET_VERA_ADDR24_IMM $00, VRAM_IMAGE_LINE_1, $10
   ASSERT_VRAM_U8_EQUALS_IMM $1213, $00
   ASSERT_VRAM_U8_EQUALS_IMM $1214, $CC
   ASSERT_VRAM_U8_EQUALS_IMM $1215, $00

   SET_VERA_ADDR24_IMM $00, VRAM_IMAGE_LINE_2, $10
   ASSERT_VRAM_U8_EQUALS_IMM $1216, $00
   ASSERT_VRAM_U8_EQUALS_IMM $1217, $BB
   ASSERT_VRAM_U8_EQUALS_IMM $1218, $00

   ;---------------------------------------------------------------------------
   ; TEST 13 (string stuff)
   ;
   ; func_append_access_mode
   ; func_strlen
   ;---------------------------------------------------------------------------
   lda #PETSCII_LOWER_W
   ldx #<actual_aaa_buffer
   ldy #>actual_aaa_buffer
   jsr func_append_access_mode
   ASSERT_A_EQUALS_IMM     $1300, 6
   ASSERT_RAM_EQUALS_ARRAY $1301, $06, expect_aaa_buffer, actual_aaa_buffer

   ldx #<expect_aaa_buffer
   ldy #>expect_aaa_buffer
   jsr func_strlen
   ASSERT_A_EQUALS_IMM $1310, 6

   ;---------------------------------------------------------------------------
   ; TEST 13 (slurp 'n skip)
   ;
   ; SLURP_INTO_A
   ; SLURP_INTO_VERA
   ; SLURP_INTO_VERA_REPEATED
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

   SLURP_INTO_A              ; burn first byte 00
   SLURP_INTO_A              ; VRAM gains 11
   sta VERA_DATA0
   lda #2                    ; VRAM skips ahead 2 bytes
   SKIP_PIXELS
   lda #2                    ; VRAM gains 2233
   SLURP_INTO_VRAM
   lda #3                    ; VRAM gains 444444
   SLURP_INTO_VRAM_REPEATED

   lda #1
   SLURP_INTO_BUFFER u8data1 ; discard 55

   SLURP_INTO_U8  u8data2    ; var set to 66
   SLURP_INTO_U16 u16data    ; var set to 7788
   SLURP_INTO_U24 u24data    ; var set to 99AABB
   SLURP_INTO_U32 u32data    ; var set to CCDDEEFF

   jsr func_close_inputstream

   ASSERT_VAR_U8_EQUALS_IMM  $1301, $66, u8data2
   ASSERT_VAR_U16_EQUALS_IMM $1302, $8877, u16data
   ASSERT_VAR_U24_EQUALS_IMM $1303, $BBAA99, u24data
   ASSERT_VAR_U16_EQUALS_IMM $1304, $DDCC, u32data+0 ; low half
   ASSERT_VAR_U16_EQUALS_IMM $1305, $FFEE, u32data+2 ; high half

   SET_VERA_ADDR24_IMM $00, VRAM_IMAGE_LINE_0, $10
   ASSERT_VRAM_EQUALS_ARRAY $1310, 7, test13_expect

   ;---------------------------------------------------------------------------
   ; NARF! performance baseline
   ;---------------------------------------------------------------------------
   SET_VERA_ADDR24_IMM $00, VRAM_IMAGE_LINE_0, $10

   ldx #<test_filename
   ldy #>test_filename
   jsr func_open_inputstream

   jsr KERNAL_ACPTR   
   sta VERA_DATA0
   
   lda #64                       ; read next 64
   ldx #<VERA_DATA0
   ldy #>VERA_DATA0
   sec                           ; don't advance (assume VERA auto-inc)
   jsr KERNAL_MACPTR 
      
   jsr func_close_inputstream
   
   ;---------------------------------------------------------------------------
   ; Test 14 (cache stuff)
   ;
   ; This test is most effective when running on the emulator using the host FS
   ; because there, MACPTR seems to very predictably always read the exact
   ; number of bytes asked for. So our test logic here can be very confident
   ; that page loads are happening based on a precise set of test requests.
   ; This might not be true on real hardware, so when this test runs on real
   ; hardware it will just be generally exercising cache, covering a
   ; non-deterministic subset of scenarios and edge cases.
   ;---------------------------------------------------------------------------
   jsr sub_init_stages_line0
   SET_VERA_ADDR24_IMM $00, VRAM_IMAGE_LINE_0, $10
   
   lda #16
   sta smc_anchor_for_cache_size+1 ; force cache size for test convenience

   ldx #<test_filename
   ldy #>test_filename
   jsr func_open_inputstream
   jsr func_cache_init           ; should load 16 bytes into cache

   ;
   ; single read, cache hit scenario with bytes remaining
   ;
   jsr func_cache_read_into_a
   jsr func_cache_read_into_a
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
   jsr func_cache_read_into_a
   sta VERA_DATA0
   
   ;
   ; single read, cache miss, should load 16 fresh, leaving 15 remaining
   ;
   jsr func_cache_read_into_a
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
   ASSERT_VRAM_EQUALS_ARRAY $1400, $48, test14_expect
   
   
   
      
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