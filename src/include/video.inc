.ifndef VIDEO_INC
        VIDEO_INC = 1

.include "./global.inc"
.include "./math.inc"
.include "./vera.inc"

VRAM_IMAGE        := $00000 ; $00000-$0F9FF 320x200 @ 8bpp
VRAM_BUFF_IMAGE   := $0FA00 ; $0FA00-$1F3FF 320x200 @ 8bpp
VRAM_BUFF_PALETTE := $1F400 ; $1F400-$1F5FF 256 colors at 2 bytes each

;==============================================================================
; SET_VRAM_ADDR_FOR_DELTA_LINE
;
; Use lookup table to quickly set VERA address to a specific line offset in
; the staging area, for access via DATA0 and using auto-increment of 1.
;
; This is overall faster than adding 320 to a 24-bit ZP var (29 cycles)
; then using a macro to set the vera address (22 cycles), but it is highly
; specific to preparing the address for a delta line.
;
; @param .X is line offset
; @cycles 16
;==============================================================================
.macro SET_VRAM_ADDR_FOR_DELTA_LINE
   stz VERA_CTRL
   lda VRAM_ADDR_TABLE_L,x
   sta VERA_ADDRx_L
   lda VRAM_ADDR_TABLE_M,x
   sta VERA_ADDRx_M
   lda VRAM_ADDR_TABLE_H,x
   sta VERA_ADDRx_H
.endmacro

;==============================================================================
; SET_VRAM_ADDR_FOR_FULL_LINE
;
; Set VERA address for line zero, DATA0, auto-inc 1
;==============================================================================
.macro SET_VRAM_ADDR_FOR_FULL_LINE
   lda #0
   sta VERA_CTRL
   sta VERA_ADDRx_L
   lda #$FA
   sta VERA_ADDRx_M
   lda #$10
   sta VERA_ADDRx_H
.endmacro

;==============================================================================
; SET_VRAM_ADDR_FOR_SCREEN_LINE
;
; Use lookup table to set VERA address to a specific line offset in the target
; area (where the image is drawn to screen), for access via DATA1 and using
; auto-increment of 4.
;
; This is a bit clunky because it's based on the pre-calculated values for
; the staging area and auto-increment 1, but it doesn't need to be very fast
; since we only call this once per frame (whereas the delta line calc gets
; called once per line in a delta chunk).
;==============================================================================
.macro SET_VRAM_ADDR_FOR_SCREEN_LINE
   SWITCH_RAM_BANK_IMM FLI_PLAYER_RAM_BANK
   lda #1                    ; establish DATA1
   sta VERA_CTRL

   lda VRAM_ADDR_TABLE_L,x   ; load low byte and effectively subtract $00
   sta VERA_ADDRx_L          ; (the low byte of the stage fold)

   lda VRAM_ADDR_TABLE_M,x   ; load middle byte and subtract $FA
   sec                       ; (the middle byte of the stage fold)
   sbc #$FA
   sta VERA_ADDRx_M

   lda VRAM_ADDR_TABLE_H,x   ; load high byte and subtract potential carry
   sbc #0                    ; note, it was already OR'ed with $10 for
   ora #$20                  ; auto-inc, but we want $30 so OR in $20
   sta VERA_ADDRx_H
.endmacro

;==============================================================================
; ADVANCE_VERA_ADDR_FOR_DELTA_PACKET
;
; This is highly specific to delta packet rendering, where we know the VRAM
; address has already been established, and we know it uses VERA_DATA0 and
; auto-inc 1, and we know we'll never be advancing for more than 255 columns.
;
; @param .A is how many pixels to advance
; @cycles 37
;==============================================================================
.macro ADVANCE_VERA_ADDR_FOR_DELTA_PACKET
   stz VERA_CTRL
   clc
   adc VERA_ADDRx_L
   sta VERA_ADDRx_L
   lda VERA_ADDRx_M
   adc #0
   sta VERA_ADDRx_M
   lda VERA_ADDRx_H
   adc #0
   sta VERA_ADDRx_H
.endmacro

.macro BATCH_COPY_ENABLE
   lda #%00000100 ; DCSEL=2
   sta VERA_CTRL
   lda #%01100000 ; Enable Cache Fill & Cache Write
   sta VERA_DC2_FX_CTRL
.endmacro

.macro BATCH_COPY_DISABLE
   lda #%00000100 ; DCSEL=2
   sta VERA_CTRL
   stz VERA_DC2_FX_CTRL
.endmacro

.macro BATCH_COPY
   lda VERA_DATA0
   lda VERA_DATA0
   lda VERA_DATA0
   lda VERA_DATA0
   stz VERA_DATA1
.endmacro

.endif
