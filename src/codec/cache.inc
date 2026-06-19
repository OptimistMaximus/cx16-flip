.ifndef CACHE_INC
        CACHE_INC = 1

.include "../include/global.inc"
.include "../include/vera.inc"

;==============================================================================
; SIP_INTO_A
;
; Note, status flags reflect the value just loaded into .A
; Note, this macro uses an unnamed label
;
; @effect .A holds the next available byte as read from cache
;==============================================================================
.macro SIP_INTO_A
   inc ZP16_cachePointer
   bne :+
   jsr func_cache_load_page
:  lda (ZP16_cachePointer)
.endmacro

;==============================================================================
; SIP_INTO_U8
;==============================================================================
.macro SIP_INTO_U8 targetAddr
   SIP_INTO_A
   sta targetAddr
.endmacro

;==============================================================================
; SIP_INTO_U16
;==============================================================================
.macro SIP_INTO_U16 targetAddr
   SIP_INTO_A
   sta targetAddr+0
   SIP_INTO_A
   sta targetAddr+1
.endmacro

;==============================================================================
; SIP_INTO_U24
;==============================================================================
.macro SIP_INTO_U24 targetAddr
   SIP_INTO_A
   sta targetAddr+0
   SIP_INTO_A
   sta targetAddr+1
   SIP_INTO_A
   sta targetAddr+2
.endmacro

;==============================================================================
; SIP_INTO_U32
;==============================================================================
.macro SIP_INTO_U32 targetAddr
   SIP_INTO_A
   sta targetAddr+0
   SIP_INTO_A
   sta targetAddr+1
   SIP_INTO_A
   sta targetAddr+2
   SIP_INTO_A
   sta targetAddr+3
.endmacro

;==============================================================================
; SIP_INTO_OBLIVION
;
; Note, this macro uses TWO unnamed labels
;
; @param count the number of bytes to slurp
; @effect .X clobbered
;==============================================================================
.macro SIP_INTO_OBLIVION count
   ldx #count
:  SIP_INTO_A
   dex
   bne :--     ; compensate for unnamed label used within SIP_INTO_A
.endmacro

;==============================================================================
; SIP_INTO_VRAM_REPEATED
;
; Read one byte from the stream and repeat it into VRAM
;
; Note, this macro uses TWO unnamed labels
;
; @param .A the number of times to repeat the byte
; @effect .X clobbered
;==============================================================================
.macro SIP_INTO_VRAM_REPEATED
   tax
   SIP_INTO_A
:  sta VERA_DATA0
   dex
   bne :-
.endmacro

;==============================================================================
; SIP_INTO_VRAM
;
; Read byte from the stream into VRAM
;
; @param .A the number of bytes to read
; @effect .X clobbered
;==============================================================================
.macro SIP_INTO_VRAM
@sip_into_vram:
   cmp #8                    ; reading 1-by-1 is faster when less than this
   bcs @bulk_is_faster
   tax
@sip_into_vram_loop:
   SIP_INTO_A
   sta VERA_DATA0
   dex
   bne @sip_into_vram_loop
   bra @sipped
@bulk_is_faster:
   jsr func_cache_read_into_vram
@sipped:
.endmacro

.endif

