.export handle_delta_fli

.import func_cache_load_page
.import func_cache_read_into_vram
.import vram_addr_table_lo
.import vram_addr_table_me
.import vram_addr_table_hi

.segment "CODE"

.include "./cache.inc"
.include "../include/global.inc"
.include "../include/math.inc"
.include "./video.inc"
.include "./api.inc"

.proc handle_delta_fli: near
   SIP_INTO_U8 ZP8_lineSkip  ; slurp low byte of line skip
   tax                       ; (we need this in .X also)
   SIP_INTO_A                ; burn high byte of line skip (always zero)

   SIP_INTO_U8 ZP8_lineCount ; slurp low byte of line count
   clc
   sta ZP8_lineStop          ; line stop is the count ...
   adc ZP8_lineSkip          ; ... plus the skip
   sta ZP8_lineStop
   SIP_INTO_A                ; burn high byte of line count (always zero)

   @line_loop:
      SET_VRAM_ADDR_FOR_DELTA_LINE  ; uses .X to set the line addr
      phx
         jsr sub_render_line
      plx
      inx
      cpx ZP8_lineStop
      bne @line_loop
   stz ZP8_returnCode
   rts
.endproc

.proc sub_render_line: near
   SIP_INTO_A                       ; packet count
   beq @packet_loop_done            ; (packet count can legit be zero)
   tay                              ; .Y is the packet countdown
@packet_loop:
   SIP_INTO_A                     ; .A holds skip count, where 0 means 0
   beq @zero_skip
   ADVANCE_VERA_ADDR_FOR_DELTA_PACKET
@zero_skip:

   SIP_INTO_A                     ; byte count
   bpl @process_positive_count      ; i.e. bit 7 was clear
      TWOS_COMPLIMENT_A
      SIP_INTO_VRAM_REPEATED
      bra @process_count_done
   @process_positive_count:
      SIP_INTO_VRAM
   @process_count_done:
   dey
   bne @packet_loop
@packet_loop_done:

   rts
.endproc
