.ifndef SLURP_INC
        SLURP_INC = 1

.include "./global.inc"
.include "./math.inc"
.include "./vera.inc"

;==============================================================================
; SLURP_INTO_A
;
; @effect .A holds the next available byte as read from cache
;
; Note that unlike the LDA instruction, the status flags do not reflect what
; byte was just read into the .A buffer.
;==============================================================================
.macro SLURP_INTO_A
   lda ZP8_cacheRemaining
   bne :+
   jsr func_cache_load_page
:  lda (ZP16_cachePointer)
   dec ZP8_cacheRemaining
   inc ZP16_cachePointer
.endmacro

;==============================================================================
; SLURP_INTO_U8
;
; This routine slurps one byte into a target address (little endian)
;==============================================================================
.macro SLURP_INTO_U8 targetAddr
   SLURP_INTO_A
   sta targetAddr
.endmacro

;==============================================================================
; SLURP_INTO_U16
;
; This routine slurps two bytes into a target address (little endian)
;==============================================================================
.macro SLURP_INTO_U16 targetAddr
   SLURP_INTO_A
   sta targetAddr+0
   SLURP_INTO_A
   sta targetAddr+1
.endmacro

;==============================================================================
; SLURP_INTO_U24
;
; This routine slurps three byte into a target address (little endian)
;==============================================================================
.macro SLURP_INTO_U24 targetAddr
   SLURP_INTO_A
   sta targetAddr+0
   SLURP_INTO_A
   sta targetAddr+1
   SLURP_INTO_A
   sta targetAddr+2
.endmacro

;==============================================================================
; SLURP_INTO_U32
;
; This routine slurps four byte into a target address (little endian)
;==============================================================================
.macro SLURP_INTO_U32 targetAddr
   SLURP_INTO_A
   sta targetAddr+0
   SLURP_INTO_A
   sta targetAddr+1
   SLURP_INTO_A
   sta targetAddr+2
   SLURP_INTO_A
   sta targetAddr+3
.endmacro

;==============================================================================
; SLURP_INTO_OBLIVION
;==============================================================================
.macro SLURP_INTO_OBLIVION count
   phx
      ldx #count
   :
      SLURP_INTO_A
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

