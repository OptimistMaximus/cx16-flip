.ifndef SLURP_INC
        SLURP_INC = 1

.include "./global.inc"
.include "./math.inc"
.include "./vera.inc"

;==============================================================================
; SLURP_INTO_A
;
; @effect .A holds byte just slurped off the inputstream
;==============================================================================
.macro SLURP_INTO_A
   jsr KERNAL_ACPTR
.endmacro

;==============================================================================
; SLURP_INTO_VRAM (using VERA_DATA0)
;
; @param .A holds the count of bytes to slurp from the inputstream into VRAM
;==============================================================================
.macro SLURP_INTO_VRAM
   phx
      phy
         sec
         ldx #<VERA_DATA0
         ldy #>VERA_DATA0
         jsr KERNAL_MACPTR
      ply
   plx
.endmacro

;==============================================================================
; SLURP_INTO_VRAM_REPEATED (using VERA_DATA0)
;
; This routine slurps one byte from the inputstream, then repeats in into VRAM
;
; @param .A holds the number of times to repeat the slurped byte
;==============================================================================
.macro SLURP_INTO_VRAM_REPEATED
   phx
      pha                  ; push .A (byte count)
         jsr KERNAL_ACPTR  ; .A now holds the slurped byte to repeat
      plx                  ; pull byte count directly into .X
   :  sta VERA_DATA0
      dex
      bne :-
   plx
.endmacro

.macro SLURP_INTO_U8 targetAddr
   jsr KERNAL_ACPTR
   sta targetAddr
.endmacro

.macro SLURP_INTO_U16 targetAddr
   jsr KERNAL_ACPTR
   sta targetAddr+0
   jsr KERNAL_ACPTR
   sta targetAddr+1
.endmacro

.macro SLURP_INTO_U24 targetAddr
   phx
      phy
         clc
         lda #3
         ldx #<targetAddr
         ldy #>targetAddr
         jsr KERNAL_MACPTR
      ply
   plx
.endmacro

.macro SLURP_INTO_U32 targetAddr
   phx
      phy
         clc
         lda #4
         ldx #<targetAddr
         ldy #>targetAddr
         jsr KERNAL_MACPTR
      ply
   plx
.endmacro

;==============================================================================
; SLURP_INTO_BUFFER
;
; @param .A holds the number of bytes to slurp and discard
; @param targetAddr where to store the bytes
;==============================================================================
.macro SLURP_INTO_BUFFER targetAddr
   phx
      phy
         clc
         ldx #<targetAddr
         ldy #>targetAddr
         jsr KERNAL_MACPTR
      ply
   plx
.endmacro

;==============================================================================
; SLURP_INTO_BUFFER_IMM
;==============================================================================
.macro SLURP_INTO_BUFFER_IMM count, targetAddr
   lda #count
   SLURP_INTO_BUFFER targetAddr
.endmacro

;==============================================================================
; SKIP_PIXELS (using VERA_DATA0)
;
; @param .A holds the number of pixels to advance (skip over)
;==============================================================================
.macro SKIP_PIXELS
   phx
      tax
   :  lda VERA_DATA0
      dex
      bne :-
   plx
.endmacro

;==============================================================================
; SKIP_COLORS (using VERA_DATA0)
;
; @param .A holds the number of colors to advance (skip over)
;==============================================================================
.macro SKIP_COLORS
   phx
      tax
   :  lda VERA_DATA0 ; low (GB)
      lda VERA_DATA0 ; high (R)
      dex
      bne :-
   plx
.endmacro


.endif

