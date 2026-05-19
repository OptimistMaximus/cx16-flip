.ifndef SLURP_INC
        SLURP_INC = 1

.include "./global.inc"
.include "./math.inc"
.include "./vera.inc"

; USE_MACPTR_FOR_U16 = 1
; USE_MACPTR_FOR_U24 = 1
; USE_MACPTR_FOR_U32 = 1

;==============================================================================
; SLURP_INTO_A
;
; @effect .A holds byte just slurped off the inputstream
;==============================================================================
.macro SLURP_INTO_A
   phx
      phy
         jsr KERNAL_ACPTR
      ply
   plx
.endmacro

;==============================================================================
; SLURP_INTO_VRAM (using VERA_DATA0)
;
; @param .A holds the count of bytes to slurp from the inputstream into VRAM
;==============================================================================
.macro SLURP_INTO_VERA
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
.macro SLURP_INTO_VERA_REPEATED
   phx
      phy
         pha                  ; push .A (byte count)
            jsr KERNAL_ACPTR  ; .A now holds the slurped byte to repeat
         plx                  ; pull byte count directly into .X
      :  sta VERA_DATA0
         dex
         bne :-
      ply
   plx
.endmacro

.macro SLURP_INTO_U8 targetAddr
   phx
      phy
         jsr KERNAL_ACPTR
         sta targetAddr
      ply
   plx
.endmacro

.macro SLURP_INTO_U16 targetAddr
   .ifdef USE_MACPTR_FOR_U16
      phx
         phy
            clc
            lda #2
            ldx #<targetAddr
            ldy #>targetAddr
            jsr KERNAL_MACPTR
         ply
      plx
   .else
      phx
         phy
            jsr KERNAL_ACPTR
            sta targetAddr+0
            jsr KERNAL_ACPTR
            sta targetAddr+1
         ply
      plx
   .endif
.endmacro

.macro SLURP_INTO_U24 targetAddr
   .ifdef USE_MACPTR_FOR_U24
      phx
         phy
            clc
            lda #3
            ldx #<targetAddr
            ldy #>targetAddr
            jsr KERNAL_MACPTR
         ply
      plx
   .else
      phx
         phy
            jsr KERNAL_ACPTR
            sta targetAddr+0
            jsr KERNAL_ACPTR
            sta targetAddr+1
            jsr KERNAL_ACPTR
            sta targetAddr+2
         ply
      plx
   .endif
.endmacro

.macro SLURP_INTO_U32 targetAddr
   .ifdef USE_MACPTR_FOR_U32
      phx
         phy
            clc
            lda #4
            ldx #<targetAddr
            ldy #>targetAddr
            jsr KERNAL_MACPTR
         ply
      plx
   .else
      phx
         phy
            jsr KERNAL_ACPTR
            sta targetAddr+0
            jsr KERNAL_ACPTR
            sta targetAddr+1
            jsr KERNAL_ACPTR
            sta targetAddr+2
            jsr KERNAL_ACPTR
            sta targetAddr+3
         ply
      plx
   .endif
.endmacro

;==============================================================================
; SLURP_INTO_OBLIVION
;
; This macro is highly inefficient, but it is assumed to only be used in a few
; rare situations where performance isn't critical.
;
; @param .A holds the number of bytes to slurp and discard
;==============================================================================
.macro SLURP_INTO_OBLIVION
   phx
      phy
         tax
      :  jsr KERNAL_ACPTR
         dex
         bne :-
      ply
   plx
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




.endif

