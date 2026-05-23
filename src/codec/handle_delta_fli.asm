.export handle_delta_fli

.import func_vera_flip_stage
.import func_prep_for_active_buffering
.import func_snooze_if_necessary

.segment "CODE"

.include "../include/global.inc"
.include "../include/math.inc"
.include "../include/slurp.inc"
.include "../include/video.inc"

.proc handle_delta_fli: near

   tmpLineSkip = ZP_VOLATILE_AB
   tmpLineCount = ZP_VOLATILE_CD
   SLURP_INTO_U16 tmpLineSkip
   SLURP_INTO_U16 tmpLineCount

   lda tmpLineSkip                     ; .A now holds line skip
   jsr func_prep_for_active_buffering

   ldx tmpLineCount                    ; .X now holds the line count
   @line_loop:
   jsr sub_render_line
   dex
   bne @line_loop

   jsr func_vera_flip_stage
   jmp func_snooze_if_necessary
.endproc

.proc sub_render_line: near
   scratchVar = ZP_VOLATILE_A

   jsr func_cache_read_into_a       ; packet count
   cmp #0
   beq @packet_loop_done            ; (packet count can legit be zero)
   tay                              ; .Y is the packet countdown
@packet_loop:
   jsr sub_skip_columns
   jsr func_cache_read_into_a       ; byte count
   bit #%10000000
   beq @process_positive_count   ; i.e. bit 7 was clear

      TWOS_COMPLIMENT_A
      jsr func_cache_dupe_into_vram
      bra @process_count_done

   @process_positive_count:

      jsr func_cache_read_into_vram

   @process_count_done:

   dey
   bne @packet_loop
@packet_loop_done:

   ADVANCE_LINE_FOR_ACTIVE_BUFFERING

   rts
.endproc

.proc sub_skip_columns: near
   jsr func_cache_read_into_a ; (.A holds skip count, where 0 means 0)
   cmp #0
   beq @done
   SKIP_PIXELS
@done:
   rts
.endproc
