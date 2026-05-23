.ifndef SLURP_INC
        SLURP_INC = 1

.include "./global.inc"
.include "./math.inc"
.include "./vera.inc"

.import func_cache_init
.import func_cache_read_into_a
.import func_cache_read_into_vram
.import func_cache_dupe_into_vram

;==============================================================================
; SLURP_INTO_U8
;
; This routine slurps one byte into a target address (little endian)
;==============================================================================
.macro SLURP_INTO_U8 targetAddr
   jsr func_cache_read_into_a
   sta targetAddr
.endmacro

;==============================================================================
; SLURP_INTO_U16
;
; This routine slurps two bytes into a target address (little endian)
;==============================================================================
.macro SLURP_INTO_U16 targetAddr
   jsr func_cache_read_into_a
   sta targetAddr+0
   jsr func_cache_read_into_a
   sta targetAddr+1
.endmacro

;==============================================================================
; SLURP_INTO_U24
;
; This routine slurps three byte into a target address (little endian)
;==============================================================================
.macro SLURP_INTO_U24 targetAddr
   jsr func_cache_read_into_a
   sta targetAddr+0
   jsr func_cache_read_into_a
   sta targetAddr+1
   jsr func_cache_read_into_a
   sta targetAddr+2
.endmacro

;==============================================================================
; SLURP_INTO_U32
;
; This routine slurps four byte into a target address (little endian)
;==============================================================================
.macro SLURP_INTO_U32 targetAddr
   jsr func_cache_read_into_a
   sta targetAddr+0
   jsr func_cache_read_into_a
   sta targetAddr+1
   jsr func_cache_read_into_a
   sta targetAddr+2
   jsr func_cache_read_into_a
   sta targetAddr+3
.endmacro

;==============================================================================
; SLURP_INTO_OBLIVION
;==============================================================================
.macro SLURP_INTO_OBLIVION count
   phx
      ldx #count
   :  jsr func_cache_read_into_a
      dex
      bne :-
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

