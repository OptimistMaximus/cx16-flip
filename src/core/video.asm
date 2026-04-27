.export func_vera_setup
.export func_vera_restore
.export func_print_hex

.segment "CODE"

.include "../include/global.inc"
.include "../include/kernal.inc"
.include "../include/vera.inc"

;-----------------------------------------------------------------------------
; print byte as hex text to screen (assuming text mode)
;
; param: A
; side-effect: A
;-----------------------------------------------------------------------------
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

;-----------------------------------------------------------------------------
; func_vera_setup
;
; Initialize VERA conditions (do this once at startup, after reading and
; validating the header).  We begin with Layer 0 active, holding whatever
; was on the screen from before we started.
;
; TODO: create sprites, enable sprites here, and  use them to cover up the
;       pixelated mess that will be shown below the 320x200 line.
;-----------------------------------------------------------------------------
.proc func_vera_setup: near

   stz ZP8_activeLayer               ; Layer 0 is active

   stz VERA_CTRL                     ; Establish DCSEL=0
   lda #%00010000                    ; Layer 1 disabled, Layer 0 enabled
   stz VERA_DC0_VIDEO                ; Sprites disabled, Output Mode VGA

   lda #64                           ; scaling to 2:1
   sta VERA_DC0_HSCALE               ; 640x480 -> 320x480
   sta VERA_DC0_VSCALE               ; 320x480 -> 320x240

   lda #%00000111                    ; Bitmap Mode, color depth 8bpp
   sta VERA_L0_CONFIG
   sta VERA_L1_CONFIG

   stz VERA_L0_TILEBASE              ; "Tile Base", Width=0 (320 pixels)
   stz VERA_L0_HSCROLL_L             ; (unused)
   stz VERA_L0_HSCROLL_H             ; Palette Offset 0

   lda #$7D                          ; bits 16:11 of $0FA00
   sta VERA_L1_TILEBASE              ; "Tile Base", Width=0 (320 pixels)
   stz VERA_L1_HSCROLL_L             ; (unused)
   stz VERA_L1_HSCROLL_H             ; Palette Offset 0

   jmp KERNAL_GRAPH_INIT
.endproc

;-----------------------------------------------------------------------------
; func_vera_restore
;
; Restore VERA to default conditions (do this once before returning to BASIC)
;-----------------------------------------------------------------------------
.proc func_vera_restore: near
   jmp KERNAL_CINT
.endproc

