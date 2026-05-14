.ifndef VIDEO_INC
        VIDEO_INC = 1

.include "./global.inc"
.include "./math.inc"
.include "./vera.inc"

;##############################################################################
; Due to VERA limitations, bitmap "tilebase" must start at an $800 aligned
; address. Part of the rendering trick used by this player is to have two areas
; of VRAM where the image is staged, and we keep flipping between them
; (showing one while staging data into the other)
;
; $00000-$0FFFF will be Stage 0, using $00000-$0F8C0 for a 320x199 image.
; $10000-$1FFFF will be Stage 1, using $10000-$1F8C0 for a 320x199 image.
;
; $0F8C0-$0FDFF in Stage 0 will be unused
; $0FE00-$0FFFF in Stage 0 will be a staging area for the palette
; $1F8C0-$1FFFF in Stage 1 will be untouched, since it spills into special
;                          VERA addresses (e.g. PSG, palette, sprites)
;
; FLI images are 320x200 so we'll parse (but not render) the last line.
;
; Note that the middle and high bytes of both stage addresses are zero.  Only
; the high byte is different.  We'll use this to our advantage in code that
; does math on the addresses. Conveniently the high byte of Stage 0 is 0, and
; the high byte of Stage 1 is 1.  And even more conveniently, the 6502 makes
; it very efficient to detect when a value is zero or not.  So we'll use a
; ZP byte having either a value of $00 or $01 to track which stage is "active".
; It will also act as the high byte of the stage address.
;##############################################################################
PALETTE_BUFFER   := $1F400    ; 256 colors at 2 bytes each

.macro ADVANCE_LINE_FOR_ACTIVE_BUFFERING
   U24_ADD_IMM ZP24_vramOffset, 320
   SET_VERA_ADDR24_VAR $00, ZP24_vramOffset, $10
.endmacro

.macro PREP_BULK_VRAM_COPY targetAddr, sourceAddr
   lda #%00000100                   ; DCSEL=2
   sta VERA_CTRL
   lda #%01100000                   ; Enable Cache Fill & Cache Write
   sta VERA_DC2_FX_CTRL

   SET_VERA_ADDR24_IMM $00, sourceAddr, $10
   SET_VERA_ADDR24_IMM $01, targetAddr, $30
.endmacro

.macro INTERNAL_MACRO_FOR_INNER_BATCH
   lda VERA_DATA0
   lda VERA_DATA0
   lda VERA_DATA0
   lda VERA_DATA0
   stz VERA_DATA1
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

   lda #%00000100                   ; DCSEL=2
   sta VERA_CTRL
   stz VERA_DC2_FX_CTRL             ; Disable Cache Fill & Cache Write
.endmacro

.endif
