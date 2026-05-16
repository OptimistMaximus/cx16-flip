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
ZP_VOLATILE_ABCD := $30
ZP_VOLATILE_EFGH := $34
ZP_VOLATILE_IJKL := $38
ZP_VOLATILE_MNOP := $3C

ZP_VOLATILE_ABC  := $30
ZP_VOLATILE_DEF  := $33
ZP_VOLATILE_GHI  := $36
ZP_VOLATILE_JKL  := $39
ZP_VOLATILE_MNO  := $3C

ZP_VOLATILE_AB   := $30
ZP_VOLATILE_CD   := $32
ZP_VOLATILE_EF   := $34
ZP_VOLATILE_GH   := $36
ZP_VOLATILE_IJ   := $38
ZP_VOLATILE_KL   := $3A
ZP_VOLATILE_MN   := $3C
ZP_VOLATILE_OP   := $3E

ZP_VOLATILE_A    := $30
ZP_VOLATILE_B    := $31
ZP_VOLATILE_C    := $32
ZP_VOLATILE_D    := $33
ZP_VOLATILE_E    := $34
ZP_VOLATILE_F    := $35
ZP_VOLATILE_G    := $36
ZP_VOLATILE_H    := $37
ZP_VOLATILE_I    := $38
ZP_VOLATILE_J    := $39
ZP_VOLATILE_K    := $3A
ZP_VOLATILE_L    := $3B
ZP_VOLATILE_M    := $3C
ZP_VOLATILE_N    := $3D
ZP_VOLATILE_O    := $3E
ZP_VOLATILE_P    := $3F

RAM_VOLATILE_BUF := $400 ; $400-$5FF scratch area

;------------------------------------------------------------------------------
; GLOBAL "STATIC" VARIABLES (BASIC AREA)
;
; These are bespoke variables whose content shouldn't be meddled with except
; by the subroutines and macros that are associated with them.
;------------------------------------------------------------------------------

ZP24_vramOffset        := $22
ZP8_slurpTracker       := $25

ZP16_chunkType         := $26
ZP16_delaySyncs        := $28
ZP16_origIrqHandler    := $2A
ZP16_debugTimerSyncs   := $2C
ZP16_numSubChunks      := $2E

GOLDEN_ZP_STASH        := $5D4 ; $5D4-$5FF

;------------------------------------------------------------------------------
; RETURN CODES (set to .A upon exit, optional details in .X and .Y)
;------------------------------------------------------------------------------
RC_SUCCESS                    := 0
RC_UNSUPPORTED_FILE_TYPE      := 1  ; type
RC_UNSUPPORTED_CHUNK_TYPE     := 2  ; type
RC_INVALID_CHUNK_TYPE         := 3  ; type
RC_SPEED_TOO_HIGH             := 4  ; FLI speed, lower half of 32-bit value

.macro BSOD returnCode, detailWord
   lda #returnCode
   ldx detailWord+0
   ldy detailWord+1
   jmp bsod
.endmacro

.endif
