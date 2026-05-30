.ifndef VIDEO_INC
        VIDEO_INC = 1

.include "./global.inc"
.include "./math.inc"
.include "./vera.inc"

VRAM_IMAGE        := $00000 ; $00000-$0F9FF 320x200 @ 8bpp
VRAM_BUFF_IMAGE   := $0FA00 ; $0FA00-$1F3FF 320x200 @ 8bpp
VRAM_BUFF_PALETTE := $1F400 ; $1F400-$1F5FF 256 colors at 2 bytes each

;==============================================================================
; CALCULATE_VRAM_LINE_ADDR
;
; This calculates the VRAM address of the desired line and stores it into
; ZP24_vramOffset. This is the address for the displayed image, relative to
; VRAM $00000, and because the input .X is always 0-1999 (per the FLI spec),
; it can safely assume the result is within the 16-bit range ($0000-$FA00).
; This allows for optimizations based on 16-bit math (since the most
; significant byte of the 24-bit address will always be zero).
;
; @param .X set to the line skip
; @param scratchAddr a safe place where a 16-bit scratch value can be written
; @effect ZP24_vramOffset set to the VRAM address for the desired line
;==============================================================================
.macro CALCULATE_VRAM_LINE_ADDR scratchAddr
   lda #0
   stx ZP24_vramOffset+0                     ; .X is now in the 24-bit result
   sta ZP24_vramOffset+1                     ; which is the basis for our
   sta ZP24_vramOffset+2                     ; multiplication optimization
   U16_ASL ZP24_vramOffset
   U16_ASL ZP24_vramOffset
   U16_ASL ZP24_vramOffset
   U16_ASL ZP24_vramOffset
   U16_ASL ZP24_vramOffset
   U16_ASL ZP24_vramOffset
   U16_COPY_VAR scratchAddr, ZP24_vramOffset ; squirrel 6x value
   U16_ASL ZP24_vramOffset
   U16_ASL ZP24_vramOffset
   U16_ADD_VAR ZP24_vramOffset, scratchAddr  ; add in 6x value
.endmacro

.macro ESTABLISH_LINE_FOR_FULL scratchAddr
   SET_VERA_ADDR24_IMM $00, VRAM_BUFF_IMAGE, $10
.endmacro

.macro ESTABLISH_LINE_FOR_DELTA scratchAddr
   CALCULATE_VRAM_LINE_ADDR scratchAddr
   U24_ADD_IMM ZP24_vramOffset, VRAM_BUFF_IMAGE
   SET_VERA_ADDR24_VAR $00, ZP24_vramOffset, $10
.endmacro

.macro ADVANCE_LINE_FOR_DELTA
   U24_ADD_IMM ZP24_vramOffset, 320
   SET_VERA_ADDR24_VAR $00, ZP24_vramOffset, $10
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
