.ifndef API_INC
        API_INC = 1

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
; or for performance reasons.  These are not meant to be used directly by a
; program.
;------------------------------------------------------------------------------
ZP16_cachePointer       := $22
ZP8_cacheRequest        := $24
ZP8_cacheStop           := $25
ZP8_lineSkip            := $26
ZP8_lineCount           := $27
ZP8_lineStop            := $28
ZP8_lineIndex           := $29
ZP8_cacheRemaining      := $2A
ZP8_returnCode          := $2B
ZP16_returnDetail       := $2C
ZP16_unused             := $2E

;------------------------------------------------------------------------------
; RETURN CODES (set to .A upon exit, optional details in .X and .Y)
;------------------------------------------------------------------------------
RC_SUCCESS                    := 0
RC_UNSUPPORTED_FILE_TYPE      := 1  ; type
RC_INVALID_CHUNK_TYPE         := 2  ; type
RC_TOO_MANY_CHUNKS            := 3  ; chunk count

.endif
