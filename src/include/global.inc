.ifndef GLOBAL_INC
        GLOBAL_INC = 1

.include "./kernal.inc"

; ENABLE_DEBUG_TIMER = 1

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
GR8_speedLimitVSyncs    := $5C  ; speed limit as VSyncs

.ifdef ENABLE_DEBUG_TIMER
GR16_debugTimerVSyncs   := $62
GR16_debugSpeedOverrun  := $64
GR16_debugSpeedUnderrun := $66
GR16_debugTimerValue    := $68
GR16_debugScratch1      := $6A
GR16_debugScratch2      := $6C
GR8_debugScratch1       := $6E
.endif

.endif
