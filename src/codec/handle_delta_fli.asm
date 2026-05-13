.export handle_delta_fli

.import func_slurp_into_buffer
.import func_slurp_into_a
.import func_vera_flip_stage
.import func_prep_for_active_buffering

.segment "CODE"

.include "../include/global.inc"
.include "../include/math.inc"
.include "../include/video.inc"

.proc sub_skip_columns: near
   jsr func_slurp_into_a ; (.A holds skip count, where 0 means 0)
   bne @proceed_to_skip
   rts

@proceed_to_skip:
   phy
   tay
@burn_loop:
   lda VERA_DATA0
   dey
   bne @burn_loop
   ply
   rts
.endproc


.proc handle_delta_fli: near

   lda #4                              ; slurp 2 words: line skip, line count
   jsr func_slurp_into_buffer

   tmpLineSkip = RAM_VOLATILE_BUF+0    ; i.e. pointer to volatile buffer, will
   tmpLineCount = RAM_VOLATILE_BUF+2   ; be clobbered upon first line slurp

   ldx tmpLineCount                    ; .X now holds the line count
   lda tmpLineSkip                     ; .A now holds line skip
   jsr func_prep_for_active_buffering

   @line_loop:
   jsr sub_render_line
   dex
   bne @line_loop

   jsr func_vera_flip_stage
   RTS_NO_DETAIL RC_SUCCESS
.endproc

.proc sub_render_line: near
   scratchVar = ZP_VOLATILE_A

   jsr func_slurp_into_a            ; packet count
   beq @packet_loop_done            ; (packet count can legit be zero)
   tay                              ; .Y is the packet countdown
@packet_loop:
   jsr sub_skip_columns
   jsr func_slurp_into_a         ; byte count
   bit #%10000000
   beq @process_positive_count   ; i.e. bit 7 was clear

      TWOS_COMPLIMENT_A
      phy
         tay                          ; .Y now becomes the repeat count
         jsr func_slurp_into_a        ; .A now becomes the byte to repeat
      :  sta VERA_DATA0
         dey
         bne :-
      ply
      bra @process_count_done

   @process_positive_count:

      sta scratchVar
      phx
         phy
            jsr func_slurp_into_buffer
            ldy #0
         :  lda RAM_VOLATILE_BUF,y
            sta VERA_DATA0
            iny
            cpy scratchVar
            bne :-
         ply
      plx

   @process_count_done:

   dey
   bne @packet_loop
@packet_loop_done:

   ADVANCE_LINE_FOR_ACTIVE_BUFFERING

   rts
.endproc
