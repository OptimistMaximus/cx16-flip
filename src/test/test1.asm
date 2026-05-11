.export test_suite_1

.import func_open_inputstream
.import func_close_inputstream
.import func_slurp_into_buffer
.import func_slurp_into_a
.import func_append_access_mode
.import func_strlen
.import func_prep_for_active_buffering
.import func_vera_flip_stage

.segment "RODATA"

test_filename: .asciiz "slurp.bin,r"
expect_abcdw:  .byte $61,$62,$63,$64,$2C,$57,$00 ; abcd,w
test12_expect_1111: .byte $00,$11,$11,$00
test12_expect_2222: .byte $00,$22,$22,$00
test12_expect_3333: .byte $00,$33,$33,$00
test12_expect_4444: .byte $00,$44,$44,$00

.segment "DATA"

u24VeraAddr: .res 3, $00

.segment "CODE"

.include "../include/global.inc"
.include "../include/math.inc"
.include "../include/math2.inc"
.include "../include/petscii.inc"
.include "../include/video.inc"
.include "../include/xunit.inc"

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
   ; func_slurp_into_a
   ; func_slurp_into_buffer
   ; func_append_access_mode
   ; func_strlen
   ;---------------------------------------------------------------------------
   ldx #<test_filename
   ldy #>test_filename
   jsr func_open_inputstream

   lda #4
   jsr func_slurp_into_buffer     ; should get first 4 chars "abcd"
   jsr func_slurp_into_a          ; should get the next char "e"
   pha
      jsr func_close_inputstream
   pla

   ASSERT_A_EQUALS_IMM      $1100, $65
   ASSERT_VAR_U8_EQUALS_IMM $1101, $61, RAM_VOLATILE_BUF+0
   ASSERT_VAR_U8_EQUALS_IMM $1102, $62, RAM_VOLATILE_BUF+1
   ASSERT_VAR_U8_EQUALS_IMM $1103, $63, RAM_VOLATILE_BUF+2
   ASSERT_VAR_U8_EQUALS_IMM $1104, $64, RAM_VOLATILE_BUF+3

   ; since the above test just passed, we know the first 4 bytes of the
   ; volatile buffer are a,b,c,d. All that's missing is a null terminator!
   ; After appending the access mode, it should be length 6: "abcd,w"
   stz RAM_VOLATILE_BUF+4
   lda #PETSCII_LOWER_W
   ldx #<RAM_VOLATILE_BUF
   ldy #>RAM_VOLATILE_BUF
   jsr func_append_access_mode
   ASSERT_A_EQUALS_IMM     $1110, 6
   ASSERT_RAM_EQUALS_ARRAY $1111, $06, expect_abcdw, RAM_VOLATILE_BUF

   ldx #<RAM_VOLATILE_BUF
   ldy #>RAM_VOLATILE_BUF
   jsr func_strlen
   ASSERT_A_EQUALS_IMM $1120, 6

   ;---------------------------------------------------------------------------
   ; TEST 12 (video stuff)
   ;
   ; func_prep_for_active_buffering
   ; ADVANCE_LINE_FOR_ACTIVE_BUFFERING
   ; func_vera_flip_stage
   ;---------------------------------------------------------------------------
   jsr sub_init_stages

   .scope test12_prep_stage_0                      ; stage 0 active
      U8_COPY_IMM ZP8_activeStage, STAGE_0_ACTIVE
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

      SET_VERA_ADDR24_IMM $00, $00000, $10         ; expect line 0
      ASSERT_VRAM_U8_EQUALS_IMM $1200, $00
      ASSERT_VRAM_U8_EQUALS_IMM $1201, $AA
      ASSERT_VRAM_U8_EQUALS_IMM $1202, $00

      SET_VERA_ADDR24_IMM $00, $00140, $10         ; expect line 1
      ASSERT_VRAM_U8_EQUALS_IMM $1203, $00
      ASSERT_VRAM_U8_EQUALS_IMM $1204, $CC
      ASSERT_VRAM_U8_EQUALS_IMM $1205, $00

      SET_VERA_ADDR24_IMM $00, $00280, $10         ; expect line 2
      ASSERT_VRAM_U8_EQUALS_IMM $1206, $00
      ASSERT_VRAM_U8_EQUALS_IMM $1207, $BB
      ASSERT_VRAM_U8_EQUALS_IMM $1208, $00

      jsr func_vera_flip_stage                     ; flip active to 1
      ASSERT_VAR_U8_EQUALS_IMM $1209, STAGE_1_ACTIVE, ZP8_activeStage

      SET_VERA_ADDR24_IMM $00, $0F800, $10         ; expect line 0
      ASSERT_VRAM_U8_EQUALS_IMM $1210, $00
      ASSERT_VRAM_U8_EQUALS_IMM $1211, $AA
      ASSERT_VRAM_U8_EQUALS_IMM $1212, $00

      SET_VERA_ADDR24_IMM $00, $0F940, $10         ; expect line 1
      ASSERT_VRAM_U8_EQUALS_IMM $1213, $00
      ASSERT_VRAM_U8_EQUALS_IMM $1214, $CC
      ASSERT_VRAM_U8_EQUALS_IMM $1215, $00

      SET_VERA_ADDR24_IMM $00, $0FA80, $10         ; expect line 2
      ASSERT_VRAM_U8_EQUALS_IMM $1216, $00
      ASSERT_VRAM_U8_EQUALS_IMM $1217, $BB
      ASSERT_VRAM_U8_EQUALS_IMM $1218, $00
   .endscope

   .scope test12_prep_stage_1                      ; stage 1 active
      lda #0                                       ; prep for line 0
      jsr func_prep_for_active_buffering
      lda #$DD
      sta VERA_DATA0

      ADVANCE_LINE_FOR_ACTIVE_BUFFERING            ; line 1
      lda #$EE
      sta VERA_DATA0

      ADVANCE_LINE_FOR_ACTIVE_BUFFERING            ; line 2
      lda #$FF
      sta VERA_DATA0

      SET_VERA_ADDR24_IMM $00, $0F800, $10         ; expect line 0
      ASSERT_VRAM_U8_EQUALS_IMM $1220, $DD
      ASSERT_VRAM_U8_EQUALS_IMM $1221, $AA
      ASSERT_VRAM_U8_EQUALS_IMM $1222, $00

      SET_VERA_ADDR24_IMM $00, $0F940, $10         ; expect line 1
      ASSERT_VRAM_U8_EQUALS_IMM $1223, $EE
      ASSERT_VRAM_U8_EQUALS_IMM $1224, $CC
      ASSERT_VRAM_U8_EQUALS_IMM $1225, $00

      SET_VERA_ADDR24_IMM $00, $0FA80, $10         ; expect line 2
      ASSERT_VRAM_U8_EQUALS_IMM $1226, $FF
      ASSERT_VRAM_U8_EQUALS_IMM $1227, $BB
      ASSERT_VRAM_U8_EQUALS_IMM $1228, $00

      jsr func_vera_flip_stage                     ; flip active to 0
      ASSERT_VAR_U8_EQUALS_IMM $1229, STAGE_0_ACTIVE, ZP8_activeStage

      SET_VERA_ADDR24_IMM $00, $00000, $10         ; expect line 0
      ASSERT_VRAM_U8_EQUALS_IMM $1220, $DD
      ASSERT_VRAM_U8_EQUALS_IMM $1221, $AA
      ASSERT_VRAM_U8_EQUALS_IMM $1222, $00

      SET_VERA_ADDR24_IMM $00, $00140, $10         ; expect line 1
      ASSERT_VRAM_U8_EQUALS_IMM $1223, $EE
      ASSERT_VRAM_U8_EQUALS_IMM $1224, $CC
      ASSERT_VRAM_U8_EQUALS_IMM $1225, $00

      SET_VERA_ADDR24_IMM $00, $00280, $10         ; expect line 2
      ASSERT_VRAM_U8_EQUALS_IMM $1226, $FF
      ASSERT_VRAM_U8_EQUALS_IMM $1227, $BB
      ASSERT_VRAM_U8_EQUALS_IMM $1228, $00
   .endscope

   PASS

.endproc

; zero out both stages
.proc sub_init_stages: near
   SET_VERA_ADDR24_IMM $00, $00000, $10
   SET_VERA_ADDR24_IMM $01, $0F800, $10
   ldx #198
@row_loop:
   ldy #150
   lda #0
@column_loop:
   sta VERA_DATA0
   sta VERA_DATA0
   sta VERA_DATA1
   sta VERA_DATA1
   dey
   bne @column_loop
   dex
   bne @row_loop
   rts
.endproc
