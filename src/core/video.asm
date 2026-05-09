.export func_vera_setup
.export func_vera_restore
.export func_register_sprites
.export func_vera_flip_layer
.export func_vera_copy_layer
.export func_print_hex
.export func_load_palette

.segment "CODE"

.include "../include/global.inc"
.include "../include/kernal.inc"
.include "../include/vera.inc"
.include "../include/video.inc"
.include "../include/zeropage.inc"

;==============================================================================
; print byte as hex text to screen (assuming text mode)
;
; @param:  .A holds the value you want to print to screen
;==============================================================================
.proc func_print_hex: near
   pha               ; push A onto stack
      lsr            ; shift left 4 times, i.e.  A = A >> 4
      lsr            ;  the end result is the high nibble is
      lsr            ;  now in the low nibble
      lsr
      jsr sub_print_hex_nibble
   pla
   and #$0F          ; the end result is the high nibble is gone
   jmp sub_print_hex_nibble ; final jsr optimized to jmp
.endproc

.proc sub_print_hex_nibble: near
   cmp #$0A          ; compare with $0A
   bcs @letter       ; i.e. (A >= 10) then A must be a letter
   ora #$30          ; else it's a digit, convert to PETSCII by adding $30
   bra @print        ; jump ahead to print
@letter:
   clc
   adc #$37          ; convert to PETSCII ... A=$41, B=$42, etc
@print:
   jmp KERNAL_CHROUT ; print whatever's in A
.endproc

;==============================================================================
; func_vera_setup
;
; Initialize VERA conditions (do this once at startup, after reading and
; validating the header).  We begin with Layer 1 "active", in that that's
; where we buffer the first image, while Layer 0 remains the one being shown
; on-screen
;==============================================================================
.proc func_vera_setup: near
   U8_COPY_IMM ZP8_activeLayer,   LAYER_1_ACTIVE
   U8_COPY_IMM VERA_CTRL,         $00              ; DCSEL=0
   U8_COPY_IMM VERA_DC0_VIDEO,    LAYER_0_ENABLED
   U8_COPY_IMM VERA_DC0_HSCALE,   64               ; 640 -> 320
   U8_COPY_IMM VERA_DC0_VSCALE,   64               ; 480 -> 240
   U8_COPY_IMM VERA_L0_CONFIG,    %00000111        ; bitmap mode, 8bpp color
   U8_COPY_IMM VERA_L1_CONFIG,    %00000111        ; bitmap mode, 8bpp color
   U8_COPY_IMM VERA_L0_TILEBASE,  LAYER_0_TILEBASE
   U8_COPY_IMM VERA_L1_TILEBASE,  LAYER_1_TILEBASE
   U8_COPY_IMM VERA_L0_HSCROLL_L, $00              ; (unused)
   U8_COPY_IMM VERA_L0_HSCROLL_H, $00              ; Palette Offset 0
   U8_COPY_IMM VERA_L1_HSCROLL_L, $00              ; (unused)
   U8_COPY_IMM VERA_L1_HSCROLL_H, $00              ; Palette Offset 0

.ifndef ENABLE_SPRITES  
   U8_COPY_IMM VERA_CTRL,         $02              ; DCSEL=1
   U8_COPY_IMM VERA_DC1_HSTART,   (0 >> 2)         ; These next 4 values are
   U8_COPY_IMM VERA_DC1_HSTOP,    (640 >> 2)       ; all based on 640x480
   U8_COPY_IMM VERA_DC1_VSTART,   (0 >> 1)         ; regardless of screen mode
   U8_COPY_IMM VERA_DC1_VSTOP,    (396 >> 1)       ; i.e. use 396 for 198
.endif
      
   U16_STZ CX16_API_R0                             ; use default driver
   jmp KERNAL_GRAPH_INIT
.endproc

;==============================================================================
; func_vera_restore
;
; Restore VERA to default conditions (do this once before returning to BASIC)
;==============================================================================
.proc func_vera_restore: near
   jmp KERNAL_CINT
.endproc

;==============================================================================
; func_load_palette
;
; This loads the 512 byte palette buffer into VERA's actual palette
;==============================================================================
.proc func_load_palette: near
   SET_VRAM_DATA0_FOR_PALETTE_BUFFER
   SET_VERA_ADDR24_IMM $01, VERA_ADDR_PALETTE, $10
   ldy #0
@loop:
   lda VERA_DATA0
   sta VERA_DATA1
   lda VERA_DATA0
   sta VERA_DATA1
   iny
   bne @loop
   rts
.endproc

;==============================================================================
; func_vera_flip_layer
;
; If Layer 0 is active, that means we've been buffering to it, so now it is
; time to enable Layer 0, disable Layer 1, and change the active layer value
; so we'll start buffering to to Layer 1 next.  If Layer 1 then essentially do
; the opposite.
;
; @effect .X clobbered
; @effect .Y clobbered
;==============================================================================
.proc func_vera_flip_layer: near
   lda ZP8_activeLayer
   beq @prep_when_0_active
      ldx #LAYER_1_ENABLED      ; Layer 1 is active, so enable it to show it,
      ldy #LAYER_0_ACTIVE       ;         and make Layer 0 become active
      bra @prep_done
@prep_when_0_active:
      ldx #LAYER_0_ENABLED      ; Layer 0 is active, so enable it to show it,
      ldy #LAYER_1_ACTIVE       ;         and make Layer 1 become active
@prep_done:
   stz VERA_CTRL                ; Establish DCSEL=0
   stx VERA_DC0_VIDEO           ; apply control settings
   sty ZP8_activeLayer          ; update who's active
   rts
.endproc

.proc func_vera_copy_layer
   lda ZP8_activeLayer
   beq @copy_layer_source_is_layer_1
   SET_VERA_ADDR24_IMM $00, LAYER_0_ADDRESS, $10 ; source is layer 0
   SET_VERA_ADDR24_IMM $01, LAYER_1_ADDRESS, $10 ; target is layer 1
   bra @copy_layer_source_and_target_established
@copy_layer_source_is_layer_1:
   SET_VERA_ADDR24_IMM $00, LAYER_1_ADDRESS, $10 ; source is layer 1
   SET_VERA_ADDR24_IMM $01, LAYER_0_ADDRESS, $10 ; target is layer 0
@copy_layer_source_and_target_established:

   ldx #198 ; 198 rows
@row_loop:
   ldy #80  ; 320 columns (80 4-byte chunks)
@column_loop:
   lda VERA_DATA0
   sta VERA_DATA1
   lda VERA_DATA0
   sta VERA_DATA1
   lda VERA_DATA0
   sta VERA_DATA1
   lda VERA_DATA0
   sta VERA_DATA1
   dey
   bne @column_loop
   dex
   bne @row_loop
   rts
.endproc

.proc func_register_sprites: near
.ifndef ENABLE_SPRITES
   rts
.endif
   xpos = ZP_VOLATILE_AB
   ypos = ZP_VOLATILE_CD

   ; Sprite data is 32x32 of color 1 (because zero is transparent!)
   SET_VERA_ADDR_DEFAULT SPRITE_DATA
   lda #$11
   ldx #16
@sprite_data_outer_loop:
   ldy #32
@sprite_data_inner_loop:
   sta VERA_DATA0
   dey
   bne @sprite_data_inner_loop
   dex
   bne @sprite_data_outer_loop

   ; This sets up the 20 sprites we need, using about 80
   ; bytes of code. This is a lot less than storing static
   ; sprint data at 8 bytes per sprint (160 bytes total)
   ; plus a few bytes to do the simple copy loop.
   SET_VERA_ADDR_DEFAULT VERA_ADDR_SPRITE_ATTRS_1
   ldy #2
   U16_COPY_IMM ypos, 198
 @sprite_attr_y_loop:
   ldx #10
   U16_STZ xpos
 @sprite_attr_x_loop:
   U8_COPY_IMM VERA_DATA0, <(SPRITE_DATA >> 5)
   U8_COPY_IMM VERA_DATA0, >(SPRITE_DATA >> 5) ; b7=0 for mode 0
   U8_COPY_VAR VERA_DATA0, xpos+0
   U8_COPY_VAR VERA_DATA0, xpos+1
   U8_COPY_VAR VERA_DATA0, ypos+0
   U8_COPY_VAR VERA_DATA0, ypos+1
   U8_COPY_IMM VERA_DATA0, %00001100
   U8_COPY_IMM VERA_DATA0, %10100000
   U16_ADD_IMM xpos, 32
   dex
   bne @sprite_attr_x_loop
   U16_ADD_IMM ypos, 32
   dey
   bne @sprite_attr_y_loop

   rts
.endproc
