.export func_vera_setup
.export func_vera_restore
.export func_print_hex
.export func_load_palette
.export func_load_image

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

   ; is this what's causing a flash-bang?
   stz VERA_CTRL                            ; DCSEL=0
   stz VERA_DC0_VIDEO                       ; disable everything

   U16_STZ CX16_API_R0                      ; use default driver
   jsr KERNAL_GRAPH_INIT

   stz VERA_CTRL                            ; DCSEL=0
   lda #64
   sta VERA_DC0_HSCALE                      ; 640 -> 320
   sta VERA_DC0_VSCALE                      ; 480 -> 240

   lda #%00000111                           ; bitmap mode, 8bpp color
   sta VERA_L0_CONFIG

   stz VERA_L0_TILEBASE                     ; VRAM $00000, W=320
   stz VERA_L0_HSCROLL_L                    ; (unused)
   stz VERA_L0_HSCROLL_H                    ; Palette Offset 0

   U8_COPY_IMM VERA_CTRL,       $02         ; DCSEL=1
   U8_COPY_IMM VERA_DC1_HSTART, (0 >> 2)    ; These next 4 values are
   U8_COPY_IMM VERA_DC1_HSTOP,  (640 >> 2)  ; all based on 640x480
   U8_COPY_IMM VERA_DC1_VSTART, (0 >> 1)    ; regardless of screen mode
   U8_COPY_IMM VERA_DC1_VSTOP,  (400 >> 1)  ; i.e. use 400 for 200

   stz VERA_CTRL                            ; DCSEL=0
   lda #%00010001                           ; enable Layer 0, VGA mode
   sta VERA_DC0_VIDEO

   rts
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
; This loads the 512 byte palette buffer into VERA's actual palette. Due to a
; quirk of how VERA handles its palette, we can't use the "fast cache write"
; trick for palette transfer.  It should be OK though, since the palette is
; relatively small.
;==============================================================================
.proc func_load_palette: near
   SET_VERA_ADDR24_IMM $00, VRAM_BUFF_PALETTE, $10
   SET_VERA_ADDR24_IMM $01, VERA_ADDR_PALETTE, $10
   ldy #(512 / 4)
@loop:
   lda VERA_DATA0
   sta VERA_DATA1
   lda VERA_DATA0
   sta VERA_DATA1
   lda VERA_DATA0
   sta VERA_DATA1
   lda VERA_DATA0
   sta VERA_DATA1
   dey
   bne @loop
   rts
.endproc

;==============================================================================
; func_load_image
;
; @param .X holds line skip
; @param .A holds line count
;==============================================================================
.proc func_load_image: near

   pha                                 ; squirrel .A line count for later

   CALCULATE_VRAM_LINE_ADDR GR16_scratch1
   SET_VERA_ADDR24_VAR $01, ZP24_vramOffset, $30

   U24_ADD_IMM ZP24_vramOffset, VRAM_BUFF_IMAGE ; establish VERA source
   SET_VERA_ADDR24_VAR $00, ZP24_vramOffset, $10

   BATCH_COPY_ENABLE

   plx                                 ; pull line count into .X
@bulk_vram_copy_outer_loop:
   ldy #(320 / 16)                     ; .Y is for columns, batched
@bulk_vram_copy_inner_loop:
   BATCH_COPY
   BATCH_COPY
   BATCH_COPY
   BATCH_COPY
   dey
   bne @bulk_vram_copy_inner_loop
   dex
   bne @bulk_vram_copy_outer_loop

   BATCH_COPY_DISABLE

   rts
.endproc


