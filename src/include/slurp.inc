.ifndef SLURP_INC
        SLURP_INC = 1

.include "./global.inc"
.include "./math.inc"
.include "./vera.inc"

.import func_cache_init
.import func_cache_read_into_a
.import func_cache_read_into_vram
.import func_cache_dupe_into_vram

ENABLE_CACHE = 1

;==============================================================================
; SLURP_INIT
;
; Initialize caching (call this once, after opening the input stream and
; before reading from it via these macros).
;==============================================================================
.macro SLURP_INIT
.ifdef ENABLE_CACHE
   jsr func_cache_init
.endif
.endmacro

;==============================================================================
; SLURP_INTO_A
;
; @effect .A holds byte just slurped off the inputstream
; @effect status flags hold non-deterministic info
;==============================================================================
.macro SLURP_INTO_A
.ifdef ENABLE_CACHE
   jsr func_cache_read_into_a
.else
   jsr KERNAL_ACPTR
.endif
.endmacro

;==============================================================================
; SLURP_INTO_VRAM (using VERA_DATA0)
;
; @param .A holds the count of bytes to slurp from the inputstream into VRAM
;==============================================================================
.macro SLURP_INTO_VRAM
.ifdef ENABLE_CACHE
   jsr func_cache_read_into_vram
.else
   phx
      phy
         sec
         ldx #<VERA_DATA0
         ldy #>VERA_DATA0
         jsr KERNAL_MACPTR
      ply
   plx
.endif
.endmacro

;==============================================================================
; SLURP_INTO_VRAM_REPEATED (using VERA_DATA0)
;
; This routine slurps one byte from the inputstream, then repeats in into VRAM
;
; @param .A holds the number of times to repeat the slurped byte
;==============================================================================
.macro SLURP_INTO_VRAM_REPEATED
.ifdef ENABLE_CACHE
   jsr func_cache_dupe_into_vram
.else
   phx
      pha                  ; push .A (byte count)
         jsr KERNAL_ACPTR  ; .A now holds the slurped byte to repeat
      plx                  ; pull byte count directly into .X
   :  sta VERA_DATA0
      dex
      bne :-
   plx
.endif
.endmacro

;==============================================================================
; SLURP_INTO_U8
;
; This routine slurps one byte into a target address (little endian)
;==============================================================================
.macro SLURP_INTO_U8 targetAddr
.ifdef ENABLE_CACHE
   jsr func_cache_read_into_a
   sta targetAddr
.else
   jsr KERNAL_ACPTR
   sta targetAddr
.endif
.endmacro

;==============================================================================
; SLURP_INTO_U16
;
; This routine slurps two bytes into a target address (little endian)
;==============================================================================
.macro SLURP_INTO_U16 targetAddr
.ifdef ENABLE_CACHE
   jsr func_cache_read_into_a
   sta targetAddr+0
   jsr func_cache_read_into_a
   sta targetAddr+1
.else
   jsr KERNAL_ACPTR
   sta targetAddr+0
   jsr KERNAL_ACPTR
   sta targetAddr+1
.endif
.endmacro

;==============================================================================
; SLURP_INTO_U24
;
; This routine slurps three byte into a target address (little endian)
;==============================================================================
.macro SLURP_INTO_U24 targetAddr
.ifdef ENABLE_CACHE
   jsr func_cache_read_into_a
   sta targetAddr+0
   jsr func_cache_read_into_a
   sta targetAddr+1
   jsr func_cache_read_into_a
   sta targetAddr+2
.else
   phx
      phy
         clc
         lda #3
         ldx #<targetAddr
         ldy #>targetAddr
         jsr KERNAL_MACPTR
      ply
   plx
.endif
.endmacro

;==============================================================================
; SLURP_INTO_U32
;
; This routine slurps four byte into a target address (little endian)
;==============================================================================
.macro SLURP_INTO_U32 targetAddr
.ifdef ENABLE_CACHE
   jsr func_cache_read_into_a
   sta targetAddr+0
   jsr func_cache_read_into_a
   sta targetAddr+1
   jsr func_cache_read_into_a
   sta targetAddr+2
   jsr func_cache_read_into_a
   sta targetAddr+3
.else
   phx
      phy
         clc
         lda #4
         ldx #<targetAddr
         ldy #>targetAddr
         jsr KERNAL_MACPTR
      ply
   plx
.endif
.endmacro

;==============================================================================
; SLURP_INTO_OBLIVION
;==============================================================================
.macro SLURP_INTO_OBLIVION count
.ifdef ENABLE_CACHE
   phx
      ldx #count
   :  jsr func_cache_read_into_a
      dex
      bne :-
   plx
.else
   lda #count
   phx
      phy
         clc
         ldx #<RAM_VOLATILE_BUF
         ldy #>RAM_VOLATILE_BUF
         jsr KERNAL_MACPTR
      ply
   plx
.endif
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

