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

   ldx #200
   ldy #0
   jsr func_vera_flip_stage
   jmp func_snooze_if_necessary
.endproc

.proc sub_render_line: near
   jsr func_cache_read_into_a      ; packet count
   tay                             ; .Y is the packet countdown
@packet_loop:
   jsr func_cache_read_into_a      ; byte count
   bit #%10000000
   beq @process_positive_count  ; i.e. bit 7 was clear

      TWOS_COMPLIMENT_A
      jsr func_cache_read_into_vram

      bra @process_count_done
   @process_positive_count:

      jsr func_cache_dupe_into_vram ; repeat next byte .A times

   @process_count_done:

   dey
   bne @packet_loop
   rts
.endproc
