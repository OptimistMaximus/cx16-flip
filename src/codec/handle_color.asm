.export handle_color_64
.export handle_color_256

.import func_load_palette
.import func_cache_load_page

.segment "CODE"

.include "../include/cache.inc"
.include "../include/global.inc"
.include "../include/math.inc"
.include "../include/opcodes.inc"
.include "../include/vera.inc"
.include "../include/video.inc"

;------------------------------------------------------------------------------
; handle_color_64
;
; Parses color chunk and populates palette buffer
;------------------------------------------------------------------------------
.proc handle_color_64: near
   lda #OPCODE_NOP
   sta smc_anchor_r_shift+0
   sta smc_anchor_r_shift+1
   sta smc_anchor_b_shift+0
   sta smc_anchor_b_shift+1
   lda #OPCODE_ASL_A
   sta smc_anchor_g_shift+0
   sta smc_anchor_g_shift+1
   jmp sub_handle_color
.endproc

;------------------------------------------------------------------------------
; handle_color_256
;
; Parses color chunk and populates palette buffer
;------------------------------------------------------------------------------
.proc handle_color_256: near
   lda #OPCODE_LSR_A
   sta smc_anchor_r_shift+0
   sta smc_anchor_r_shift+1
   sta smc_anchor_b_shift+0
   sta smc_anchor_b_shift+1
   lda #OPCODE_NOP
   sta smc_anchor_g_shift+0
   sta smc_anchor_g_shift+1
   jmp sub_handle_color
.endproc

sub_handle_color:

   tempVeraRed    = GR8_scratch1
   tempVeraGreen  = GR8_scratch2
   copyCount      = GR8_scratch3
   numPackets     = GR16_scratch1

   ;---------------------------------------------------------------------------
   ; Although packet count is 16-bit, it doesn't make sense for the size to be
   ; anything other than 1 to 256. Zero packets would be silly, because if
   ; there really aren't any entries then there wouldn't be any point in the
   ; color chunk in the first place.  Similarly, 257 or more entries would be
   ; ridiculous because the FLI format only supports 256 colors.  That said,
   ; we can safely ignore the high byte of the packet count and treat the low
   ; byte's zero as meaning 256.  It would be highly inefficient to have 256
   ; packets each encoding a skip count of 0 and a run count of 1, but it is
   ; technically a spec-compliant thing to do.
   ;
   ; We still need to slurp 16-bit values, of course.  We'll walk the packets
   ; and account for the runs as we go, updating the palette staging area.
   ;
   ; Each packet has a skip count and a copy count. A skip count of zero means
   ; zero (don't skip) but a copy count of zero means 256 (i.e. a full palette
   ; is being declared in 1 packet)
   ;---------------------------------------------------------------------------
   SET_VERA_ADDR24_IMM $00, VRAM_BUFF_PALETTE, $10
   SIP_INTO_U16 numPackets

   ldx #0
packet_loop:

   SIP_INTO_A                     ; .A holds skip count, where 0 means 0
   cmp #0
   beq @zero_skip
   tay
:  lda VERA_DATA0
   lda VERA_DATA0
   dey
   bne :-

@zero_skip:
   SIP_INTO_U8 copyCount
   ldy #0
copy_loop:
   SIP_INTO_A             ; slurp RGB's R
smc_anchor_r_shift:
   lsr                      ; nop if 6-bit
   lsr                      ; nop if 6-bit
   lsr
   lsr
   sta tempVeraRed

   SIP_INTO_A             ; slurp RGB's G
smc_anchor_g_shift:
   nop                      ; asl if 6-bit
   nop                      ; asl if 6-bit
   and #$F0
   sta tempVeraGreen

   SIP_INTO_A             ; slurp RGB's B
   smc_anchor_b_shift:
   lsr                      ; nop if 6-bit
   lsr                      ; nop if 6-bit
   lsr
   lsr
   ora tempVeraGreen
   sta VERA_DATA0           ; store VERA color (GB)
   lda tempVeraRed          ; store VERA color (R)
   sta VERA_DATA0

   iny
   cpy copyCount
   bne copy_loop

   inx
   cpx numPackets                       ; just the low byte
   bne packet_loop

   U8_COPY_IMM ZP8_lineSkip, $FF
   U8_COPY_IMM ZP8_lineCount, $FF
   rts
