.ifndef GLOBAL_INC
        GLOBAL_INC = 1

.include "./kernal.inc"

ENABLE_DEBUG_TIMER = 1

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

ZP_VOLATILE_PTR         := $30
ZP8_timerTrigger        := $32 ; state variable needed by speed timer
ZP8_imageVSyncsElapsed  := $33 ; VSyncs elapsed while rendering current image
GR16_origIrqHandler     := $34

GR32_chunkSize          := $50 ; needed for padding logic
GR16_chunkType          := $54
GR16_frameIndex         := $56
GR16_frameCount         := $58
GR8_chunkIndex          := $5A
GR8_chunkCount          := $5B
GR8_speedLimitVSyncs    := $5C  ; speed limit as VSyncs
GR8_returnCode          := $5D
GR16_returnDetail       := $5E
GR8_cacheStatus         := $60

.ifdef ENABLE_DEBUG_TIMER
GR16_debugTimerVSyncs   := $62
GR16_debugSpeedOverrun  := $64
GR16_debugSpeedUnderrun := $66
GR16_debugTimerValue    := $68
GR16_debugScratch1      := $6A
GR16_debugScratch2      := $6C
GR8_debugScratch1       := $6E
.endif




;------------------------------------------------------------------------------
; RAM VARIABLES
;------------------------------------------------------------------------------
VRAM_ADDR_TABLE_L    := $8000
VRAM_ADDR_TABLE_M    := $8100
VRAM_ADDR_TABLE_H    := $8200
CONST_skipArray      := $8300
CONST_countArray     := $8400
CONST_cacheLowerAddr := $8500
CONST_cacheUpperAddr := $8580

;------------------------------------------------------------------------------
; RETURN CODES (set to .A upon exit, optional details in .X and .Y)
;------------------------------------------------------------------------------
RC_SUCCESS                    := 0
RC_UNSUPPORTED_FILE_TYPE      := 1  ; type
RC_INVALID_CHUNK_TYPE         := 2  ; type
RC_READ_ERROR                 := 3  ; lower byte is READST value

.endif
