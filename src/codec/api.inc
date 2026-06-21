.ifndef API_INC
        API_INC = 1

.include "../include/kernal.inc"

;------------------------------------------------------------------------------
; FLI Player Dynamically Loadable Library Symbols
;
; To be compliant with the Frame Driver spec, the first 256 bytes of the 
; library can be whatever the implementation prefers.  The next 24 bytes
; after that are the official entry points.  Presently only 3 are defined:
; OPEN, NEXT, CLOSE.  The remaining entries must jump somewhere that 
; immediately returns via RTS.
;
; The reamining bytes of the loadable library can be whatever the
; implementation prefers.  The maximum size allowed for the library file is
; $1000 bytes.
;------------------------------------------------------------------------------
FRAME_DRIVER_LOAD_ADDR  := $7000
FRAME_DRIVER_FUNC_OPEN  := FRAME_DRIVER_LOAD_ADDR + $00
FRAME_DRIVER_FUNC_NEXT  := FRAME_DRIVER_LOAD_ADDR + $03
FRAME_DRIVER_FUNC_CLOSE := FRAME_DRIVER_LOAD_ADDR + $06
FRAME_DRIVER_RESERVED_1 := FRAME_DRIVER_LOAD_ADDR + $09
FRAME_DRIVER_RESERVED_2 := FRAME_DRIVER_LOAD_ADDR + $0C
FRAME_DRIVER_RESERVED_3 := FRAME_DRIVER_LOAD_ADDR + $0F
FRAME_DRIVER_RESERVED_4 := FRAME_DRIVER_LOAD_ADDR + $12
FRAME_DRIVER_RESERVED_5 := FRAME_DRIVER_LOAD_ADDR + $15


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

;------------------------------------------------------------------------------
; RETURN CODES (set to .A upon exit, optional details in .X and .Y)
;------------------------------------------------------------------------------
RC_SUCCESS                    := 0
RC_UNSUPPORTED_FILE_TYPE      := 1  ; type
RC_INVALID_CHUNK_TYPE         := 2  ; type
RC_TOO_MANY_CHUNKS            := 3  ; chunk count

.endif
