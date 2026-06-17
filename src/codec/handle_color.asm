.export handle_color_64
.export handle_color_256

.import func_load_palette
.import func_cache_load_page
.import volatile16a
.import volatile8a
.import volatile8b
.import volatile8c

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
   jsr sub_handle_color_prep
@packet_loop:
   lda #0 ; zero means color 256
   jsr sub_handle_color_packet
   dex
   bne @packet_loop
   U8_COPY_IMM ZP8_lineSkip, $FF
   U8_COPY_IMM ZP8_lineCount, $FF
   stz GR8_returnCode
   rts
.endproc

;------------------------------------------------------------------------------
; handle_color_256
;
; Parses color chunk and populates palette buffer
;------------------------------------------------------------------------------
.proc handle_color_256: near
   jsr sub_handle_color_prep
@packet_loop:
   lda #1 ; non-zero means color 256
   jsr sub_handle_color_packet
   dex
   bne @packet_loop
   U8_COPY_IMM ZP8_lineSkip, $FF
   U8_COPY_IMM ZP8_lineCount, $FF
   stz GR8_returnCode
   rts
.endproc

;==============================================================================
; sub_handle_color_prep
;
; @effect .X holds the number of packets
;==============================================================================
.proc sub_handle_color_prep: near

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
   SIP_INTO_U16 volatile16a

   ldx volatile16a
   rts
.endproc

.proc sub_handle_color_packet: near

   tempVeraRed    = volatile8a
   tempVeraGreen  = volatile8b
   colorMode      = volatile8c

   sta colorMode

   SIP_INTO_A                     ; .A holds skip count, where 0 means 0
   cmp #0
   beq @zero_skip
   tay
@skip_loop:
   lda VERA_DATA0
   lda VERA_DATA0
   dey
   bne @skip_loop
@zero_skip:

   SIP_INTO_A                ; read in copy count
   tay
copy_loop:

   lda colorMode
   bne @mode256

      SIP_INTO_A             ; slurp RGB's R
      lsr
      lsr
      sta tempVeraRed

      SIP_INTO_A             ; slurp RGB's G
      asl
      asl
      and #$F0
      sta tempVeraGreen

      SIP_INTO_A             ; slurp RGB's B
      lsr
      lsr
      bra @mode_handled

   @mode256:

      SIP_INTO_A             ; slurp RGB's R
      lsr
      lsr
      lsr
      lsr
      sta tempVeraRed

      SIP_INTO_A             ; slurp RGB's G
      and #$F0
      sta tempVeraGreen

      SIP_INTO_A             ; slurp RGB's B
      lsr
      lsr
      lsr
      lsr

   @mode_handled:

   ora tempVeraGreen
   sta VERA_DATA0           ; store VERA color (GB)
   lda tempVeraRed          ; store VERA color (R)
   sta VERA_DATA0

   dey
   bne copy_loop

   rts
.endproc
