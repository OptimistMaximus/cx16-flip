.org $080D            ; specify where in memory our code will live

.import func_setup_irq_handler
.import func_restore_irq_handler
.import func_find_arg
.import func_open_inputstream
.import func_close_inputstream
.import func_append_access_mode
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
   jsr sub_establish_filename
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

;------------------------------------------------------------------------------
; Establish the filename by looking for a custom argument. If no such arg
; was found, then we'll use our default value.  Then, open the file.
;
; @effect .A length of the filename
; @effect .X low byte of filename address
; @effect .Y high byte of filename address
;------------------------------------------------------------------------------
.proc sub_establish_filename: near
   lda #0
   ldx #<RAM_VOLATILE_BUF
   ldy #>RAM_VOLATILE_BUF
   jsr func_find_arg
   bcc @arg_was_cool              ; .C=0 means it was found
   ldx #<default_image_filename
   ldy #>default_image_filename
   rts
@arg_was_cool:
   lda #PETSCII_LOWER_R
   jsr func_append_access_mode
   ldx #<RAM_VOLATILE_BUF
   ldy #>RAM_VOLATILE_BUF
   rts
.endproc
