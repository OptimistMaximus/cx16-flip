.ifndef GLOBAL_INC
        GLOBAL_INC = 1

.include "./kernal.inc"

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
ZP_VOLATILE_ABCD := $22
ZP_VOLATILE_EFGH := $26
ZP_VOLATILE_IJKL := $2A

ZP_VOLATILE_ABC  := $22
ZP_VOLATILE_DEF  := $25
ZP_VOLATILE_GHI  := $28
ZP_VOLATILE_JKL  := $2B

ZP_VOLATILE_AB   := $22
ZP_VOLATILE_CD   := $24
ZP_VOLATILE_EF   := $26
ZP_VOLATILE_GH   := $28
ZP_VOLATILE_IJ   := $2A
ZP_VOLATILE_KL   := $2C
ZP_VOLATILE_MN   := $2E

ZP_VOLATILE_A     := $22
ZP_VOLATILE_B     := $23
ZP_VOLATILE_C     := $24
ZP_VOLATILE_D     := $25
ZP_VOLATILE_E     := $26
ZP_VOLATILE_F     := $27
ZP_VOLATILE_G     := $28
ZP_VOLATILE_H     := $29
ZP_VOLATILE_I     := $2A
ZP_VOLATILE_J     := $2B
ZP_VOLATILE_K     := $2C
ZP_VOLATILE_L     := $2D
ZP_VOLATILE_M     := $2E
ZP_VOLATILE_N     := $2F

RAM_VOLATILE_BUF   := $400 ; $400-$4FF scratch area

;------------------------------------------------------------------------------
; GLOBAL "STATIC" VARIABLES
;
; These are bespoke variables whose content shouldn't be meddled with except
; by the subroutines and macros that are associated with them.
;------------------------------------------------------------------------------

ZP16_delaySyncs        := $40
ZP16_width             := $42
ZP8_height             := $44
ZP8_depth              := $45
ZP16_numFrames         := $46

RAM16_fileType         := $500

RAM_stagingArea        := $600 ; $600-$7FF for staging data

;------------------------------------------------------------------------------
; FLI CONSTANTS
;------------------------------------------------------------------------------
FILE_TYPE_FLI   := $AF11
FILE_TYPE_FLC   := $AF12

FRAME_TYPE      := $F1FA

CHUNK_COLOR_256 := $0004 ; FLI palette info, RGB values from 0-255
CHUNK_COLOR_64  := $000B ; FLI palette info, RGB values from 0-63
CHUNK_DELTA_FLI := $000C ; FLI compressed via deltas
CHUNK_BLACK     := $000D ; FLI all pixels implicitly color zero)
CHUNK_BYTE_RUN  := $000F ; FLI byte run
CHUNK_FLI_COPY  := $0010 ; FLI uncompressed

;------------------------------------------------------------------------------
; SYMBOLS
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; RETURN CODES (set to .A upon exit, optional details in .X and .Y)
;------------------------------------------------------------------------------
RC_SUCCESS                    := 0
RC_CANNOT_OPEN_FILE           := 1 ; .X is CHKIN status, .Y is OPEN status
RC_UNSUPPORTED_FILE_TYPE      := 2 ; type
RC_UNSUPPORTED_FRAME_TYPE     := 3 ; type
RC_UNSUPPORTED_CHUNK_TYPE     := 4 ; type
RC_WIDTH_TOO_BIG              := 5 ; width
RC_HEIGHT_TOO_BIG             := 6 ; height
RC_DEPTH_TOO_BIG              := 7 ; depth
RC_SPEED_TOO_HIGH             := 8 ; FLI speed, lower half of 32-bit value
RC_DELAY_TOO_LONG             := 9 ; FLC delay
 

;------------------------------------------------------------------------------
; Convenience Macros for RTS with Return Code and .X .Y detail
;
; This is very important: lda is always done LAST, so that calling code can
; safely do a BEQ or BNE to check the return status
;------------------------------------------------------------------------------
.macro RTS_VAR16_DETAIL rc, detailAddr
   ldx #<detailAddr
   ldy #>detailAddr
   lda #rc
   rts
.endmacro

.macro RTS_NO_DETAIL rc
   ldx #0
   ldy #0
   lda #rc
   rts
.endmacro




.endif
