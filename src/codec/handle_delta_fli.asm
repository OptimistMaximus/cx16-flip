.export handle_delta_fli

.import func_cache_load_page
.import func_cache_read_into_vram
.import func_cache_dupe_into_vram

.segment "CODE"

.include "../include/global.inc"
.include "../include/math.inc"
.include "../include/slurp.inc"
.include "../include/video.inc"

.proc handle_delta_fli: near
   SLURP_INTO_A   ; slurp low byte of line skip
   sta ZP8_lineSkip
   tax                ; (we need this in .X also)
   SLURP_INTO_A   ; burn high byte of line skip (always zero)

   SLURP_INTO_A   ; slurp low byte of line count
   sta ZP8_lineCount

   clc
   sta ZP8_lineStop  ; line stop is the count ...
   adc ZP8_lineSkip  ; ... plus the skip
   sta ZP8_lineStop

   SLURP_INTO_A   ; burn high byte of line count (always zero)

   @line_loop:
      SET_VRAM_ADDR_FOR_DELTA_LINE  ; uses .X to set the line addr
      phx
         jsr sub_render_line
      plx
      inx
      cpx ZP8_lineStop
      bne @line_loop
   rts
.endproc

.proc sub_render_line: near
   SLURP_INTO_A       ; packet count
   cmp #0
   beq @packet_loop_done            ; (packet count can legit be zero)
   tay                              ; .Y is the packet countdown
@packet_loop:

   SLURP_INTO_A                     ; .A holds skip count, where 0 means 0
   cmp #0
   beq @zero_skip
   ADVANCE_VERA_ADDR_FOR_DELTA_PACKET
@zero_skip:

   SLURP_INTO_A                     ; byte count
   bit #%10000000
   beq @process_positive_count      ; i.e. bit 7 was clear

      TWOS_COMPLIMENT_A
      jsr func_cache_dupe_into_vram
      bra @process_count_done

   @process_positive_count:

      jsr func_cache_read_into_vram

   @process_count_done:

   dey
   bne @packet_loop
@packet_loop_done:

   rts
.endproc
