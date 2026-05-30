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

   ldx ZP8_lineSkip
   @line_loop:
      SET_VRAM_ADDR_FOR_DELTA_LINE
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
   jsr sub_skip_columns
   SLURP_INTO_A       ; byte count
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

   rts
.endproc

;==============================================================================
; sub_skip_columns
;
; Every delta packet starts with a column skip. We achieve this by advancing
; the active VRAM address either by doing an LDA loop (to gain the side-effect
; of VERA's auto-increment feature, which we assume to be 1 when rendering
; FLI deltas) or by setting a whole new VERA address.
;
; The cost of setting a new VERA address is 37 cycles. The cost of looping
; over LDA is 2 cycles plus 9 per loop.  So, if the skip value is less than
; 4 it is cheaper to do a crude loop (a loop of 4 being 38 cycles).
;==============================================================================
.proc sub_skip_columns: near
   SLURP_INTO_A ; (.A holds skip count, where 0 means 0)
   cmp #0
   bne @nonzero_skip
   rts
@nonzero_skip:
   cmp #5
   bcs @establish_new_address

   tax
:  lda VERA_DATA0
   dex
   bne :-
   rts

@establish_new_address:               ; .A is still the slurped value, so we
   ADVANCE_VERA_ADDR_FOR_DELTA_PACKET ; can just call the advance macro
   rts
.endproc
