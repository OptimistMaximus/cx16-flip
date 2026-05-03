.ifndef VIDEO_INC
        VIDEO_INC = 1

.include "./global.inc"
.include "./math.inc"
.include "./vera.inc"

;##############################################################################
; Logic in this include file knows the secret of how the active layer is
; determined, and how to calculate memory offsets for each layer.  Unit tests
; notwithstanding, only this include file should need such secret information.
;
; ZP8_activeLayer holds either the value $00 or $FA.  When it holds $00 it
; implies that Layer 0 is "active", meaning that's where we should buffer
; the actively-being-processed frame's pixel data.  That is (by design)
; at Layer 0 address $000000. Note, the middle byte matches ZP8_activeLayer.
;
; When ZP8_activeLayer holds $FA it implies that Layer 1 is "active", which
; means we should buffer data to Layer 1's address $00FA00.  Note, the middle
; byte matches ZP8_activeLayer.
;
; Using this convention, we "flip" layers by flipping ZP8_activeLayer between
; $00 and $FA.
;##############################################################################

;==============================================================================
; SET_VRAM_DATA0_FOR_PALETTE_BUFFER
;==============================================================================
.macro SET_VRAM_DATA0_FOR_PALETTE_BUFFER
   SET_VERA_ADDR24_IMM $00, $1F400, $10
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

      
;==============================================================================
; FLIP_LAYERS
;
; If Layer 0 is active, that means we've been buffering to it, so now it is
; time to enable Layer 0, disable Layer 1, and change the active layer value
; so we'll start buffering to to Layer 1 next.  If Layer 1 then essentially do
; the opposite. 
;==============================================================================
.macro FLIP_LAYERS
   lda ZP8_activeLayer
   beq @flip_layers_from_layer_0
      stz ZP8_activeLayer              ; flipping from 1 to 0 ...
      lda #%00100000                   ; sprites off, layer 1 on, layer 0 off
      bra @flip_layers_done
@flip_layers_from_layer_0:          
      U8_COPY_IMM ZP8_activeLayer, $FA ; flip from 0 to 1 ...
      lda #%00010000                   ; sprites off, layer 1 off, layer 0 on
@flip_layers_done:
   stz VERA_CTRL                       ; Establish DCSEL=0
   sta VERA_DC0_VIDEO                  ; apply control settings
.endmacro

.endif
