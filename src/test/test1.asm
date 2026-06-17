.export test_suite_1

.import func_open_inputstream
.import func_close_inputstream
.import func_load_image
.import func_load_palette
.import func_cache_load_page
.import func_cache_read_into_vram
.import func_print_hex
.import func_cache_init
.import func_init_vram_table

.segment "RODATA"

fn_cache11: .asciiz "cache11.bin,r"
fn_cache11_end:

fn_cache260: .asciiz "cache260.bin,r"
fn_cache260_end:

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

var32scratch1: .res 4, $00
var24scratch1: .res 3, $00
var16scratch1: .res 2, $00
var16scratch2: .res 2, $00
var16scratch3: .res 2, $00
var8scratch1:  .res 1
var8scratch2:  .res 1


.segment "CODE"

.include "../include/cache.inc"
.include "../include/global.inc"
.include "../include/math.inc"
.include "../include/math2.inc"
.include "../include/petscii.inc"
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

.macro OPEN_INPUTSTREAM filenameLabel, filenameLabelEnd
   lda #(filenameLabelEnd - filenameLabel)
   ldx #<filenameLabel
   ldy #>filenameLabel
   jsr func_open_inputstream
.endmacro

.macro CLOSE_INPUTSTREAM
   jsr func_close_inputstream
.endmacro



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
   U16_COPY_IMM var16scratch1, $4444
   U8_COPY_IMM var8scratch1, $03
   U16_SLOW_MULTIPLY var16scratch2, var16scratch1, var8scratch1
   ASSERT_VAR_U16_EQUALS_IMM $1000, $CCCC, var16scratch2 ; result

   U16_COPY_IMM var16scratch1, $2222
   U16_COPY_IMM var16scratch2, $0777
   U16_SLOW_DIVIDE var16scratch3, var16scratch1, var16scratch2
   ASSERT_VAR_U16_EQUALS_IMM $1001, $0004, var16scratch3 ; result
   ASSERT_VAR_U16_EQUALS_IMM $1002, $0446, var16scratch1 ; remainder

   ;---------------------------------------------------------------------------
   ; TEST 11 (file stuff)
   ;
   ; func_open_inputstream
   ; func_close_inputstream
   ;---------------------------------------------------------------------------
   OPEN_INPUTSTREAM fn_cache11, fn_cache11_end
   jsr KERNAL_ACPTR               ; should get first value AA
   sta u8data1
   CLOSE_INPUTSTREAM
   ASSERT_VAR_U8_EQUALS_IMM $1100, $AA, u8data1

   ;---------------------------------------------------------------------------
   ; TEST 12 (video stuff)
   ;
   ; func_init_vram_table
   ; SET_VRAM_ADDR_FOR_FULL_LINE
   ; SET_VRAM_ADDR_FOR_DELTA_LINE
   ; SET_VRAM_ADDR_FOR_SCREEN_LINE
   ; ADVANCE_VERA_ADDR_FOR_DELTA_PACKET
   ;---------------------------------------------------------------------------
   jsr func_init_vram_table

   ; Line 0 is (0 * 320) + $0FA00 with high byte OR'ed with $10
   ASSERT_VAR_U8_EQUALS_IMM $1200, $00, VRAM_ADDR_TABLE_L+0
   ASSERT_VAR_U8_EQUALS_IMM $1201, $FA, VRAM_ADDR_TABLE_M+0
   ASSERT_VAR_U8_EQUALS_IMM $1202, $10, VRAM_ADDR_TABLE_H+0

   ; Line 4 is (4 * 320) + $0FA00 with high byte OR'ed with $10
   ASSERT_VAR_U8_EQUALS_IMM $1203, $00, VRAM_ADDR_TABLE_L+4
   ASSERT_VAR_U8_EQUALS_IMM $1204, $FF, VRAM_ADDR_TABLE_M+4
   ASSERT_VAR_U8_EQUALS_IMM $1205, $10, VRAM_ADDR_TABLE_H+4

   ; Line 199 is (199 * 320) + $0FA00 with high byte OR'ed with $10
   ASSERT_VAR_U8_EQUALS_IMM $1206, $C0, VRAM_ADDR_TABLE_L+199
   ASSERT_VAR_U8_EQUALS_IMM $1207, $F2, VRAM_ADDR_TABLE_M+199
   ASSERT_VAR_U8_EQUALS_IMM $1208, $11, VRAM_ADDR_TABLE_H+199

   SET_VRAM_ADDR_FOR_FULL_LINE
   ASSERT_VAR_U24_EQUALS_IMM $1210, $10FA00, VERA_ADDRx_L

   ldx #0
   SET_VRAM_ADDR_FOR_DELTA_LINE
   ASSERT_VAR_U24_EQUALS_IMM $1210, $10FA00, VERA_ADDRx_L

   ldx #100 ; (100*320) + $FA00 with high byte OR'ed with $10
   SET_VRAM_ADDR_FOR_DELTA_LINE
   ASSERT_VAR_U24_EQUALS_IMM $1210, $117700, VERA_ADDRx_L

   lda #$55 ; advance $55 beyond previous setting
   ADVANCE_VERA_ADDR_FOR_DELTA_PACKET
   ASSERT_VAR_U24_EQUALS_IMM $1220, $117755, VERA_ADDRx_L

   ldx #5
   SET_VRAM_ADDR_FOR_SCREEN_LINE
   ASSERT_VAR_U24_EQUALS_IMM $1240, $300640, VERA_ADDRx_L

   ;---------------------------------------------------------------------------
   ; TEST 13a (basic reads)
   ;
   ; SIP_INTO_A
   ; SIP_INTO_U32
   ; SIP_INTO_U24
   ; SIP_INTO_U16
   ; SIP_INTO_U8
   ;
   ; SIP_INTO_A as the very first read tests just-in-time page in for single
   ; reads (upon which all macros in this test are based).
   ;---------------------------------------------------------------------------
   .scope test13a
      jsr func_cache_init
      OPEN_INPUTSTREAM fn_cache11, fn_cache11_end
      SIP_INTO_A
      sta var8scratch2
      SIP_INTO_U32 var32scratch1
      SIP_INTO_U24 var24scratch1
      SIP_INTO_U16 var16scratch1
      SIP_INTO_U8 var8scratch1
      CLOSE_INPUTSTREAM

      ASSERT_VAR_U8_EQUALS_IMM  $1300, $AA, var8scratch2
      ASSERT_VAR_U32_EQUALS_IMM $1301, $00,$112233, var32scratch1
      ASSERT_VAR_U24_EQUALS_IMM $1302, $445566, var24scratch1
      ASSERT_VAR_U16_EQUALS_IMM $1303, $7788, var16scratch1
      ASSERT_VAR_U8_EQUALS_IMM  $1304, $99, var8scratch1
   .endscope

   ;---------------------------------------------------------------------------
   ; TEST 13b (read into VRAM)
   ;
   ; SIP_INTO_OBLIVION
   ; SIP_INTO_VRAM_REPEATED
   ; SIP_INTO_VRAM
   ;
   ; The first SIP_INTO_VRAM in this test runs in a situation where there is
   ; definitely enough bytes remaining for that read.
   ;
   ; The second SIP_INTO_VRAM in this test runs in a situation where there is
   ; not enough remaining bytes, such that it will be broken into two reads.
   ;---------------------------------------------------------------------------
   .scope test13b
      jsr func_cache_init
      jsr sub_init_stages_line0
      SET_VERA_ADDR24_IMM $00, $00000, $10

      OPEN_INPUTSTREAM fn_cache260, fn_cache260_end

      SIP_INTO_OBLIVION 3                 ; skip 00,11,22

      lda #3
      SIP_INTO_VRAM_REPEATED              ; read next 33 and write 3 times

      .scope
         lda #2                           ; small enough to avoid bulk read
         SIP_INTO_VRAM                    ; read 44,55 and write
      .endscope

      SIP_INTO_OBLIVION 10                ; burn 66-FF
      .scope
         lda #$90                         ; bulk read where avail >= request
         SIP_INTO_VRAM
      .endscope

      SIP_INTO_OBLIVION $0C               ; burn most of row of AA
      .scope
         lda #$58                         ; bulk read where avail < request
         SIP_INTO_VRAM
      .endscope
      CLOSE_INPUTSTREAM

      ; reset VRAM address and verify what was written (and untouched)
      SET_VERA_ADDR24_IMM $00, $00000, $10
      ASSERT_VRAM_U8_EQUALS_IMM $1320, $33
      ASSERT_VRAM_U8_EQUALS_IMM $1321, $33
      ASSERT_VRAM_U8_EQUALS_IMM $1322, $33
      ASSERT_VRAM_U8_EQUALS_IMM $1323, $44
      ASSERT_VRAM_U8_EQUALS_IMM $1324, $55
      ASSERT_VRAM_U8_EQUALS_IMM $1325, $11

      SET_VERA_ADDR24_IMM $00, $00094, $10
      ASSERT_VRAM_U8_EQUALS_IMM $1330, $99
      ASSERT_VRAM_U8_EQUALS_IMM $1331, $AA
      ASSERT_VRAM_U8_EQUALS_IMM $1332, $AA
      ASSERT_VRAM_U8_EQUALS_IMM $1333, $AA
      ASSERT_VRAM_U8_EQUALS_IMM $1334, $AA
      ASSERT_VRAM_U8_EQUALS_IMM $1335, $BB

      SET_VERA_ADDR24_IMM $00, $000E8, $10
      ASSERT_VRAM_U8_EQUALS_IMM $1340, $FF
      ASSERT_VRAM_U8_EQUALS_IMM $1341, $DE
      ASSERT_VRAM_U8_EQUALS_IMM $1342, $AD
      ASSERT_VRAM_U8_EQUALS_IMM $1343, $BE
      ASSERT_VRAM_U8_EQUALS_IMM $1344, $EF
      ASSERT_VRAM_U8_EQUALS_IMM $1345, $00 ; untouched

   .endscope

   ;---------------------------------------------------------------------------
   ; TEST 13c (read into VRAM)
   ;
   ; SIP_INTO_VRAM
   ;
   ; This tests an additional scenario where the current offset is $FF, and
   ; the next read is a bulk read.
   ;---------------------------------------------------------------------------
   .scope test13c
      jsr func_cache_init
      jsr sub_init_stages_line0
      SET_VERA_ADDR24_IMM $00, $00000, $10

      OPEN_INPUTSTREAM fn_cache260, fn_cache260_end
      lda #33
      SIP_INTO_VRAM
      CLOSE_INPUTSTREAM

      SET_VERA_ADDR24_IMM $00, $0000F, $10
      ASSERT_VRAM_U8_EQUALS_IMM $1330, $FF
      ASSERT_VRAM_U8_EQUALS_IMM $1331, $11

      SET_VERA_ADDR24_IMM $00, $0001F, $10
      ASSERT_VRAM_U8_EQUALS_IMM $1332, $11
      ASSERT_VRAM_U8_EQUALS_IMM $1333, $22
      ASSERT_VRAM_U8_EQUALS_IMM $1324, $00 ; (untouched)
   .endscope


   ;---------------------------------------------------------------------------
   ; TEST 14 (VRAM address calculations)
   ;---------------------------------------------------------------------------

   ;---------------------------------------------------------------------------
   ; Test 15
   ;---------------------------------------------------------------------------


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