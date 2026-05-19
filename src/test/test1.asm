.export test_suite_1

.import func_open_inputstream
.import func_close_inputstream
.import func_append_access_mode
.import func_strlen
.import func_prep_for_active_buffering
.import func_vera_flip_stage

.segment "RODATA"

test_filename: .asciiz "slurp.bin,r"

expect_aaa_buffer: .byte $61,$62,$63,$64,$2C,$57,$00 ; abcd,w

test12_expect_1111: .byte $00,$11,$11,$00
test12_expect_2222: .byte $00,$22,$22,$00
test12_expect_3333: .byte $00,$33,$33,$00
test12_expect_4444: .byte $00,$44,$44,$00

test13_expect: .byte $11,$00,$00,$22,$33,$44,$44,$44

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

   lda #4
   ldx #<RAM_VOLATILE_BUF
   ldy #>RAM_VOLATILE_BUF
   jsr KERNAL_MACPTR              ; should get first 4 chars 112233
   jsr KERNAL_ACPTR               ; should get the next char 55
   sta u8data1
   jsr func_close_inputstream

   ASSERT_VAR_U8_EQUALS_IMM $1101, $11, RAM_VOLATILE_BUF+0
   ASSERT_VAR_U8_EQUALS_IMM $1102, $22, RAM_VOLATILE_BUF+1
   ASSERT_VAR_U8_EQUALS_IMM $1103, $33, RAM_VOLATILE_BUF+2
   ASSERT_VAR_U8_EQUALS_IMM $1104, $44, RAM_VOLATILE_BUF+3
   ASSERT_VAR_U8_EQUALS_IMM $1105, $55, u8data1

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