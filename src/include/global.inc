.ifndef GLOBAL_INC
        GLOBAL_INC = 1

.include "./kernal.inc"

; IDEAS:
;
; 114,286 CPU cycles occur during 1/70  of a second at 8 MHz.
; 133,333 CPU cycles occur during 1/60  of a second at 8 MHz.
;  44,444 CPU cycles occur during 1/180 of a second at 8 MHz.
;
; 297 seventieths = 255 sixtieths

;------------------------------------------------------------------------------
; GLOBAL "VOLATILE" VARIABLES
;
; Any subroutine or macro can use these at any time for any purpose. As such
; never assume that the values persist after you JSR or JMP or call another
; macro.  These are intended for use as quick "scratch" variables.
;
; The memory layout is based on alphabet letters, and the number of alphabet
; letters implies the size (e.g. ABC is 24-bit, EF is 16-bit).  Think of it
; like a "union" in C ... they all overlap according to their alphabet letters.
; If you write to ZP_VOLATILE_ABC you can read the middle byte via ZP_VOLATILE_B
;
; Per the honor system, please never use these in an IRQ handler, because if
; you did, then no logic could ever safely use them!  If you need ZP vars for
; IRQ stuff, declare them in the "STATIC" section.
;------------------------------------------------------------------------------
ZP_VOLATILE_A    := $22
ZP_VOLATILE_B    := $23
ZP_VOLATILE_C    := $24
ZP_VOLATILE_D    := $25
ZP_VOLATILE_E    := $26
ZP_VOLATILE_F    := $27
ZP_VOLATILE_G    := $28
ZP_VOLATILE_H    := $29
ZP_VOLATILE_I    := $2A
ZP_VOLATILE_J    := $2B
ZP_VOLATILE_K    := $2C
ZP_VOLATILE_L    := $2D

ZP_VOLATILE_ABCD := ZP_VOLATILE_A
ZP_VOLATILE_EFGH := ZP_VOLATILE_E
ZP_VOLATILE_IJKL := ZP_VOLATILE_I

ZP_VOLATILE_ABC  := ZP_VOLATILE_A
ZP_VOLATILE_DEF  := ZP_VOLATILE_D
ZP_VOLATILE_GHI  := ZP_VOLATILE_G
ZP_VOLATILE_JKL  := ZP_VOLATILE_J

ZP_VOLATILE_AB   := ZP_VOLATILE_A
ZP_VOLATILE_CD   := ZP_VOLATILE_C
ZP_VOLATILE_EF   := ZP_VOLATILE_E
ZP_VOLATILE_GH   := ZP_VOLATILE_G
ZP_VOLATILE_IJ   := ZP_VOLATILE_I
ZP_VOLATILE_KL   := ZP_VOLATILE_K

RAM_VOLATILE_BUF := $400 ; $400-$5FF scratch area

;------------------------------------------------------------------------------
; GLOBAL "STATIC" VARIABLES (BASIC AREA)
;
; These are bespoke variables whose content shouldn't be meddled with except
; by the subroutines and macros that are associated with them.
;------------------------------------------------------------------------------

ZP16_delaySyncs        := $2E

ZP32_slurpTracker      := $30
ZP32_fileSize          := $34
ZP24_vramOffset        := $38
ZP8_unused             := $3B
ZP16_chunkType         := $3C
ZP16_numSubChunks      := $3E

GOLDEN_origIrqHandler  := $600 ; 16-bit
GOLDEN_debugTimerSyncs := $602 ; 16-bit

GOLDEN_returnCode      := $6D0 ; 8-bit
GOLDEN_returnDetail    := $6D2 ; 16-bit
GOLDEN_zpStash         := $6D4

GOLDEN_slurpBuffer     := $700 ; 256 bytes (idea not implemented yet)

;------------------------------------------------------------------------------
; RETURN CODES (set to .A upon exit, optional details in .X and .Y)
;------------------------------------------------------------------------------
RC_SUCCESS                    := 0
RC_UNSUPPORTED_FILE_TYPE      := 1  ; type
RC_UNSUPPORTED_CHUNK_TYPE     := 2  ; type
RC_INVALID_CHUNK_TYPE         := 3  ; type
RC_SPEED_TOO_HIGH             := 4  ; FLI speed, lower half of 32-bit value

.macro BSOD returnCode, detailAddr
   lda #returnCode
   sta GOLDEN_returnCode
   lda detailAddr+0
   sta GOLDEN_returnDetail+0
   lda detailAddr+1
   sta GOLDEN_returnDetail+1
   jmp bsod
.endmacro

.endif
