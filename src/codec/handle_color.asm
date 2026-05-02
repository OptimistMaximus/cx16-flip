.segment "CODE"

.export handle_color_64
.export handle_color_256

.segment "CODE"

.include "../include/file.inc"
.include "../include/global.inc"
.include "../include/math.inc"
.include "../include/vera.inc"

   stagingArea       = ZP_VOLATILE_AB
   numPackets        = ZP_VOLATILE_CD
   numPacketsLo      = ZP_VOLATILE_C   ; 0 means 256 (since 16-bit was $0100)
   innerCounts       = ZP_VOLATILE_EF
   innerCountSkip    = ZP_VOLATILE_E   ; 0 means 256, but that'd be silly
   innerCountCopy    = ZP_VOLATILE_F   ; 0 means 256 (i.e. all 1 color)
   tempColor         = ZP_VOLATILE_GHI
   tempColorRed      = ZP_VOLATILE_G
   tempColorGreen    = ZP_VOLATILE_H
   tempColorBlue     = ZP_VOLATILE_I
   veraColor         = ZP_VOLATILE_KL
   veraColorGB       = ZP_VOLATILE_K
   veraColorR        = ZP_VOLATILE_L
   tempGreenNibble   = ZP_VOLATILE_M
   paletteCopyAddr   = ZP_VOLATILE_OP
   

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

   ;---------------------------------------------------------------------------
   ; Although packet count is 16-bit, it doesn't make sense for the size to be
   ; anything other than 1 to 256. Zero packets would be silly, because if
   ; there really aren't any entries then there wouldn't be any point in the
   ; color chunk in the first place.  Similarly, 257 or more entries would be
   ; ridiculous because the FLI format only supports 256 colors.  That said,
   ; we can safely ignore the high byte of the packet count and treat the low
   ; byte's zero as meaning 256.
   ;
   ; We still need to slurp 16-bit values, of course.  We'll walk the packets
   ; and account for the runs as we go, updating the palette staging area.
   ;---------------------------------------------------------------------------
   U16_COPY_IMM stagingArea, RAM_paletteStagingArea
   
   SLURP_VAR16 ZP_VOLATILE_CD
   ldx ZP_VOLATILE_C              ; .X is the packet count (0 means 256)
   
packet_loop:
   SLURP_VAR16 innerCounts
   U16_ADD_VAR8 stagingArea, innerCountSkip
   ldy innerCountCopy

      copy_loop:
         SLURP_VAR24 tempColor

         lda tempColorRed
smc_anchor_r_shift:
         lsr                      ; nop if 6-bit
         lsr                      ; nop if 6-bit
         lsr
         lsr
         phy
            ldy #1
            sta (stagingArea),y
         ply
   
         lda tempColorGreen
smc_anchor_g_shift:
         nop                      ; asl if 6-bit
         nop                      ; asl if 6-bit
         and #$F0
         sta tempGreenNibble
   
         lda tempColorBlue
smc_anchor_b_shift:
         lsr                      ; nop if 6-bit
         lsr                      ; nop if 6-bit
         lsr
         lsr
         ora tempGreenNibble
         sta (stagingArea)
         
         U16_ADD_IMM stagingArea, 2 ; advance to next palette entry
         dey
         bne copy_loop

   dex
   bne packet_loop

   ;---------------------------------------------------------------------------
   ; now copy the staging area to the palette
   ;---------------------------------------------------------------------------
   SET_VERA_ADDR24_IMM $00, VERA_ADDR_PALETTE, $10 ; DATA0, stride 1
   U16_COPY_IMM paletteCopyAddr, RAM_paletteStagingArea+$0000
   ldx #0
@palette_copy_outer_loop:
   ldy #0
@palette_copy_inner_loop:
   lda (paletteCopyAddr),y
   sta VERA_DATA0
   iny
   bne @palette_copy_inner_loop

   inc paletteCopyAddr+1
   dex
   bne @palette_copy_outer_loop
      
   RTS_NO_DETAIL RC_SUCCESS

