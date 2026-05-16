.export handle_color_64
.export handle_color_256

.import func_load_palette
.import func_slurp_into_buffer
.import func_slurp_into_a

.segment "CODE"

.include "../include/global.inc"
.include "../include/math.inc"
.include "../include/vera.inc"
.include "../include/video.inc"

.macro SLURP_INTO_VAR16 targetAddr
   jsr func_slurp_into_a
   sta targetAddr+0
   jsr func_slurp_into_a
   sta targetAddr+1
.endmacro

.macro SLURP_INTO_VAR8 targetAddr
   jsr func_slurp_into_a
   sta targetAddr
.endmacro



;------------------------------------------------------------------------------
; handle_color_64
;
; Parses color chunk and populates palette buffer
;------------------------------------------------------------------------------
.proc handle_color_64: near
   lda #$EA ; NOP
   sta smc_anchor_r_shift+0
   sta smc_anchor_r_shift+1
   sta smc_anchor_b_shift+0
   sta smc_anchor_b_shift+1
   lda #$0A ; ASL
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
   lda #$4A ; LSR
   sta smc_anchor_r_shift+0
   sta smc_anchor_r_shift+1
   sta smc_anchor_b_shift+0
   sta smc_anchor_b_shift+1
   lda #$EA ; NOP
   sta smc_anchor_g_shift+0
   sta smc_anchor_g_shift+1
   jmp sub_handle_color
.endproc

sub_handle_color:

   tempColor      = ZP_VOLATILE_ABC
   tempColorRed   = ZP_VOLATILE_A
   tempColorGreen = ZP_VOLATILE_B
   tempColorBlue  = ZP_VOLATILE_C
   tempVeraRed    = ZP_VOLATILE_E
   tempVeraGreen  = ZP_VOLATILE_F
   numPackets     = ZP_VOLATILE_GH
   copyCount      = ZP_VOLATILE_I

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

   SLURP_INTO_VAR16 numPackets

   ldx #0
packet_loop:

   jsr sub_skip_colors

   SLURP_INTO_VAR8 copyCount
   ldy #0

      copy_loop:
         phx
            phy
               SLURP_INTO_VAR8 tempColorRed
smc_anchor_r_shift:
               lsr                      ; nop if 6-bit
               lsr                      ; nop if 6-bit
               lsr
               lsr
               sta tempVeraRed

               SLURP_INTO_VAR8 tempColorGreen
smc_anchor_g_shift:
               nop                      ; asl if 6-bit
               nop                      ; asl if 6-bit
               and #$F0
               sta tempVeraGreen

               SLURP_INTO_VAR8 tempColorBlue
smc_anchor_b_shift:
               lsr                      ; nop if 6-bit
               lsr                      ; nop if 6-bit
               lsr
               lsr
               ora tempVeraGreen
               sta VERA_DATA0           ; store VERA color (GB)
               lda tempVeraRed          ; store VERA color (R)
               sta VERA_DATA0
            ply
         plx

         iny
         cpy copyCount
         bne copy_loop

   inx
   cpx numPackets                       ; just the low byte
   bne packet_loop

   jmp func_load_palette                ; jsr/rts optimization


   
   
; @effect .Y clobbered
sub_skip_colors:
   jsr func_slurp_into_a ; skip count
   beq @skip_done
   tay
@skip_loop:
   lda VERA_DATA0 ; burn low
   lda VERA_DATA0 ; burn high
   dey
   bne @skip_loop
@skip_done:
   rts
