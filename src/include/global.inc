.ifndef GLOBAL_INC
        GLOBAL_INC = 1

.include "./kernal.inc"

; ENABLE_DEBUG_TIMER = 1

;------------------------------------------------------------------------------
; GLOBAL VARIABLES (Zero Page)
;
; These MUST be in Zero Page, either because of addressing mode requirements,
; or for performance reasons.
;------------------------------------------------------------------------------
ZP_VOLATILE_PTR         := $22
ZP16_cachePointer       := $24
ZP8_cacheLoadCount      := $26
ZP8_cacheScratch        := $27
ZP8_lineSkip            := $28
ZP8_lineCount           := $29
ZP8_lineStop            := $2A
ZP8_lineIndex           := $2B
ZP8_timerTrigger        := $2C ; state variable needed by speed timer
ZP8_imageVSyncsElapsed  := $2D ; VSyncs elapsed while rendering current image

GR16_origIrqHandler     := $2E

GR32_scratch1           := $30
GR16_scratch1           := $34
GR16_scratch2           := $46
GR16_scratch3           := $48
GR24_scratch1           := $4A
GR8_scratch1            := $4D
GR8_scratch2            := $4E
GR8_scratch3            := $4F

GR32_chunkSize          := $50 ; needed for padding logic
GR16_chunkType          := $54
GR16_frameIndex         := $56
GR16_frameCount         := $58
GR8_chunkIndex          := $5A
GR8_chunkCount          := $5B
GR8_speedLimitVSyncs    := $5C  ; speed limit as VSyncs
GR8_returnCode          := $5D
GR16_returnDetail       := $5E

.ifdef ENABLE_DEBUG_TIMER
GR16_debugTimerVSyncs   := $60
GR16_debugSpeedOverrun  := $62
GR16_debugSpeedUnderrun := $64
GR16_debugTimerValue    := $66
.endif

;------------------------------------------------------------------------------
; BANKED VARIABLES
;------------------------------------------------------------------------------
FLI_PLAYER_RAM_BANK := 1
VRAM_ADDR_TABLE_L := $B000
VRAM_ADDR_TABLE_M := $B100
VRAM_ADDR_TABLE_H := $B200

CONST_cacheAddr   := $B300
CONST_cacheSize   := $FF  ; (this is a constant, not a variable)
CONST_skipArray   := $B400
CONST_countArray  := $B500

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
