.export handle_byte_run

.import func_cache_load_page
.import func_cache_read_into_vram

.segment "CODE"

.include "./cache.inc"
.include "../include/global.inc"
.include "./video.inc"

.proc handle_byte_run: near
   SET_VRAM_ADDR_FOR_FULL_LINE

   lda #200
   sta ZP8_lineIndex          ; acts as line countdown
@line_loop:
   jsr sub_render_line
   dec ZP8_lineIndex
   bne @line_loop
   U8_COPY_IMM ZP8_lineSkip, 0
   U8_COPY_IMM ZP8_lineCount, 200
   rts
.endproc

.proc sub_render_line: near
   SIP_INTO_A      ; packet count
   tay                             ; .Y is the packet countdown
packet_loop:
   SIP_INTO_A      ; byte count
   bpl @process_positive_count  ; i.e. bit 7 was clear
      TWOS_COMPLIMENT_A
      SIP_INTO_VRAM
      bra @process_count_done
   @process_positive_count:
      SIP_INTO_VRAM_REPEATED
   @process_count_done:
   dey
   bne packet_loop
   stz GR8_returnCode
   rts
.endproc
