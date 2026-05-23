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

;------------------------------------------------------------------------------
; GLOBAL "VOLATILE" VARIABLES
;
; Per the honor system, please never use these in an IRQ handler, because if
; you did, then no logic could ever safely use them!  If you need ZP vars for
; IRQ stuff, declare them in the "STATIC" section.
;------------------------------------------------------------------------------
ZP_VOLATILE_PTR         := $22

;------------------------------------------------------------------------------
; GLOBAL "STATIC" VARIABLES (ZERO PAGE)
;
; These are bespoke variables whose content shouldn't be meddled with except
; by the subroutines and macros that are associated with them.
;------------------------------------------------------------------------------

ZP8_timerTrigger        := $24 ; state variable needed by speed timer
ZP8_imageVSyncsElapsed  := $25 ; VSyncs elapsed while rendering current image

ZP32_chunkReads         := $26 ; how many bytes have been read for curr chunk
ZP16_cachePointer       := $2A ; TODO make this 24-bit and document chunk size assumption
ZP8_cacheRemaining      := $2C
ZP8_cacheScratch        := $2D

ZP24_vramOffset         := $30


;------------------------------------------------------------------------------
; GLOBAL "STATIC" VARIABLES (GOLDEN RAM)
;
; These are bespoke variables whose content shouldn't be meddled with except
; by the subroutines and macros that are associated with them.
;------------------------------------------------------------------------------
GOLDEN_cacheAddr      := $500 ; $400-$4FF cache
GOLDEN_cacheSize      := $FF  ; how much to load into cache (at most)

GR32_scratch1         := $400
GR32_scratch2         := $404

GR16_scratch1         := $408
GR16_scratch2         := $40A
GR16_scratch3         := $40C
GR16_scratch4         := $40E

GR24_scratch1         := $410
GR24_scratch2         := $413

GR8_scratch1          := $414
GR8_scratch2          := $415
GR8_scratch3          := $416
GR8_scratch4          := $417

GR32_chunkSize        := $420
GR16_frameIndex       := $424
GR16_frameCount       := $426
GR16_chunkIndex       := $428
GR16_chunkCount       := $42A

GR16_chunkType        := $430
GR16_speedVsyncs      := $434
GR8_speedLimitVSyncs  := $436  ; speed limit expressed as number of VSyncs

GR8_returnCode        := $437
GR16_returnDetail     := $438
GR16_origIrqHandler   := $43A
GR16_debugTimerVSyncs := $43C
GR16_debugSpeedSkips  := $43E






;------------------------------------------------------------------------------
; RETURN CODES (set to .A upon exit, optional details in .X and .Y)
;------------------------------------------------------------------------------
RC_SUCCESS                    := 0
RC_UNSUPPORTED_FILE_TYPE      := 1  ; type
RC_UNSUPPORTED_CHUNK_TYPE     := 2  ; type
RC_INVALID_CHUNK_TYPE         := 3  ; type
RC_UNEXPECTED_CHUNK_TYPE      := 4  ; type
RC_READ_ERROR                 := 5  ; lower byte is READST value

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
