.ifndef VERA_INC
        VERA_INC = 1
;-----------------------------------------------------------------------------
; VERA Constants
;-----------------------------------------------------------------------------

VERA_ADDRx_L     = $9F20    ; b7-b0 ~ VRAM Address (7:0)
VERA_ADDRx_M     = $9F21    ; b7-b0 ~ VRAM Address (15:8)
VERA_ADDRx_H     = $9F22    ; b7-b4 ~ Address Increment (bits 7-4)
                            ;         0 = 0    1 = 1     2 = 2
                            ;         3 = 4    4 = 8     5 = 16
                            ;         6 = 32   7 = 64    8 = 128
                            ;         9 = 256  A = 512   B = 40
                            ;         C = 80   D = 160   E = 320
                            ;         F = 640
                            ; b3    ~ Decrement
                            ; b2    ~ Nibble Increment ??
                            ; b1    ~ Nibble Address   ??
                            ; b0    ~ VRAM Address (16)

VERA_DATA0       = $9F23
VERA_DATA1       = $9F24
VERA_CTRL        = $9F25    ; b7    ~ Reset
                            ; b6-b1 ~ Display Composer Select
                            ; b0    ~ Address Select

VERA_EIN         = $9F26    ; "Interrupt Enable"
                            ; b7    ~ IRQ Line (8)
                            ; b3    ~ AFLOW
                            ; b2    ~ SPRCOL
                            ; b1    ~ LINE
                            ; b0    ~ VSYNC

VERA_ISR         = $9F27    ; "Interrupt Service Routine"
                            ; b7-b4 ~ Sprite Collisions
                            ; b3    ~ AFLOW
                            ; b2    ~ SPRCOL
                            ; b1    ~ LINE
                            ; b0    ~ VSYNC

VERA_DC0_VIDEO   = $9F29    ; b7    ~ Current Field ??
                            ; b6    ~ Sprites Enabled
                            ; b5    ~ Layer 1 Enabled
                            ; b4    ~ Layer 0 Enabled
                            ; b3    ~ NTSC / RGB:240P
                            ; b2    ~ NTSC:Chroma Disable / RGB: HV Sync
                            ; b1-b0 ~ OutputMode
                            ;         0 = Video Disabled
                            ;         1 = VGA output
                            ;         2 = NTSC (composite/S-Video)
                            ;         3 = RGB 15 KHz

VERA_DC0_HSCALE   = $9F2A   ; 64 = 2:1 (good for 320x240 mode), 128 = 1:1
VERA_DC0_VSCALE   = $9F2B   ; 64 = 2:1 (good for 320x240 mode), 128 = 1:1
VERA_DC0_BORDER   = $9F2C   ; holds palette index to use for boarder

VERA_DC2_FX_CTRL  = $9F29   ; b7    Transparent Writes
                            ; b6    Cache Write Enable
                            ; b5    Cache Fill Enable
                            ; b4    One-byte Cache Cycling
                            ; b3    16-bit Hop
                            ; b2    4-bit Mode
                            ; b1-b0 Addr1 Mode

VERA_L0_CONFIG    = $9F2D   ; b7-b6 ~ Map Height
                            ; b5-b4 ~ Map Width
                            ; b3    ~ T256C
                            ; b2    ~ Bitmap Mode
                            ; b1-b0 ~ Color Depth
                            ;         0 = 1 bpp
                            ;         1 = 2 bpp
                            ;         2 = 4 bpp
                            ;         3 = 8 bpp
VERA_L0_MAPBASE   = $9F2E

VERA_L0_TILEBASE  = $9F2F   ; b7-b2 ~ Tile Base Address (tile mode)
                            ; b7-b2 ~ Bitmap Address (bitmap mode)
                            ; b1    ~ Tile Height  0 = 8 pixels  | 320
                            ; b0    ~ Tile Width   1 = 16 pixels | 640
VERA_L0_HSCROLL_L = $9F30
VERA_L0_HSCROLL_H = $9F31
VERA_L0_VSCROLL_L = $9F32
VERA_L0_VSCROLL_H = $9F33

VERA_L1_CONFIG    = $9F34
VERA_L1_MAPBASE   = $9F35
VERA_L1_TILEBASE  = $9F36
VERA_L1_HSCROLL_L = $9F37
VERA_L1_HSCROLL_H = $9F38
VERA_L1_VSCROLL_L = $9F39
VERA_L1_VSCROLL_H = $9F3A

;------------------------------------------------------------------------------
; VERA default memory layout
;------------------------------------------------------------------------------
VERA_ADDR_BITMAP         = $00000 ; Bitmap (320x240 @ 256c)
VERA_ADDR_UNUSED1        = $12C00 ; $400 bytes
VERA_ADDR_SPRITES        = $13000 ; Sprite Image Data
VERA_ADDR_TEXT           = $1B000 ; Text Mode Tile Base (Screen Codes)
VERA_ADDR_UNUSED2        = $1EC00 ; $400 bytes
VERA_ADDR_CHARSET        = $1F000 ; Text Mode Tile Map  (Character Set)
VERA_ADDR_UNUSED3        = $1F800 ; $1C0 bytes
VERA_ADDR_PSG            = $1F9C0 ; [IMMOBILE] PSG Registers
VERA_ADDR_PALETTE        = $1FA00 ; [IMMOBILE] Color Palette
VERA_ADDR_PALETTE_LOW    = $1FA00
VERA_ADDR_PALETTE_HIGH   = $1FA01
VERA_ADDR_SPRITE_ATTRS   = $1FC00 ; [IMMOBILE] Sprite Attributes
VERA_ADDR_SPRITE_ATTRS_1 = $1FC08 ; [IMMOBILE] Sprite Attributes for Sprite 1
VERA_ADDR_SPRITE_ATTRS_2 = $1FC10 ; [IMMOBILE] Sprite Attributes for Sprite 2
                                  ;            ... et cetera ...



.endif
