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

; MINIMIZE_ZEROPAGE_USAGE = 1

;------------------------------------------------------------------------------
; GLOBAL VARIABLES (Zero Page)
;
; These MUST be in Zero Page, either because of addressing mode requirements,
; or for performance reasons.
;------------------------------------------------------------------------------
ZP_VOLATILE_PTR         := $22
ZP24_vramOffset         := $24
ZP16_cachePointer       := $2A
ZP8_cacheRemaining      := $2C
ZP8_cacheScratch        := $2D
ZP8_timerTrigger        := $2E ; state variable needed by speed timer
ZP8_imageVSyncsElapsed  := $2F ; VSyncs elapsed while rendering current image

;------------------------------------------------------------------------------
; GLOBAL VARIABLES
;
; These can be anywhere in RAM, though the program will be smaller and faster
; if they exist in Zero Page.  As long as the total usage here is under $40
; bytes, it can easily fit in either ZP or GOLDEN RAM.
;------------------------------------------------------------------------------
CONST_cacheAddr       := $400
CONST_cacheSize       := $FF  ; (this is a constant, not a variable)

.ifdef MINIMIZE_ZEROPAGE_USAGE
   GLOBAL_VAR_BASE    := $500
.else
   GLOBAL_VAR_BASE    := $0
.endif

GR32_scratch1         := GLOBAL_VAR_BASE + $40
GR32_scratch2         := GLOBAL_VAR_BASE + $44

GR16_scratch1         := GLOBAL_VAR_BASE + $48
GR16_scratch2         := GLOBAL_VAR_BASE + $4A
GR16_scratch3         := GLOBAL_VAR_BASE + $4C
GR16_scratch4         := GLOBAL_VAR_BASE + $4E

GR24_scratch1         := GLOBAL_VAR_BASE + $50
GR24_scratch2         := GLOBAL_VAR_BASE + $53

GR8_scratch1          := GLOBAL_VAR_BASE + $56
GR8_scratch2          := GLOBAL_VAR_BASE + $57
GR8_scratch3          := GLOBAL_VAR_BASE + $58
GR8_scratch4          := GLOBAL_VAR_BASE + $59
GR16_debugTimerValue  := GLOBAL_VAR_BASE + $5A

GR32_chunkSize        := GLOBAL_VAR_BASE + $60
GR16_chunkType        := GLOBAL_VAR_BASE + $64
GR16_frameIndex       := GLOBAL_VAR_BASE + $66
GR16_frameCount       := GLOBAL_VAR_BASE + $68
GR16_chunkIndex       := GLOBAL_VAR_BASE + $6A
GR16_chunkCount       := GLOBAL_VAR_BASE + $6C
GR16_speedVsyncs      := GLOBAL_VAR_BASE + $6E

GR8_speedLimitVSyncs  := GLOBAL_VAR_BASE + $70  ; speed limit as VSyncs
GR8_returnCode        := GLOBAL_VAR_BASE + $71
GR16_returnDetail     := GLOBAL_VAR_BASE + $72
GR16_origIrqHandler   := GLOBAL_VAR_BASE + $74
GR16_debugTimerVSyncs := GLOBAL_VAR_BASE + $76
GR16_debugSpeedSkips  := GLOBAL_VAR_BASE + $78
GR8_paddingRetries    := GLOBAL_VAR_BASE + $7A

;------------------------------------------------------------------------------
; RETURN CODES (set to .A upon exit, optional details in .X and .Y)
;------------------------------------------------------------------------------
RC_SUCCESS                    := 0
RC_UNSUPPORTED_FILE_TYPE      := 1  ; type
RC_INVALID_CHUNK_TYPE         := 2  ; type
RC_READ_ERROR                 := 3  ; lower byte is READST value

.macro BSOD returnCode, detailAddr
   lda #returnCode
   sta GR8_returnCode
   lda detailAddr+0
   sta GR16_returnDetail+0
   lda detailAddr+1
   sta GR16_returnDetail+1
   jmp bsod
.endmacro

.macro BSOD_A returnCode
   lda #returnCode
   sta GR8_returnCode
   sta GR16_returnDetail+0
   stz GR16_returnDetail+1
   jmp bsod
.endmacro


.endif
