.export test_suite_0

.import func_snooze
.import func_snooze_if_necessary
.import func_detect_filename
.import func_setup_irq_handler
.import func_restore_irq_handler
.import func_print_hex

.segment "RODATA"

test_bb_no_args:  .byte $8A,$00   ; "RUN"
test_bb_spaces:   .byte $8A,$20,$3A,$20,$8F,$20,$20,$41,$41,$20,$20,$00
test_bb_two_args: .byte $8A,$3A,$8F,$20,$41,$41,$20,$42,$42,$20,$00
test_bb_cheeky:   ; i.e. someone's trying a buffer overrun attack
.byte $8A,$3A,$8F,$20,$20,$20,$20,$20,$20,$20
.byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20
.byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20
.byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20
.byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20
.byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20
.byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20
.byte $20,$20,$20,$20,$20,$20,$20,$43,$43,$00

test_bb_expect_found: .asciiz "aa,r"
test_bb_expect_default: .asciiz "image.fli,r"

.segment "CODE"

.include "../include/global.inc"
.include "../include/math.inc"
.include "../include/petscii.inc"
.include "../include/xunit.inc"
.include "../include/zeropage.inc"

.include "../include/vera.inc"

.macro PRINT petscii
   lda #petscii
   jsr KERNAL_CHROUT
.endmacro

;##############################################################################
; Although all the things tested in this test have no dependencies, some of
; them are so fundamental that they are useful to use when writing other tests.
; Hence, they are tested here in a very carefully chosen order.
;
; It is critical that a test never uses production code until AFTER it that
; production code has itself been tested. Every test suite hereafter should
; ideally only depend on things tested in an earlier suite.
;##############################################################################
.proc test_suite_0: near

   ;---------------------------------------------------------------------------
   ; TEST 00 (simple macros that everything else depends upon)
   ;
   ; U16_STZ
   ; U24_STZ
   ;---------------------------------------------------------------------------
   lda #$55
   sta GR16_scratch1+0
   sta GR16_scratch1+1
   U16_STZ GR16_scratch1
   ASSERT_VAR_U16_EQUALS_IMM $0000, $0000, GR16_scratch1

   lda #$55
   sta GR24_scratch1+0
   sta GR24_scratch1+1
   sta GR24_scratch1+2
   U24_STZ GR24_scratch1
   ASSERT_VAR_U24_EQUALS_IMM $0001, $000000, GR24_scratch1

   ;---------------------------------------------------------------------------
   ; TEST 00 (simple macros that everything else depends upon)
   ;
   ; U8_COPY_IMM
   ; U16_COPY_IMM
   ; U24_COPY_IMM
   ;---------------------------------------------------------------------------
   stz GR8_scratch1
   U8_COPY_IMM GR8_scratch1, $AA
   ASSERT_VAR_U8_EQUALS_IMM $0010, $AA, GR8_scratch1

   U16_STZ GR16_scratch1
   U16_COPY_IMM GR16_scratch1, $AABB
   ASSERT_VAR_U16_EQUALS_IMM $0011, $AABB, GR16_scratch1

   U24_STZ GR24_scratch1
   U24_COPY_IMM GR24_scratch1, $AABBCC
   ASSERT_VAR_U24_EQUALS_IMM $0012, $AABBCC, GR24_scratch1

   ;---------------------------------------------------------------------------
   ; TEST 00 (simple macros that everything else depends upon)
   ;
   ; U8_COPY_VAR
   ; U16_COPY_VAR
   ; U24_COPY_VAR
   ;---------------------------------------------------------------------------
   stz         GR8_scratch1
   U8_COPY_IMM GR8_scratch2, $AA
   U8_COPY_VAR GR8_scratch1, GR8_scratch2
   ASSERT_VAR_U8_EQUALS_IMM $0020, $AA, GR8_scratch1

   U16_STZ      GR16_scratch1
   U16_COPY_IMM GR16_scratch2, $AABB
   U16_COPY_VAR GR16_scratch1, GR16_scratch2
   ASSERT_VAR_U16_EQUALS_IMM $0021, $AABB, GR16_scratch1

   U24_STZ      GR24_scratch1
   U24_COPY_IMM GR24_scratch2, $AABB
   U24_COPY_VAR GR24_scratch1, GR24_scratch2
   ASSERT_VAR_U24_EQUALS_IMM $0022, $AABB, GR24_scratch1

   ;---------------------------------------------------------------------------
   ; TEST 01 (add, subtract)
   ;
   ; U16_ADD_A
   ;                  U24_ADD_IMM
   ; U16_ADD_VAR
   ; U16_SUB_VAR
   ;---------------------------------------------------------------------------
   U16_COPY_IMM GR16_scratch1, $00FE
   U16_COPY_IMM GR16_scratch2, $0004

   lda #3
   U16_ADD_A GR16_scratch1
   ASSERT_VAR_U16_EQUALS_IMM $0100, $0101, GR16_scratch1

   U16_SUB_VAR GR16_scratch1, GR16_scratch2
   ASSERT_VAR_U16_EQUALS_IMM $0101, $00FD, GR16_scratch1

   U16_ADD_VAR GR16_scratch1, GR16_scratch2
   ASSERT_VAR_U16_EQUALS_IMM $0102, $0101, GR16_scratch1

   U24_COPY_IMM GR24_scratch1, $00EEEE
   U24_ADD_IMM  GR24_scratch1, $222222
   ASSERT_VAR_U24_EQUALS_IMM $0110, $231110, GR24_scratch1


   ;---------------------------------------------------------------------------
   ; TEST 02 (inc)
   ;
   ; U16_INC
   ;---------------------------------------------------------------------------
   U16_COPY_IMM GR16_scratch1, $00FE
   U16_INC      GR16_scratch1
   ASSERT_VAR_U16_EQUALS_IMM $0106, $00FF, GR16_scratch1

   U16_INC      GR16_scratch1
   ASSERT_VAR_U16_EQUALS_IMM $0107, $0100, GR16_scratch1

   ;---------------------------------------------------------------------------
   ; TEST 03 (cmp)
   ;
   ; U16_CMP_IMM    U16_CMP_VAR
   ;---------------------------------------------------------------------------
   U16_COPY_IMM GR16_scratch1, $5555

   U16_CMP_IMM  GR16_scratch1, $5555
   ASSERT_BCS $0300 ; >=
   ASSERT_BEQ $0301 ; ==

   U16_CMP_IMM  GR16_scratch1, $4466
   ASSERT_BCS $0302 ; >=
   ASSERT_BNE $0303 ; !=

   U16_CMP_IMM  GR16_scratch1, $6644
   ASSERT_BCC $0304 ; <

   U16_COPY_IMM GR16_scratch2, $5555
   U16_CMP_VAR  GR16_scratch1, GR16_scratch2
   ASSERT_BCS $0310 ; >=
   ASSERT_BEQ $0311 ; ==

   U16_COPY_IMM GR16_scratch2, $4466
   U16_CMP_VAR  GR16_scratch1, GR16_scratch2
   ASSERT_BCS $0312 ; >=
   ASSERT_BNE $0313 ; !=

   U16_COPY_IMM GR16_scratch2, $6644
   U16_CMP_VAR  GR16_scratch1, GR16_scratch2
   ASSERT_BCC $0314 ; <

   ;---------------------------------------------------------------------------
   ; TEST 04 (misc)
   ;
   ; TWOS_COMPLIMENT_A
   ;---------------------------------------------------------------------------
   lda #2
   TWOS_COMPLIMENT_A
   ASSERT_A_EQUALS_IMM $0400, $FE

   TWOS_COMPLIMENT_A
   ASSERT_A_EQUALS_IMM $0401, $02






   ;---------------------------------------------------------------------------
   ; TEST 9 - func_detect_filename
   ;
   ; White box testing: We know func_find_arg parses the BASIC buffer.  We know
   ; the BASIC buffer is located at $200 to $281, including the NULL terminator.
   ; We know the buffer holds tokenized BASIC, left and right trimmed.
   ;---------------------------------------------------------------------------
   .macro PREP_BASIC_BUFFER sourceLabel
      ldy #$FF
   :  iny
      lda sourceLabel,y
      sta $200,y
      bne :-
   .endmacro

   .macro DETECT_FILENAME testId, expectSize, expectText
      jsr func_detect_filename
      stx ZP_VOLATILE_PTR+0
      sty ZP_VOLATILE_PTR+1
      ASSERT_A_EQUALS_IMM testId, expectSize
      ASSERT_RAM_EQUALS_ARRAY_INDIRECT (testId+1), (expectSize-1), expectText, ZP_VOLATILE_PTR
   .endmacro

   PREP_BASIC_BUFFER test_bb_no_args
   DETECT_FILENAME $0900, 11, test_bb_expect_default

   PREP_BASIC_BUFFER test_bb_spaces
   DETECT_FILENAME $0910, 4, test_bb_expect_found

   PREP_BASIC_BUFFER test_bb_cheeky
   DETECT_FILENAME $0920, 11, test_bb_expect_default

   PREP_BASIC_BUFFER test_bb_two_args
   DETECT_FILENAME $0930, 4, test_bb_expect_found

   ;---------------------------------------------------------------------------
   ; TEST 99 (timer)
   ;
   ; We can't really assert anything for these tests, but we can view the
   ; behavior at runtime.  The following code should cause a period to be
   ; printed on screen every 1 second for 3 seconds (unconditional snooze)
   ; and then after 2 more seconds, an exlamation point due to a contrived
   ; 2 second elapsed at speed 3 (3-2=1), then an immediate exclamation point
   ; due to a contrived 4 seconds elapsed at speed 3 (3-4=-1).
   ;
   ; When testing by visual cue, set timeout to 60 for 1 second granularity.
   ; To not waste time when we're confident timing works, set it to 10.
   ;---------------------------------------------------------------------------
   snoozeUnits = 10

   jsr func_setup_irq_handler
   PRINT PETSCII_LOWER_T
   PRINT PETSCII_PERIOD
   lda #snoozeUnits
   jsr func_snooze
   PRINT PETSCII_PERIOD
   lda #snoozeUnits
   jsr func_snooze
   PRINT PETSCII_PERIOD
   lda #snoozeUnits
   jsr func_snooze
   PRINT PETSCII_PERIOD

   U8_COPY_IMM GR8_speedLimitVSyncs, (snoozeUnits*3)
   U8_COPY_IMM ZP8_imageVSyncsElapsed, (snoozeUnits*2)
   jsr func_snooze_if_necessary
   PRINT PETSCII_EXCLAMATION

   U8_COPY_IMM ZP8_imageVSyncsElapsed, (snoozeUnits*4)
   jsr func_snooze_if_necessary
   PRINT PETSCII_EXCLAMATION

   lda #snoozeUnits    ; linger 1 extra second, just so a human watching
   jsr func_snooze     ; the test can see the !! before it disappears.

   jsr func_restore_irq_handler

   PASS
.endproc

