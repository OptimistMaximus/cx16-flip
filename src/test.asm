.org $080D            ; specify where in memory our code will live

.import test_suite_0
.import test_suite_1
.import test_suite_2
.import smc_anchor_for_bsod

.segment "STARTUP"    ; declare segments
.segment "INIT"
.segment "ONCE"
.segment "CODE"

.include "./include/opcodes.inc"

.macro RUN_SUITE label
   jsr label
   bcs fail
.endmacro

.macro PRINT petscii
   lda #petscii
   jsr $FFD2
.endmacro

.macro PRINT_NEWLINE
   PRINT $0D
.endmacro

   jmp start

   ;###########################################################################
   ; The test suite subroutines are assumed to increase by complexity and
   ; dependency.  Test Suite 1 should test things that have no dependency on
   ; anything.  Test Suite 2 will test things that depend only on things
   ; already proven to work by virtue of Test Suite 1 passing.  And so on.
   ;
   ; This test file should remain as simple as possible. It has the bare
   ; minimum logic necessary to interpret the Carry bit and .X and .Y values
   ; as set by the assertions in the xuint.inc macros.
   ;###########################################################################

start:

   lda #OPCODE_RTS
   sta smc_anchor_for_bsod ; overwrite JMP with RTS

   RUN_SUITE test_suite_0
   RUN_SUITE test_suite_1
   RUN_SUITE test_suite_2

   jmp pass

pass:
   jsr $FF81
   PRINT_NEWLINE
   PRINT 'p'
   PRINT 'a'
   PRINT 's'
   PRINT 's'
   PRINT_NEWLINE
   PRINT_NEWLINE
   rts

fail:
   phy                   ; push .Y (assertion number)
      phx                ; push .X (test number)
         jsr $FF81
         PRINT_NEWLINE
         PRINT 'f'
         PRINT 'a'
         PRINT 'i'
         PRINT 'l'
         PRINT ' '
      pla                 ; pull test number
      jsr sub_print_hex
      PRINT '-'
   pla
   jsr sub_print_hex     ; pull assertion number
   PRINT_NEWLINE
   PRINT_NEWLINE
   rts

; a simplified print routine based on the assumption that the nibbles
; of test numbers and assertion numbers stay within 0-9
sub_print_hex:
   pha
      lsr
      lsr
      lsr
      lsr
      ora #$30
      jsr $FFD2
   pla
   and #$0F
   ora #$30
   jsr $FFD2
   rts

