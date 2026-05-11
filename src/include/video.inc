.ifndef VIDEO_INC
        VIDEO_INC = 1

 ENABLE_FAST_CACHE_WRITE = 1

.include "./global.inc"
.include "./math.inc"
.include "./vera.inc"

;##############################################################################
; Due to VERA limitations, bitmap "tilebase" must start at an $800 aligned
; address. Part of the rendering trick used by this player is to have two areas
; of VRAM where the image is staged, and we keep flipping between them
; (showing one while staging data into the other)
;
; $00000-$0F800 will be Stage 0.
; $0F800-$1F000 will be Stage 1.
;
; Thus, each stage can hold a 320x198 image. We'll need to cut corners a bit,
; or rather cut lines. FLI images always seem to be 320x200, so we should cut
; either the first two, the last two, or the first and last.
;
; Ideally we'd do the following:
; Height 200 ($C8) -> skip first and last lines
; Height 199 ($C7) -> skip first line
;                  -> else, don't skip any lines
;
; Note that the low and high bytes of both addresses are always zero.  Only
; the middle byte is different.  We'll use this to our advantage in code that
; does math on the addresses. We only need to care about the middle byte of
; the VRAM offset. It also means we can easily store the state of whic layer
; is active by just storing its middle byte.  A value of $00 means Layer 0
; is active.  The non-zero value means Layer 1 is active.
;
; TODO: consider maybe we can just have a single always-active stage at
; $00000-$12C00 that we just update as we go. MAYBE we can update fast enough
; that it isn't too crappy-looking. Probably not, so this is just a curiosity
; to be explored at a later date.
;##############################################################################
STAGE_0_ADDRESS  := $00000    ; $00000 to $0F7FF is stage 0 (320x198)
STAGE_1_ADDRESS  := $0F800    ; $0F800 to $1EFFF is stage 1 (320x198)
UNUSED_ADDRESS   := $1F000    ; $1F000 to $1F6FF
PALETTE_BUFFER   := $1F400    ; $1F700 to $1F8FF (256 colors at 2 bytes each)

STAGE_0_TILEBASE := %00000000 ; bits 7:2 are bits 16:11 of addr
STAGE_1_TILEBASE := %01111100 ; bits 7:2 are bits 16:11 of addr

STAGE_0_ACTIVE   := $00       ; middle byte of 17-bit address
STAGE_1_ACTIVE   := $F8       ; middle byte of 17-bit address

STAGE_0_ENABLED  := %00010001 ; layer 1 off, layer 0 on, VGA
STAGE_1_ENABLED  := %00100001 ; layer 1 on, layer 0 off, VGA

.macro ADVANCE_LINE_FOR_ACTIVE_BUFFERING
   U24_ADD_IMM ZP24_vramOffset, 320
   SET_VERA_ADDR24_VAR $00, ZP24_vramOffset, $10
.endmacro

.macro PREP_BULK_VRAM_COPY targetAddr, sourceAddr
.ifdef ENABLE_FAST_CACHE_WRITE

   lda #%00000100                   ; DCSEL=2
   sta VERA_CTRL
   lda #%01100000                   ; Enable Cache Fill & Cache Write
   sta VERA_DC2_FX_CTRL

   SET_VERA_ADDR24_IMM $00, sourceAddr, $10
   SET_VERA_ADDR24_IMM $01, targetAddr, $30
.else
   SET_VERA_ADDR24_IMM $00, sourceAddr, $10
   SET_VERA_ADDR24_IMM $01, targetAddr, $10
.endif
.endmacro

.macro INTERNAL_MACRO_FOR_INNER_BATCH
.ifdef ENABLE_FAST_CACHE_WRITE
   lda VERA_DATA0
   lda VERA_DATA0
   lda VERA_DATA0
   lda VERA_DATA0
   stz VERA_DATA1
.else
   lda VERA_DATA0
   sta VERA_DATA1
   lda VERA_DATA0
   sta VERA_DATA1
   lda VERA_DATA0
   sta VERA_DATA1
   lda VERA_DATA0
   sta VERA_DATA1
.endif
.endmacro

; @param outerCount outer loop count
; @param innerCount inner loop count (must be multiple of 16)
.macro EXEC_BULK_VRAM_COPY outerCount, innerCount
   ldx #outerCount
@bulk_vram_copy_outer_loop:
   ldy #(innerCount / 16)
@bulk_vram_copy_inner_loop:
   INTERNAL_MACRO_FOR_INNER_BATCH
   INTERNAL_MACRO_FOR_INNER_BATCH
   INTERNAL_MACRO_FOR_INNER_BATCH
   INTERNAL_MACRO_FOR_INNER_BATCH
   dey
   bne @bulk_vram_copy_inner_loop
   dex
   bne @bulk_vram_copy_outer_loop

.ifdef ENABLE_FAST_CACHE_WRITE
   lda #%00000100                   ; DCSEL=2
   sta VERA_CTRL
   stz VERA_DC2_FX_CTRL             ; Disable Cache Fill & Cache Write
.endif
.endmacro

.endif
