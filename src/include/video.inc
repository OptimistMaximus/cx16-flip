.ifndef VIDEO_INC
        VIDEO_INC = 1

.include "./global.inc"
.include "./math.inc"
.include "./vera.inc"

;##############################################################################
; Due to VERA limitations, bitmap layers must start at an $800 aligned address.
; Part of the rendering trick used by this player is to have two bitmap layers
; that we keep flipping between (showing one while staging data into the other)
;
; $00000-$0F800 will be Layer 0.
; $0F800-$1F000 will be Layer 1.
;
; Thus, each layer can hold a 320x198 image. We'll need to cut corners a bit,
; or rather cut lines. As a trick for now, the first and last lines of every
; image will be parsed but not rendered to screen.
;
; Ideally we'd do the following:
; Height 200 ($C8) -> skip first and last lines
; Height 199 ($C7) -> skip first line
;                  -> else, don't skip any lines
;
; But for this first release, it will just always skip the first and last.
;
; Note that the low and high bytes of both addresses are always zero.  Only
; the middle byte is different.  We'll use this to our advantage in code that
; does math on the addresses. We only need to care about the middle byte of
; the VRAM offset. It also means we can easily store the state of whic layer
; is active by just storing its middle byte.  A value of $00 means Layer 0
; is active.  The non-zero value means Layer 1 is active.
;
; TODO: consider maybe we can just have a single always-active layer at
; $00000-$12C00 that we just update as we go. MAYBE we can update fast enough
; that it isn't too crappy-looking. Probably not, so this is just a curiosity
; to be explored at a later date.
;##############################################################################
LAYER_0_ADDRESS  := $00000    ; $00000 to $0F7FF is layer 0 (320x198)
LAYER_1_ADDRESS  := $0F800    ; $0F800 to $1EFFF is layer 1 (320x198)
SPRITE_DATA      := $1F200    ; $1F200 to $1F3FF one sprite ( 32x32 )
PALETTE_BUFFER   := $1F400    ; $1F400 to $1F7FF

LAYER_0_TILEBASE := %00000000 ; bits 7:2 are bits 16:11 of addr
LAYER_1_TILEBASE := %01111100 ; bits 7:2 are bits 16:11 of addr

LAYER_0_ACTIVE   := $00       ; middle byte of 17-bit address
LAYER_1_ACTIVE   := $F8       ; middle byte of 17-bit address

LAYER_0_ENABLED  := %01010001 ; sprites on, layer 1 off, layer 0 on, VGA
LAYER_1_ENABLED  := %01100001 ; sprites on, layer 1 on, layer 0 off, VGA

;==============================================================================
; SET_VRAM_DATA0_FOR_PALETTE_BUFFER
;==============================================================================
.macro SET_VRAM_DATA0_FOR_PALETTE_BUFFER
   SET_VERA_ADDR24_IMM $00, PALETTE_BUFFER, $10
.endmacro

;==============================================================================
; CALC_VRAM_OFFSET
;
; This is a special optimization to calculate a VRAM offset in 320x240 mode
; where the line number is less than 204. This means the calculated result will
; be within the 16-bit range, so we can save a few cycles due to not worrying
; about the most significant byte (it can be unconditionally forced to zero)
;
; @param  resultAddr  where to store the 24-bit result
; @param  lineAddr    where the line number is (having value 0-203)
; @param  scratchAddr where it's safe to temporarily store a 16-bit value
;
; The optimization here is to store the line number into the 24-bit result,
; then multiply by 320 by adding the result of the line number multiplied by
; 64 plus the line number multiplied by 256. Multiplying by 64 is just six
; left-shifts, so we'll do that and squirrel away the result into our scratch
; area. Then do two more shifts so that the result now represents the value
; multiplied by 256. Then add in the squirreled away 64x value.
;
; It is tempting to do a quick check for line 0, in which case we can skip all
; the boring shifts and adds, but it is assumed this macro will get called in
; situations where line 0 is as likely to be passed in as any other line. So
; we don't want to incur the 2 or 3 cycle penalty 100% of the time only to
; save some cycles 1/204th of the time.
;==============================================================================
.macro CALC_VRAM_OFFSET_FOR_DELTA resultAddr, lineAddr, scratchAddr
   lda lineAddr
   sta resultAddr+0
   stz resultAddr+1
   stz resultAddr+2
   U16_ASL resultAddr
   U16_ASL resultAddr
   U16_ASL resultAddr
   U16_ASL resultAddr
   U16_ASL resultAddr
   U16_ASL resultAddr
   U16_COPY_VAR scratchAddr, resultAddr
   U16_ASL resultAddr
   U16_ASL resultAddr
   U16_ADD_VAR resultAddr, scratchAddr

   clc                      ; Now add the active layer's bitmap address.
   lda resultAddr+1         ; The lower byte is always zero, so no need to
   adc ZP8_activeLayer      ; add anything. The middle byte is tracked in
   sta resultAddr+1         ; ZP_activeLayer, so we must add it. Then carry
   lda resultAddr+2         ; into the high byte. This is a bit wasteful for
   adc #0                   ; layer 0 but doing this unconditionally keeps
   sta resultAddr+2         ; each layer's processing time consistent.
.endmacro

;==============================================================================
; CALC_VRAM_OFFSET_FOR_FULL
;==============================================================================
.macro CALC_VRAM_OFFSET_FOR_FULL resultAddr
   stz resultAddr+0
   lda ZP8_activeLayer
   sta resultAddr+1
   stz resultAddr+2
.endmacro




.endif
