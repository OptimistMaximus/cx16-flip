.export handle_byte_run

.import func_prep_for_active_buffering

.segment "CODE"

.include "../include/narf.inc"
.include "../include/global.inc"
.include "../include/slurp.inc"
.include "../include/video.inc"

.proc handle_byte_run: near
   phy
      lda #0                             ; full starts at line 0 always
      jsr func_prep_for_active_buffering
      ldx #200                           ; .X is the line countdown
   @line_loop:
      jsr sub_render_line
      dex
      bne @line_loop
   ply
   lda #0    ; return value line skip
   ldx #200  ; return value line count
   rts
.endproc

.proc sub_render_line: near
   NARF_READ_INTO_A      ; packet count
   tay                             ; .Y is the packet countdown
packet_loop:
   NARF_READ_INTO_A      ; byte count
   bit #%10000000
   beq @process_positive_count  ; i.e. bit 7 was clear

      TWOS_COMPLIMENT_A
      jsr func_cache_read_into_vram

      bra @process_count_done
   @process_positive_count:

      jsr func_cache_dupe_into_vram ; repeat next byte .A times

   @process_count_done:

   dey
   bne packet_loop
   rts
.endproc
