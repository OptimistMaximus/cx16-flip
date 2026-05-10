.org $080D

.segment "INIT"
.segment "STARTUP"
.segment "ONCE"
.segment "CODE"

USE_GRAPH_INIT = 1
USE_HV_TRICK = 1

CX16_API_R0  := $02
CX16_API_R1  := $04
CX16_API_R2  := $06
CX16_API_R3  := $08
CX16_API_R4  := $0A

KERNAL_GRAPH_INIT       := $FF20 ; initialize graphics
KERNAL_GRAPH_SET_COLORS := $FF29 ; set stroke, fill and background colors
KERNAL_GRAPH_DRAW_RECT  := $FF2F ; draw a rectangle (optionally filled)
KERNAL_GRAPH_PUT_CHAR   := $FF41
KERNAL_SCREEN_MODE      := $FF5F

VERA_ADDRx_L      := $9F20    ; b7-b0 ~ VRAM Address (7:0)
VERA_ADDRx_M      := $9F21    ; b7-b0 ~ VRAM Address (15:8)
VERA_ADDRx_H      := $9F22    ; b7-b4 ~ Address Increment (bits 7-4)
VERA_DATA0        := $9F23
VERA_DATA1        := $9F24

VERA_L0_CONFIG    := $9F2D
VERA_L0_MAPBASE   := $9F2E
VERA_L0_TILEBASE  := $9F2F
VERA_L0_HSCROLL_L := $9F30
VERA_L0_HSCROLL_H := $9F31
VERA_L0_VSCROLL_L := $9F32
VERA_L0_VSCROLL_H := $9F33

VERA_CTRL         := $9F25
VERA_DC0_VIDEO    := $9F29
VERA_DC0_HSCALE   := $9F2A
VERA_DC0_VSCALE   := $9F2B
VERA_DC1_HSTART   := $9F29   ; Active Display H-Start (9:2)
VERA_DC1_HSTOP    := $9F2A   ; Active Display H-Stop (9:2)
VERA_DC1_VSTART   := $9F2B   ; Active Display V-Start (8:1)
VERA_DC1_VSTOP    := $9F2C   ; Active Display V-Stop (8:1)

.macro DRAW_RECT posx, posy, width, height
   lda #<posx
   sta CX16_API_R0+0
   lda #>posx
   sta CX16_API_R0+1

   lda #<posy
   sta CX16_API_R1+0
   lda #>posy
   sta CX16_API_R1+1

   lda #width
   sta CX16_API_R2+0
   stz CX16_API_R2+1

   lda #height
   sta CX16_API_R3+0
   stz CX16_API_R3+1

   stz CX16_API_R4+0           ; rectangle corner radius (0)
   stz CX16_API_R4+1
   clc                         ; rectangle fill
   jsr KERNAL_GRAPH_DRAW_RECT
.endmacro

.macro SET_COLOR color
   lda #color                  ; color of stroke
   tax                         ; color of fill
   tay                         ; color of background background
   jsr KERNAL_GRAPH_SET_COLORS
.endmacro

   ;----------------------------------------------------------
   ; initialize graphics
   ;----------------------------------------------------------
.ifdef USE_GRAPH_INIT
   stz CX16_API_R0+0           ; default driver (0)
   stz CX16_API_R0+1
   jsr KERNAL_GRAPH_INIT
.else
   clc                         ; clear means "set"
   lda #$80                    ; 320x240@256C Layer 0
   jsr KERNAL_SCREEN_MODE
.endif

   ;----------------------------------------------------------
   ; establish VERA DCSEL=0 stuff
   ;----------------------------------------------------------
   stz VERA_CTRL
   lda #%00010001           ; sprites off, layer 1 off, layer 0 on, VGA mode
   sta VERA_DC0_VIDEO

   lda #64                  ; i.e. 2x scale
   sta VERA_DC0_HSCALE
   sta VERA_DC0_VSCALE

   ;----------------------------------------------------------
   ; establish VERA layer 0 stuff
   ;----------------------------------------------------------
   lda #%00000111           ; bitmap mode, 8bpp color
   sta VERA_L0_CONFIG

   stz VERA_L0_TILEBASE     ; i.e. $00000
   stz VERA_L0_HSCROLL_L    ; (unused)
   stz VERA_L0_HSCROLL_H    ; Palette Offset 0

   ;----------------------------------------------------------
   ; establish VERA DCSEL=1 stuff
   ;----------------------------------------------------------
.ifdef USE_HV_TRICK
   lda #$02
   sta VERA_CTRL

   lda #(0 >> 2)
   sta VERA_DC1_HSTART
   lda #(640 >> 2)
   sta VERA_DC1_HSTOP

   lda #(0 >> 1)
   sta VERA_DC1_VSTART
   lda #(400 >> 1)
   sta VERA_DC1_VSTOP
.endif

   SET_COLOR 2
   DRAW_RECT $0000, $0000, $20, $20
   DRAW_RECT $0020, $0020, $20, $20
   DRAW_RECT $0040, $0040, $20, $20
   DRAW_RECT $0060, $0060, $20, $20
   DRAW_RECT $0080, $0080, $20, $20
   DRAW_RECT $00A0, $00A0, $20, $20
   DRAW_RECT $00C0, $00C0, $20, $20

   SET_COLOR 3
   DRAW_RECT $00E0, $00E0, $20, $20  ; should clip bottom

   SET_COLOR 4
   DRAW_RECT $0100, $00C0, $20, $20
   DRAW_RECT $0120, $00A0, $20, $20 ; should kiss right

   
;   lda #$02
;   sta VERA_CTRL
;   lda #30
;   sta VERA_DC1_VSTART
;   lda #210
;   sta VERA_DC1_VSTOP
;   stz VERA_CTRL
;
;   lda #$02
;   sta VERA_CTRL
;   lda #40
;   sta VERA_DC1_HSTART
;   lda #120
;   sta VERA_DC1_HSTOP
;   stz VERA_CTRL
   
   rts
