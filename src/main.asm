.org $080D            ; specify where in memory our code will live

.import func_setup_irq_handler
.import func_restore_irq_handler
.import func_detect_filename
.import func_open_inputstream
.import func_close_inputstream
.import func_load_library
.import func_cache_init
.import func_print_hex
.import func_vera_setup
.import func_vera_restore
.import func_slurp_header
.import func_slurp_frame
.import func_snooze_if_necessary

.segment "INIT"
.segment "STARTUP"
.segment "ONCE"
.segment "CODE"

.include "codec/api.inc"
.include "core/debug.inc"
.include "include/global.inc"
.include "include/kernal.inc"
.include "include/math.inc"
.include "include/petscii.inc"
.include "include/vera.inc"
.include "include/zeropage.inc"

   jmp start

start:

   jsr func_load_library
   jsr func_setup_irq_handler
   jsr func_detect_filename
   jsr func_open_inputstream
   jsr FRAME_DRIVER_FUNC_OPEN

   cmp #0
   beq @open_success
   jmp error
@open_success:
   stx GR8_speedLimitVSyncs    ; FLI max speed limit fits in 8-bits

   DEBUG_TIMER_START

@frame_loop:
   jsr FRAME_DRIVER_FUNC_NEXT
   bcs @frame_loop_done
   jsr func_snooze_if_necessary
   bra @frame_loop

@frame_loop_done:
   cmp #0
   beq @next_success
   jmp error
@next_success:

   DEBUG_TIMER_READ

   jsr func_close_inputstream

.ifndef ENABLE_DEBUG_TIMER
:  jsr KERNAL_GETIN             ; i.e. press any key to continue
   beq :-                       ; (leaving last image still on-screen)
.endif

   jsr FRAME_DRIVER_FUNC_CLOSE
   jsr func_restore_irq_handler

   DEBUG_TIMER_DUMP
   rts

error:
   rts

