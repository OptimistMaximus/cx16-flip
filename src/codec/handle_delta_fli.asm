.export handle_delta_fli

.import func_vera_flip_stage
.import func_prep_for_active_buffering
.import fnc_slurp_into_a

.segment "CODE"

.include "../include/global.inc"
.include "../include/math.inc"
.include "../include/slurp.inc"
.include "../include/video.inc"

.proc handle_delta_fli: near
   jsr func_cache_read_into_a   ; slurp low byte of line skip
   tay                          ; and store it in .Y
   jsr func_cache_read_into_a   ; burn high byte of line skip (always zero)

   jsr func_cache_read_into_a   ; slurp low byte of line count
   tax                          ; and store it in .X
   jsr func_cache_read_into_a   ; burn high byte of line count (always zero)

   phx                          ; squirrel .X for later
      phy                       ; squirrel .Y for later
         phx
            tya
            jsr func_prep_for_active_buffering
         plx
      @line_loop:
         jsr sub_render_line
         dex
         bne @line_loop
      pla                       ; pull .Y into .A so it has the line skip
   plx                          ; pull .X so it has the line count again
   rts
.endproc

.proc sub_render_line: near
   scratchVar = GR8_scratch1

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
