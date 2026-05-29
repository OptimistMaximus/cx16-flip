.export test_suite_2

.import func_detect_filename
.import func_open_inputstream
.import func_close_inputstream
.import func_slurp_header
.import func_slurp_chunk
.import func_slurp_frame
.import handle_invalid
.import handle_color_256
.import handle_color_64
.import handle_delta_fli
.import handle_black
.import handle_byte_run
.import handle_fli_copy
.import func_load_palette
.import sub_resolve_chunk_type
.import sub_resolve_frame_type

.include "../include/global.inc"
.include "../include/math.inc"
.include "../include/math2.inc"
.include "../include/slurp.inc"
.include "../include/vera.inc"
.include "../include/video.inc"
.include "../include/xunit.inc"

.segment "RODATA"     ; Read-Only data

fn_header_x: .asciiz "headerx.bin,r"
fn_chunk_x:  .asciiz "chunkx.bin,r"
fn_color_x:  .asciiz "colorx.bin,r"
fn_byterun:  .asciiz "byterun.bin,r"
fn_deltafli: .asciiz "deltafli.bin,r"

.segment "CODE"

VRAM_IMAGE_LINE_0  := $00000
VRAM_IMAGE_LINE_1  := $00140
VRAM_IMAGE_LINE_2  := $00280
VRAM_IMAGE_LINE_3  := $003C0

.macro OPEN_INPUTSTREAM_R filenameLabel, replacementOffset, replacementChar
   U8_COPY_IMM filenameLabel+replacementOffset, replacementChar
   ldx #<filenameLabel
   ldy #>filenameLabel
   jsr sub_strlen
   jsr func_open_inputstream
   jsr func_cache_init
.endmacro

.macro CLOSE_INPUTSTREAM
   pha                                  ; preserve .A .X .Y since we
      phx                               ; often call this after calling
         phy                            ; a subroutine that was reading
            jsr func_close_inputstream  ; a file, and we need to close
         ply                            ; the stream before asserting the
      plx                               ; subroutine's side-effects
   pla
.endmacro

.proc test_suite_2: near

   ;---------------------------------------------------------------------------
   ; TEST 30 - slurp_header
   ;---------------------------------------------------------------------------
   OPEN_INPUTSTREAM_R fn_header_x, 6, '0'
   jsr func_slurp_header
   CLOSE_INPUTSTREAM
   ASSERT_VAR_U8_EQUALS_IMM $3001, $48, GR8_speedLimitVSyncs ; $55 * 6 / 7 = $48

   OPEN_INPUTSTREAM_R fn_header_x, 6, '1'
   jsr func_slurp_header
   CLOSE_INPUTSTREAM
   ASSERT_VAR_U8_EQUALS_IMM $3011, RC_UNSUPPORTED_FILE_TYPE, GR8_returnCode
   ASSERT_VAR_U16_EQUALS_IMM $3012, $AF12, GR16_returnDetail

   OPEN_INPUTSTREAM_R fn_header_x, 6, '2'
   jsr func_slurp_header
   CLOSE_INPUTSTREAM
   ASSERT_VAR_U8_EQUALS_IMM $3021, $FE, GR8_speedLimitVSyncs

   ;---------------------------------------------------------------------------
   ; TEST 31 - handle_invalid
   ;---------------------------------------------------------------------------
   U16_COPY_IMM GR16_chunkType, $DEAD
   jsr handle_invalid
   ASSERT_VAR_U8_EQUALS_IMM $3100, RC_INVALID_CHUNK_TYPE, GR8_returnCode
   ASSERT_VAR_U16_EQUALS_IMM $3101, $DEAD, GR16_returnDetail

   ;---------------------------------------------------------------------------
   ; TEST 32 - handle_black
   ;
   ; Test this early so we can use it in subsequent tests to establish VRAM
   ; to a known state. When used in conjunction with func_vera_flip_stage
   ; (also already tested in test1.asm) we can initialize both areas of VRAM
   ; to all zeros.
   ;---------------------------------------------------------------------------
   VPOKE $00000, $AA
   VPOKE $0F9FF, $BB
   VPOKE $0FA00, $CC
   VPOKE $1F3FF, $DD
   VPOKE $1F400, $EE
   jsr handle_black
   ASSERT_A_EQUALS_IMM     $3200, 0           ; line skip
   ASSERT_X_EQUALS_IMM     $3201, 200         ; line skip
   ASSERT_VPEEK_EQUALS_IMM $3200, $AA, $00000 ; untouched
   ASSERT_VPEEK_EQUALS_IMM $3200, $BB, $0F9FF ; untouched
   ASSERT_VPEEK_EQUALS_IMM $3201, $00, $0FA00 ; via black
   ASSERT_VPEEK_EQUALS_IMM $3203, $00, $1F3FF ; via black
   ASSERT_VPEEK_EQUALS_IMM $3204, $EE, $1F400 ; untouched

   ;---------------------------------------------------------------------------
   ; TEST 33 - sub_resolve_chunk_type
   ;           sub_resolve_frame_type
   ;
   ; Note that this implementation doesn't handle padding, so we should expect
   ; what is resolved on the first pass.
   ;
   ; The test expectations are based on white-box knowledge of the handler
   ; jump table, where offset $0E is for "BLACK" and $02 is for "FRAME_TYPE"
   ;---------------------------------------------------------------------------
   .macro T33 lambda, filenumPetscii, testId, expect
      OPEN_INPUTSTREAM_R fn_chunk_x, 5, filenumPetscii
      SLURP_INTO_U32 GR32_chunkSize
      SLURP_INTO_U16 GR16_chunkType
      jsr lambda
      CLOSE_INPUTSTREAM
      ASSERT_X_EQUALS_IMM testId, expect
   .endmacro

   T33 sub_resolve_chunk_type, '0', $3300, $0E  ; no padding
   T33 sub_resolve_chunk_type, '1', $3301, $00  ; one byte of padding
   T33 sub_resolve_chunk_type, '3', $3303, $00  ; invalid chunk

   T33 sub_resolve_frame_type, '4', $3314, $02  ; no padding
   T33 sub_resolve_frame_type, '5', $3315, $00  ; no padding, invalid low byte
   T33 sub_resolve_frame_type, '6', $3316, $00  ; no padding, invalid high byte

   ;---------------------------------------------------------------------------
   ; TEST 34 - func_slurp_chunk
   ;
   ; Now that handle_black and sub_resolve_chunk_type are confirmed to work,
   ; this test can focus on looking for evidence that padding is handled
   ; correctly. This will re-use the chunk files 0 and 1, because they have
   ; chunk type BLACK type with varying amounts of padding.
   ;
   ; Since handle_black is already confirmed to work, we don't need to verify
   ; the whole vram buffer; we can just verify $FA00 turns to zero.
   ;---------------------------------------------------------------------------
   .macro T34 filenumPetscii, testId
      VPOKE $0FA00, $55
      OPEN_INPUTSTREAM_R fn_chunk_x, 5, filenumPetscii
      jsr func_slurp_chunk
      CLOSE_INPUTSTREAM
      ASSERT_VPEEK_EQUALS_IMM testId, $00, $0FA00
   .endmacro

   T34 '0', $3400 ; no padding
   T34 '1', $3401 ; one byte of padding

   ;---------------------------------------------------------------------------
   ; TEST 35 - func_load_palette
   ;---------------------------------------------------------------------------
   jsr sub_init_palette_buffer
   jsr func_load_palette
   SET_VERA_ADDR24_IMM $00, $1FA00, $10
   ASSERT_VRAM_U16_EQUALS_IMM $3500, $0000
   ASSERT_VRAM_U16_EQUALS_IMM $3501, $0101
   ASSERT_VRAM_U16_EQUALS_IMM $3502, $0202
   SET_VERA_ADDR24_IMM $00, $1FB00, $10
   ASSERT_VRAM_U16_EQUALS_IMM $3503, $8080
   ASSERT_VRAM_U16_EQUALS_IMM $3504, $8181
   ASSERT_VRAM_U16_EQUALS_IMM $3505, $8282
   SET_VERA_ADDR24_IMM $00, $1FBFA, $10
   ASSERT_VRAM_U16_EQUALS_IMM $3506, $FDFD
   ASSERT_VRAM_U16_EQUALS_IMM $3507, $FEFE
   ASSERT_VRAM_U16_EQUALS_IMM $3508, $FFFF

   ;---------------------------------------------------------------------------
   ; TEST 36 - handle_color_64
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
   jsr sub_init_palette_buffer
   jsr handle_color_64
   CLOSE_INPUTSTREAM
   
   ASSERT_A_EQUALS_IMM $3600, 0
   ASSERT_X_EQUALS_IMM $3600, 0
   SET_VERA_ADDR24_IMM $00, $1F400, $10
   ASSERT_VRAM_U16_EQUALS_IMM $3601, $0000 ; color 0 skip
   ASSERT_VRAM_U16_EQUALS_IMM $3602, $0101 ; color 1 skip
   ASSERT_VRAM_U16_EQUALS_IMM $3603, $0EA7 ; color 2
   ASSERT_VRAM_U16_EQUALS_IMM $3604, $0303 ; color 3 skip
   ASSERT_VRAM_U16_EQUALS_IMM $3605, $0666 ; color 4
   ASSERT_VRAM_U16_EQUALS_IMM $3606, $0BBB ; color 5
   ASSERT_VRAM_U16_EQUALS_IMM $3607, $0606 ; color 6 untouched

   OPEN_INPUTSTREAM_R fn_color_x, 5, '0'
   jsr sub_init_palette_buffer
   jsr handle_color_256
   CLOSE_INPUTSTREAM

   ASSERT_A_EQUALS_IMM $3610, 0
   ASSERT_X_EQUALS_IMM $3610, 0
   SET_VERA_ADDR24_IMM $00, $1F400, $10
   ASSERT_VRAM_U16_EQUALS_IMM $3611, $0000 ; color 0 skip
   ASSERT_VRAM_U16_EQUALS_IMM $3612, $0101 ; color 1 skip
   ASSERT_VRAM_U16_EQUALS_IMM $3613, $0321 ; color 2
   ASSERT_VRAM_U16_EQUALS_IMM $3614, $0303 ; color 3 skip
   ASSERT_VRAM_U16_EQUALS_IMM $3615, $0111 ; color 4
   ASSERT_VRAM_U16_EQUALS_IMM $3616, $0222 ; color 5
   ASSERT_VRAM_U16_EQUALS_IMM $3617, $0606 ; color 6 untouched

   OPEN_INPUTSTREAM_R fn_color_x, 5, '1'
   jsr sub_init_palette_buffer
   jsr handle_color_256

   CLOSE_INPUTSTREAM
   SET_VERA_ADDR24_IMM $00, $1F400, $10
   ldy #0
@test36_copy_packet_count_loop:
   ASSERT_VRAM_U16_EQUALS_IMM $3621, $0111  ; color 0,2,4,etc
   ASSERT_VRAM_U16_EQUALS_IMM $3622, $0222  ; color 1,3,5,etc
   iny
   cpy #128
   bne @test36_copy_packet_count_loop

   OPEN_INPUTSTREAM_R fn_color_x, 5, '2'
   jsr sub_init_palette_buffer
   jsr handle_color_256
   CLOSE_INPUTSTREAM
   SET_VERA_ADDR24_IMM $00, $1F400, $10
   ldy #0
@test36_verify_packet_count_loop:
   ASSERT_VRAM_U16_EQUALS_IMM $3631, $0111  ; color 0,2,4,etc
   ASSERT_VRAM_U16_EQUALS_IMM $3632, $0222  ; color 1,3,5,etc
   iny
   cpy #128
   bne @test36_verify_packet_count_loop

   ;---------------------------------------------------------------------------
   ; TEST 37 - handle_byte_run
   ;
   ; This test zeros out the first 6 bytes of both the stage 0 and stage 1
   ; bitmaps, then establishes stage 0 as active (so we expect updates to
   ; happen to stage 1).
   ;
   ; The simulated data represents a height 1 image, so establish height 1
   ; before processing the input stream.
   ;
   ; Expect Stage 0 to be untouched, Stage 1 to have the byte run, and the
   ; stage switched from 0 to 1.
   ;---------------------------------------------------------------------------
   jsr handle_black
   OPEN_INPUTSTREAM_R fn_byterun, 0, 'b'
   jsr handle_byte_run
   CLOSE_INPUTSTREAM
   ASSERT_A_EQUALS_IMM $3700, 0
   ASSERT_X_EQUALS_IMM $3701, 200
   
   SET_VERA_ADDR24_IMM $00, $0FA00, $10
   ASSERT_VRAM_U8_EQUALS_IMM $3710, $00 ; packet 0 start (line 0)
   SET_VERA_ADDR24_IMM $00, $0FA7E, $10
   ASSERT_VRAM_U8_EQUALS_IMM $3711, $00 ; packet 0 end
   ASSERT_VRAM_U8_EQUALS_IMM $3712, $01 ; packet 1 start
   ASSERT_VRAM_U8_EQUALS_IMM $3713, $02
   ASSERT_VRAM_U8_EQUALS_IMM $3714, $03
   ASSERT_VRAM_U8_EQUALS_IMM $3715, $04
   ASSERT_VRAM_U8_EQUALS_IMM $3716, $05 ; packet 1 end
   ASSERT_VRAM_U8_EQUALS_IMM $3717, $06 ; packet 2 start
   SET_VERA_ADDR24_IMM $00, $0FAF3, $10
   ASSERT_VRAM_U8_EQUALS_IMM $3718, $06 ; packet 2 end
   ASSERT_VRAM_U8_EQUALS_IMM $3719, $07 ; packet 3 start
   SET_VERA_ADDR24_IMM $00, $0FB3F, $10
   ASSERT_VRAM_U8_EQUALS_IMM $3720, $07 ; packet 3 end
   ASSERT_VRAM_U8_EQUALS_IMM $3721, $01 ; packet 4 start (line 1)

   ;---------------------------------------------------------------------------
   ; TEST 38 - handle_delta_fli
   ;
   ; The test data establishes the initial line number as line 4, with line
   ; count 2.
   ;
   ; line 0 -> 0000 + F800 = 0F800
   ; line 1 -> 0140 + F800 = 0F940
   ; line 2 -> 0280 + F800 = 0FA80
   ; line 3 -> 03C0 + F800 = 0FBC0
   ; line 4 -> 0500 + F800 = 0FD00   <--- enter delta
   ; line 5 -> 0640 + F800 = 0FE40   <--- leave delta
   ;---------------------------------------------------------------------------
   jsr handle_black

   OPEN_INPUTSTREAM_R fn_deltafli, 0, 'd'
   jsr handle_delta_fli
   CLOSE_INPUTSTREAM

   ASSERT_A_EQUALS_IMM $3800, 4 ; line skip
   ASSERT_X_EQUALS_IMM $3801, 2 ; line count

   SET_VERA_ADDR24_IMM $00, $0FDC0, $10 ; line 4
   ASSERT_VRAM_U8_EQUALS_IMM $3810, $00 ; pixel 0
   ASSERT_VRAM_U8_EQUALS_IMM $3811, $00 ; pixel 1
   ASSERT_VRAM_U8_EQUALS_IMM $3812, $00 ; pixel 2

   SET_VERA_ADDR24_IMM $00, $0FF00, $10 ; line 5
   ASSERT_VRAM_U8_EQUALS_IMM $3813, $00 ; pixel 0 (skipped)
   ASSERT_VRAM_U8_EQUALS_IMM $3814, $00 ; pixel 1 (skipped)
   ASSERT_VRAM_U8_EQUALS_IMM $3815, $00 ; pixel 2 (skipped)
   ASSERT_VRAM_U8_EQUALS_IMM $3816, $00 ; pixel 3 (skipped)
   ASSERT_VRAM_U8_EQUALS_IMM $3817, $AA ; pixel 4
   ASSERT_VRAM_U8_EQUALS_IMM $3818, $AA ; pixel 5
   ASSERT_VRAM_U8_EQUALS_IMM $3819, $AA ; pixel 6
   ASSERT_VRAM_U8_EQUALS_IMM $3820, $00 ; pixel 7 (skipped)
   ASSERT_VRAM_U8_EQUALS_IMM $3821, $BB ; pixel 8
   ASSERT_VRAM_U8_EQUALS_IMM $3822, $CC ; pixel 9
   ASSERT_VRAM_U8_EQUALS_IMM $3823, $DD ; pixel 10
   ASSERT_VRAM_U8_EQUALS_IMM $3824, $00 ; pixel 11 (skipped)
   ASSERT_VRAM_U8_EQUALS_IMM $3825, $EE ; pixel 12
   ASSERT_VRAM_U8_EQUALS_IMM $3826, $EE ; pixel 13
   ASSERT_VRAM_U8_EQUALS_IMM $3827, $00 ; pixel 14 (untouched)

   SET_VERA_ADDR24_IMM $00, $10040, $10 ; line 6
   ASSERT_VRAM_U8_EQUALS_IMM $3830, $55 ; pixel 0
   ASSERT_VRAM_U8_EQUALS_IMM $3831, $55 ; pixel 1
   ASSERT_VRAM_U8_EQUALS_IMM $3832, $55 ; pixel 2

   SET_VERA_ADDR24_IMM $00, $10180, $10 ; line 7
   ASSERT_VRAM_U8_EQUALS_IMM $3840, $00 ; pixel 0
   ASSERT_VRAM_U8_EQUALS_IMM $3841, $00 ; pixel 1
   ASSERT_VRAM_U8_EQUALS_IMM $3842, $00 ; pixel 2

   ;---------------------------------------------------------------------------
   ; TEST 39 - handle_fli_copy
   ;---------------------------------------------------------------------------




   PASS
.endproc



.proc sub_strlen: near
   stx ZP_VOLATILE_PTR+0
   sty ZP_VOLATILE_PTR+1
   phy
      ldy #0
@loop:
      lda (ZP_VOLATILE_PTR),y
      beq @loop_done
      iny
      bra @loop
@loop_done:
      tya
   ply
   rts
.endproc

.proc sub_init_palette_buffer: near
   SET_VERA_ADDR24_IMM $00, $1F400, $10
   ldy #0
@loop:
   sty VERA_DATA0
   sty VERA_DATA0
   iny
   bne @loop
   rts
.endproc
