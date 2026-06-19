.ifndef GLOBAL_INC
        GLOBAL_INC = 1

.include "../include/kernal.inc"

;------------------------------------------------------------------------------
; FLI Player Dynamically Loadable Library Symbols
;------------------------------------------------------------------------------
FLIP_DLL_LOAD_ADDR  := $7000
FLIP_DLL_FUNC_OPEN  := FLIP_DLL_LOAD_ADDR + $100
FLIP_DLL_FUNC_NEXT  := FLIP_DLL_LOAD_ADDR + $103
FLIP_DLL_FUNC_CLOSE := FLIP_DLL_LOAD_ADDR + $106

;------------------------------------------------------------------------------
; GLOBAL VARIABLES (Zero Page) -- Library
;
; These MUST be in Zero Page, either because of addressing mode requirements,
; or for performance reasons.
;------------------------------------------------------------------------------
ZP16_cachePointer       := $22
ZP8_cacheRequest        := $24
ZP8_cacheStop           := $25
ZP8_lineSkip            := $26
ZP8_lineCount           := $27
ZP8_lineStop            := $28
ZP8_lineIndex           := $29
ZP8_cacheRemaining      := $2A

;------------------------------------------------------------------------------
; GLOBAL VARIABLES (Zero Page) -- Program
;
; These MUST be in Zero Page, either because of addressing mode requirements,
; or for performance reasons.
;------------------------------------------------------------------------------

GR16_chunkType          := $54
GR16_frameIndex         := $56
GR16_frameCount         := $58
GR8_chunkIndex          := $5A
GR8_chunkCount          := $5B
GR8_speedLimitVSyncs    := $5C  ; speed limit as VSyncs
GR8_returnCode          := $5D
GR16_returnDetail       := $5E
GR8_cacheStatus         := $60

;------------------------------------------------------------------------------
; RAM VARIABLES
;------------------------------------------------------------------------------
CONST_skipArray      := $8300
CONST_countArray     := $8400

;------------------------------------------------------------------------------
; RETURN CODES (set to .A upon exit, optional details in .X and .Y)
;------------------------------------------------------------------------------
RC_SUCCESS                    := 0
RC_UNSUPPORTED_FILE_TYPE      := 1  ; type
RC_INVALID_CHUNK_TYPE         := 2  ; type
RC_READ_ERROR                 := 3  ; lower byte is READST value

.endif
