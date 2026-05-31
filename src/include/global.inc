.ifndef GLOBAL_INC
        GLOBAL_INC = 1

.include "./kernal.inc"

; MINIMIZE_ZEROPAGE_USAGE = 1

;------------------------------------------------------------------------------
; GLOBAL VARIABLES (Zero Page)
;
; These MUST be in Zero Page, either because of addressing mode requirements,
; or for performance reasons.
;------------------------------------------------------------------------------
ZP_VOLATILE_PTR         := $22
ZP16_cachePointer       := $24
ZP8_cacheRemaining      := $26
ZP8_cacheLoadCount      := $27
ZP8_lineSkip            := $28
ZP8_lineCount           := $29
ZP8_lineStop            := $2A
ZP8_timerTrigger        := $2B ; state variable needed by speed timer
ZP8_imageVSyncsElapsed  := $2C ; VSyncs elapsed while rendering current image

;------------------------------------------------------------------------------
; GLOBAL VARIABLES
;
; These can be anywhere in RAM, though the program will be smaller and faster
; if they exist in Zero Page.  As long as the total usage here is under $40
; bytes, it can easily fit in either ZP or GOLDEN RAM.
;------------------------------------------------------------------------------
.ifdef MINIMIZE_ZEROPAGE_USAGE
   GLOBAL_VAR_BASE    := $B600
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

GR32_chunkSize        := GLOBAL_VAR_BASE + $60 ; needed for padding logic
GR16_chunkType        := GLOBAL_VAR_BASE + $64
GR16_frameIndex       := GLOBAL_VAR_BASE + $66
GR16_frameCount       := GLOBAL_VAR_BASE + $68
GR8_chunkIndex        := GLOBAL_VAR_BASE + $6A
GR8_chunkCount        := GLOBAL_VAR_BASE + $6B
GR8_cacheSize         := GLOBAL_VAR_BASE + $6C

GR8_speedLimitVSyncs  := GLOBAL_VAR_BASE + $70  ; speed limit as VSyncs
GR8_returnCode        := GLOBAL_VAR_BASE + $71
GR16_returnDetail     := GLOBAL_VAR_BASE + $72
GR16_origIrqHandler   := GLOBAL_VAR_BASE + $74
GR16_debugTimerVSyncs := GLOBAL_VAR_BASE + $76
GR16_debugSpeedOverrun := GLOBAL_VAR_BASE + $78
GR16_debugSpeedUnderrun := GLOBAL_VAR_BASE + $7A

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
