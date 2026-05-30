.export handle_byte_run

.import func_cache_load_page
.import func_cache_read_into_vram
.import func_cache_dupe_into_vram

.segment "CODE"

.include "../include/global.inc"
.include "../include/slurp.inc"
.include "../include/video.inc"

.proc handle_byte_run: near
   phy
      SET_VRAM_ADDR_FOR_FULL_LINE

      ldx #200                    ; .X is the line countdown
   @line_loop:
      jsr sub_render_line
      dex
      bne @line_loop
   ply
   U8_COPY_IMM ZP8_lineSkip, 0
   U8_COPY_IMM ZP8_lineCount, 200
   rts
.endproc

.proc sub_render_line: near
   SLURP_INTO_A      ; packet count
   tay                             ; .Y is the packet countdown
packet_loop:
   SLURP_INTO_A      ; byte count
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
