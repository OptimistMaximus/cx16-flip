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
; GLOBAL "STATIC" VARIABLES
;
; These are bespoke variables whose content shouldn't be meddled with except
; by the subroutines and macros that are associated with them.
;------------------------------------------------------------------------------

ZP24_vramOffset        := $22
ZP8_activeStage        := $25
ZP8_height             := $26
ZP8_depth              := $27
ZP8_slurpTracker       := $28

ZP16_chunkType         := $40
ZP16_delaySyncs        := $42
ZP16_width             := $44
ZP16_numFrames         := $46
ZP16_currFrame         := $48
ZP16_numSubChunks      := $4A
ZP16_origIrqHandler    := $4C
ZP16_debugTimerSyncs   := $4E

RAM_paletteStagingArea := $600 ; $600-$7FF for staging the palette

;------------------------------------------------------------------------------
; RETURN CODES (set to .A upon exit, optional details in .X and .Y)
;------------------------------------------------------------------------------
RC_SUCCESS                    := 0
RC_CANNOT_OPEN_FILE           := 1  ; .X is CHKIN status, .Y is OPEN status
RC_UNSUPPORTED_FILE_TYPE      := 2  ; type
RC_UNSUPPORTED_FRAME_TYPE     := 3  ; type
RC_UNSUPPORTED_CHUNK_TYPE     := 4  ; type
RC_WIDTH_TOO_BIG              := 5  ; width
RC_HEIGHT_TOO_BIG             := 6  ; height
RC_DEPTH_TOO_BIG              := 7  ; depth
RC_SPEED_TOO_HIGH             := 8  ; FLI speed, lower half of 32-bit value
RC_DELAY_TOO_LONG             := 9  ; FLC delay
RC_INVALID_CHUNK_TYPE         := 10 ; type


;==============================================================================
; RTS_VAR16_DETAIL
;
; This macro establishes a semantic convention where a subroutine can return
; with .A holding a return code (see above) and .X and .Y holding detail.
;
; Note that as part of this macro's contract, it sets .A as the very last
; action. So, callers can do a quick BEQ or BNE to detect success or failure.
;==============================================================================
.macro RTS_VAR16_DETAIL rc, detailAddr
   ldx detailAddr+0
   ldy detailAddr+1
   lda #rc
   rts
.endmacro

;==============================================================================
; RTS_NO_DETAIL
;
; This macro is exactly the same as RTS_VAR16_DETAIL, except it forces the
; .X and .Y values to zero.
;==============================================================================
.macro RTS_NO_DETAIL rc
   ldx #0
   ldy #0
   lda #rc
   rts
.endmacro

.endif
