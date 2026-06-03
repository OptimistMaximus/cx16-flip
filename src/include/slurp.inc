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
;
; With the caching algorithim as of version 0.7.0, batch reading N bytes is
; slower than individual reads when N < 6.  So for now, unless that algorithm
; is revisited, it is faster to do 16/24/32 bit reads as individual reads. 
;==============================================================================
.macro SLURP_INTO_A
   lda ZP16_cachePointer
   cmp ZP8_cacheLoadCount
   bcc :+
   jsr func_cache_load_page
:  lda (ZP16_cachePointer)
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
;
; @param count the number of bytes to slurp
;==============================================================================
.macro SLURP_INTO_OBLIVION count
   lda #count
   jsr func_cache_discard_bytes
.endmacro

.endif

