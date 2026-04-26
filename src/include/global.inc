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
; Per the honor system, please never use these in an IRQ handler, because if
; you did, then no logic could ever safely use them!  If you need ZP vars for
; IRQ stuff, declare them in the "STATIC" section.
;
; The naming convention uses alphabet pairs to organize them by size. Just make
; sure you don't have any overlapping alphabet letters in the combos you use.
; For example, you can safely use ZP_VOLATILE_ABC and ZP_VOLATILE_D together,
; but you can't use ZP_VOLATILE_DEF and ZP_VOLATILE_CD at the same time, since
; they'd clobber each other's 'D' spot.
;------------------------------------------------------------------------------
ZP32_VOLATILE_ABCD := $22
ZP32_VOLATILE_EFGH := $26

ZP24_VOLATILE_ABC  := $22
ZP24_VOLATILE_DEF  := $25

ZP16_VOLATILE_AB   := $22
ZP16_VOLATILE_CD   := $24
ZP16_VOLATILE_EF   := $26
ZP16_VOLATILE_GH   := $28

ZP8_VOLATILE_A     := $22
ZP8_VOLATILE_B     := $23
ZP8_VOLATILE_C     := $24
ZP8_VOLATILE_D     := $25
ZP8_VOLATILE_E     := $26
ZP8_VOLATILE_F     := $27
ZP8_VOLATILE_G     := $28
ZP8_VOLATILE_H     := $29

RAM_VOLATILE_BUF   := $400 ; $400-$4FF scratch area

;------------------------------------------------------------------------------
; GLOBAL "STATIC" VARIABLES
;
; These are bespoke variables whose content shouldn't be meddled with except
; by the subroutines and macros that are associated with them.
;------------------------------------------------------------------------------

ZP8_lineCount          := $40


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
RC_CANNOT_OPEN_FILE           := 1  ; .X holds CHKIN status, .Y holds OPEN status
RC_UNSUPPORTED_FILE_TYPE      := 2  ; .X .Y hold low and high bytes of type
RC_UNSUPPORTED_FRAME_TYPE     := 3  ; .X .Y hold low and high bytes of type
RC_UNSUPPORTED_CHUNK_TYPE     := 4  ; .X .Y hold low and high bytes of type
RC_WIDTH_TOO_BIG              := 5  ; .X .Y hold low and high bytes of width
RC_HEIGHT_TOO_BIG             := 6  ; .X .Y hold low and high bytes of height
RC_DELAY_TOO_LONG             := 7

.endif
