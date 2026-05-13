.export handle_byte_run

.import func_slurp_into_buffer
.import func_slurp_into_a
.import func_vera_flip_stage
.import func_prep_for_active_buffering

.segment "CODE"

.include "../include/global.inc"
.include "../include/video.inc"

.proc handle_byte_run: near
   lda #0                             ; full starts at line 0 always
   jsr func_prep_for_active_buffering

   ldx #199                           ; .X is the line countdown
@line_loop:
   jsr sub_render_line
   dex
   bne @line_loop

   jsr sub_burn_line
   jsr func_vera_flip_stage

   RTS_NO_DETAIL RC_SUCCESS
.endproc

.proc sub_render_line: near
   scratchVar = ZP_VOLATILE_P
   jsr func_slurp_into_a           ; packet count
   tay                             ; .Y is the packet countdown
@packet_loop:
   jsr func_slurp_into_a        ; byte count
   bit #%10000000
   beq @process_positive_count  ; i.e. bit 7 was clear

      TWOS_COMPLIMENT_A
      sta scratchVar
      phx
         phy
            jsr func_slurp_into_buffer ; .A is already set to desired count
            ldy #0
         :  lda RAM_VOLATILE_BUF,y
            sta VERA_DATA0
            iny
            cpy scratchVar
            bne :-
         ply
      plx

      bra @process_count_done
   @process_positive_count:

      phy
         tay                          ; .Y now becomes the repeat count
         jsr func_slurp_into_a        ; .A now becomes the byte to repeat
      :  sta VERA_DATA0
         dey
         bne :-
      ply

   @process_count_done:

   dey
   bne @packet_loop
   rts
.endproc

.proc sub_burn_line: near
   jsr func_slurp_into_a           ; packet count
   tay                             ; .Y is the packet countdown
@packet_loop:
   jsr func_slurp_into_a        ; byte count
   bit #%10000000
   beq @process_positive_count  ; i.e. bit 7 was clear

      TWOS_COMPLIMENT_A
      phx
         phy
            jsr func_slurp_into_buffer ; .A is already set to desired count
         ply
      plx

      bra @process_count_done
   @process_positive_count:

      jsr func_slurp_into_a        ; .A now becomes the byte to repeat

   @process_count_done:

   dey
   bne @packet_loop
   rts
.endproc


