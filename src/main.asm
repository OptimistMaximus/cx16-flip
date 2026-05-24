.org $080D            ; specify where in memory our code will live

.import func_setup_irq_handler
.import func_restore_irq_handler
.import func_detect_filename
.import func_open_inputstream
.import func_close_inputstream
.import func_print_hex
.import func_vera_setup
.import func_vera_restore
.import func_slurp_header
.import func_slurp_frame

.segment "INIT"
.segment "STARTUP"
.segment "ONCE"
.segment "CODE"

.include "include/debug.inc"
.include "include/global.inc"
.include "include/kernal.inc"
.include "include/math.inc"
.include "include/petscii.inc"
.include "include/slurp.inc"
.include "include/vera.inc"
.include "include/zeropage.inc"

   jmp start

default_image_filename: .byte "image.fli,r"

.ifdef DEBUG_TIMER_ENABLED
debug_timer_value: .word $0000
.endif

start:

   jsr func_setup_irq_handler

   DEBUG_TIMER_START
   jsr func_vera_setup
   jsr func_detect_filename
   jsr func_open_inputstream
   jsr func_cache_init
   jsr func_slurp_header

@frame_loop:
   jsr func_slurp_frame
   U16_INC     GR16_frameIndex
   U16_CMP_VAR GR16_frameIndex, GR16_frameCount
   bne @frame_loop

   jsr func_close_inputstream

   DEBUG_TIMER_READ debug_timer_value

:  jsr KERNAL_GETIN             ; i.e. press any key to continue
   beq :-                       ; (leaving last image still on-screen)

   jsr func_vera_restore        ; restore vera to text mode
   jsr func_restore_irq_handler

   DEBUG_TIMER_DUMP debug_timer_value
   rts
