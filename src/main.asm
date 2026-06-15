.org $080D            ; specify where in memory our code will live

.import func_setup_irq_handler
.import func_restore_irq_handler
.import func_detect_filename
.import func_open_inputstream
.import func_close_inputstream
.import func_cache_init
.import func_print_hex
.import func_vera_setup
.import func_vera_restore
.import func_slurp_header
.import func_slurp_frame
.import func_init_vram_table
.import func_snooze_if_necessary

.segment "INIT"
.segment "STARTUP"
.segment "ONCE"
.segment "CODE"

.include "include/debug.inc"
.include "include/global.inc"
.include "include/kernal.inc"
.include "include/math.inc"
.include "include/petscii.inc"
.include "include/vera.inc"
.include "include/zeropage.inc"

   jmp start

FLIP_DLL_LOAD_ADDR := $7000
video_driver_open  := FLIP_DLL_LOAD_ADDR + 0
video_driver_next  := FLIP_DLL_LOAD_ADDR + 3
video_driver_close := FLIP_DLL_LOAD_ADDR + 6
   
lib_fn: .asciiz "flip080.dll,r"
lib_fn_end:

start:

   jsr sub_load_library
   jsr func_setup_irq_handler
   jsr func_detect_filename
   jsr func_open_inputstream
   jsr video_driver_open
   
   cmp #0
   beq @open_success
   jmp error
@open_success:
   stx GR8_speedLimitVSyncs    ; FLI max speed limit fits in 8-bits
   
   DEBUG_TIMER_START

@frame_loop:
   jsr video_driver_next
   bcs @frame_loop_done
   jsr func_snooze_if_necessary
   bra @frame_loop

@frame_loop_done:
   cmp #0
   beq @next_success
   jmp error
@next_success:
   php
   plp
   bcc @frame_loop              ; .C = 0 means another frame exists

   DEBUG_TIMER_READ

.ifndef ENABLE_DEBUG_TIMER
:  jsr KERNAL_GETIN             ; i.e. press any key to continue
   beq :-                       ; (leaving last image still on-screen)
.endif
   
   jsr video_driver_close
   jsr func_close_inputstream
   jsr func_restore_irq_handler

   DEBUG_TIMER_DUMP
   rts
   
error:
   rts

;==============================================================================
; sub_load_library
;
; This optimistically assumes that there will be no I/O error, such that the
; only reason for READST to return non-zero will be end-of-file.
;==============================================================================
.proc sub_load_library: near
   varLoadAddr = GR16_scratch1
   varReadCount = GR16_scratch2

   lda #(lib_fn_end - lib_fn)
   ldx #<lib_fn
   ldy #>lib_fn
   jsr func_open_inputstream
   U16_COPY_IMM varLoadAddr, FLIP_DLL_LOAD_ADDR   
@load_loop:
   clc
   lda #0
   ldx varLoadAddr+0
   ldy varLoadAddr+1
   jsr KERNAL_MACPTR                       ; read a chunk of bytes into memory
   stx varReadCount+0
   sty varReadCount+1
   U16_ADD_VAR varLoadAddr, varReadCount   ; update the load addr
   jsr KERNAL_READST                       ; keep reading until "error"
   beq @load_loop
   jmp func_close_inputstream
.endproc
