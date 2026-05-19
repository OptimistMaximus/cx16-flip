.export handle_byte_run

.import func_vera_flip_stage
.import func_prep_for_active_buffering
.import func_snooze_if_necessary

.segment "CODE"

.include "../include/global.inc"
.include "../include/slurp.inc"
.include "../include/video.inc"

.proc handle_byte_run: near
   lda #0                             ; full starts at line 0 always
   jsr func_prep_for_active_buffering

   ldx #200                           ; .X is the line countdown
@line_loop:
   jsr sub_render_line
   dex
   bne @line_loop
   jsr func_vera_flip_stage
   jmp func_snooze_if_necessary
.endproc

.proc sub_render_line: near
   SLURP_INTO_A                    ; packet count
   tay                             ; .Y is the packet countdown
@packet_loop:
   SLURP_INTO_A                    ; byte count
   bit #%10000000
   beq @process_positive_count  ; i.e. bit 7 was clear

      TWOS_COMPLIMENT_A
      SLURP_INTO_VRAM

      bra @process_count_done
   @process_positive_count:

      SLURP_INTO_VRAM_REPEATED     ; repeat next byte .A times

   @process_count_done:

   dey
   bne @packet_loop
   rts
.endproc
