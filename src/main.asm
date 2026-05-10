.org $080D            ; specify where in memory our code will live

.import func_setup_irq_handler
.import func_restore_irq_handler
.import func_find_arg
.import func_open_inputstream
.import func_close_inputstream
.import func_append_access_mode
.import func_slurp_into_a
.import func_print_hex
.import func_vera_setup
.import func_vera_restore
.import func_register_sprites
.import func_slurp_header
.import func_slurp_chunk

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

default_image_filename: .byte "image.fli,r"

.ifdef DEBUG_TIMER_ENABLED
debug_timer_value: .word $0000
.endif

;------------------------------------------------------------------------------
; PRINT
;------------------------------------------------------------------------------
.macro PRINT petscii
   lda #petscii
   jsr KERNAL_CHROUT
.endmacro

;------------------------------------------------------------------------------
; RTS_BSOD (BASIC Screen of Death)
;
; Call this to return to BASIC, assuming .A .X and .Y were already set with
; the return status and detail.  This restores VERA  back to default
; and prints the return status and detail as text.
;------------------------------------------------------------------------------
.macro RTS_BSOD
   phy
      phx
         pha
            jsr func_vera_restore
            PRINT PETSCII_RETURN
            PRINT PETSCII_LOWER_E
            PRINT PETSCII_LOWER_R
            PRINT PETSCII_LOWER_R
            PRINT PETSCII_LOWER_O
            PRINT PETSCII_LOWER_R
            PRINT PETSCII_SPACE
         pla
         jsr func_print_hex
         PRINT PETSCII_SPACE
         PRINT PETSCII_OPEN_SQUARE
      plx
      txa
      jsr func_print_hex
   ply
   tya
   jsr func_print_hex
   PRINT PETSCII_CLOSE_SQUARE
   PRINT PETSCII_RETURN
   PRINT PETSCII_RETURN
   jsr func_restore_irq_handler
   rts
.endmacro

start:

   jsr func_setup_irq_handler

   DEBUG_TIMER_START
   jsr func_register_sprites
   jsr func_vera_setup

   jsr sub_establish_filename
   jsr func_open_inputstream
   beq @inputstream_is_cool
   RTS_BSOD
@inputstream_is_cool:

   jsr func_slurp_header
   beq @header_is_cool
   RTS_BSOD
@header_is_cool:

   U16_STZ ZP16_currFrame
@frame_loop:
   jsr func_slurp_chunk
   beq @chunk_is_cool
   RTS_BSOD
@chunk_is_cool:

   lda ZP8_slurpTracker
   bit #%00000001              ; should have added a padding byte, so we need
   beq @padding_mitigated      ; to burn it before proceeding to the next chunk
   jsr func_slurp_into_a
@padding_mitigated:

   U16_INC ZP16_currFrame
   U16_CMP_VAR ZP16_currFrame, ZP16_numFrames
   bne @frame_loop

   jsr func_close_inputstream

   DEBUG_TIMER_READ debug_timer_value

:  jsr KERNAL_GETIN             ; i.e. press any key to continue
   beq :-                       ; (leaving last image still on-screen)

   jsr func_vera_restore        ; restore vera to text mode
   jsr func_restore_irq_handler
   DEBUG_TIMER_DUMP debug_timer_value
   RTS_NO_DETAIL RC_SUCCESS

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
