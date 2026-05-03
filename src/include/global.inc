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
; Any subroutine or macro can use these at any time for any purpose. As such
; never assume that the values persist after you JSR or JMP or call another
; macro.  These are intended for use as quick "scratch" variables.
;
; The memory layout is based on alphabet letters, and the number of alphabet
; letters implies the size (e.g. ABC is 24-bit, EF is 16-bit).  Think of it
; like a "union" in C ... they all overlap according to their alphabet letters.
; If you write to ZP_VOLATILE_ABC you can read the middle byte via ZP_VOLATILE_B
;
; Per the honor system, please never use these in an IRQ handler, because if
; you did, then no logic could ever safely use them!  If you need ZP vars for
; IRQ stuff, declare them in the "STATIC" section.
;------------------------------------------------------------------------------
ZP_VOLATILE_ABCD := $30
ZP_VOLATILE_EFGH := $34
ZP_VOLATILE_IJKL := $38
ZP_VOLATILE_MNOP := $3C

ZP_VOLATILE_ABC  := $30
ZP_VOLATILE_DEF  := $33
ZP_VOLATILE_GHI  := $36
ZP_VOLATILE_JKL  := $39
ZP_VOLATILE_MNO  := $3C

ZP_VOLATILE_AB   := $30
ZP_VOLATILE_CD   := $32
ZP_VOLATILE_EF   := $34
ZP_VOLATILE_GH   := $36
ZP_VOLATILE_IJ   := $38
ZP_VOLATILE_KL   := $3A
ZP_VOLATILE_MN   := $3C
ZP_VOLATILE_OP   := $3E

ZP_VOLATILE_A    := $30
ZP_VOLATILE_B    := $31
ZP_VOLATILE_C    := $32
ZP_VOLATILE_D    := $33
ZP_VOLATILE_E    := $34
ZP_VOLATILE_F    := $35
ZP_VOLATILE_G    := $36
ZP_VOLATILE_H    := $37
ZP_VOLATILE_I    := $38
ZP_VOLATILE_J    := $39
ZP_VOLATILE_K    := $3A
ZP_VOLATILE_L    := $3B
ZP_VOLATILE_M    := $3C
ZP_VOLATILE_N    := $3D
ZP_VOLATILE_O    := $3E
ZP_VOLATILE_P    := $3F

RAM_VOLATILE_BUF := $400 ; $400-$5FF scratch area

VRAM_BITMAP_LAYER_0 := $00000 ; 00000-0F9FF (layer 0, 320x200 pixels)
VRAM_BITMAP_LAYER_1 := $0FA00 ; 0FA00-1F3FF (layer 1, 320x200 pixels)
VRAM_PALETTE_BUFFER := $1F400 ; 1F400-1F7FF (palette staging area)
VRAM_SCRATCH_AREA   := $1F800 ; 1F800-1F9BF (unused)

;------------------------------------------------------------------------------
; GLOBAL "STATIC" VARIABLES
;
; These are bespoke variables whose content shouldn't be meddled with except
; by the subroutines and macros that are associated with them.
;------------------------------------------------------------------------------

ZP8_activeLayer        := $40 ; even means Layer 0, odd means Layer 1
ZP8_height             := $41
ZP8_depth              := $42

ZP16_delaySyncs        := $50
ZP16_width             := $52
ZP16_numFrames         := $54
ZP16_chunkType         := $56
ZP32_chunkSize         := $58
ZP16_currFrame         := $5A
ZP16_numSubChunks      := $5C

RAM16_fileType         := $500


RAM_paletteStagingArea := $600 ; $600-$7FF for staging the palette

;------------------------------------------------------------------------------
; FLI CONSTANTS
;------------------------------------------------------------------------------
FILE_TYPE_FLI   := $AF11
FILE_TYPE_FLC   := $AF12

FRAME_TYPE      := $F1FA

CHUNK_COLOR_256 := $0004 ; FLI palette info, RGB values from 0-255
CHUNK_COLOR_64  := $000B ; FLI palette info, RGB values from 0-63
CHUNK_DELTA_FLI := $000C ; FLI compressed via deltas
CHUNK_BLACK     := $000D ; FLI all pixels implicitly color zero)
CHUNK_BYTE_RUN  := $000F ; FLI byte run
CHUNK_FLI_COPY  := $0010 ; FLI uncompressed

;------------------------------------------------------------------------------
; SYMBOLS
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; RETURN CODES (set to .A upon exit, optional details in .X and .Y)
;------------------------------------------------------------------------------
RC_SUCCESS                    := 0
RC_CANNOT_OPEN_FILE           := 1  ; .X is CHKIN status, .Y is OPEN status
RC_UNSUPPORTED_FILE_TYPE      := 2  ; type
RC_UNSUPPORTED_FRAME_TYPE     := 3  ; type
RC_UNSUPPORTED_CHUNK_TYPE     := 4  ; type
RC_WIDTH_TOO_BIG              := 5  ; width
RC_HEIGHT_TOO_BIG             := 6  ; height
RC_DEPTH_TOO_BIG              := 7  ; depth
RC_SPEED_TOO_HIGH             := 8  ; FLI speed, lower half of 32-bit value
RC_DELAY_TOO_LONG             := 9  ; FLC delay
RC_INVALID_CHUNK_TYPE         := 10 ; type


;==============================================================================
; RTS_VAR16_DETAIL
;
; This macro establishes a semantic convention where a subroutine can return
; with .A holding a return code (see above) and .X and .Y holding detail.
;
; Note that as part of this macro's contract, it sets .A as the very last
; action. So, callers can do a quick BEQ or BNE to detect success or failure.
;==============================================================================
.macro RTS_VAR16_DETAIL rc, detailAddr
   ldx detailAddr+0
   ldy detailAddr+1
   lda #rc
   rts
.endmacro

;==============================================================================
; RTS_NO_DETAIL
;
; This macro is exactly the same as RTS_VAR16_DETAIL, except it forces the
; .X and .Y values to zero.
;==============================================================================
.macro RTS_NO_DETAIL rc
   ldx #0
   ldy #0
   lda #rc
   rts
.endmacro

;==============================================================================
; ESTABLISH_VERA_ADDRESS
;
; If Layer 0 is active then we should stage data into Layer 1
; Otherwise (i.e. Layer 1 is active) we fall through and stage to Layer 0 
;==============================================================================
.macro ESTABLISH_VERA_ADDRESS
.scope
   lda ZP8_activeLayer
   beq @handle_layer_0_active
      SET_VERA_ADDR24_IMM $00, VRAM_BITMAP_LAYER_0, $10
      bra @handle_layer_done
@handle_layer_0_active:
      SET_VERA_ADDR24_IMM $00, VRAM_BITMAP_LAYER_1, $10
@handle_layer_done:
.endscope
.endmacro

;==============================================================================
; FLIP_LAYERS
;
; If Layer 0 is active then make it inactive and make Layer 1 active, by 
; setting VERA_CTRL, where b6 is sprites, b5 is Layer 1, b4 is Layer 0.
;==============================================================================
.macro FLIP_LAYERS
.scope
   lda ZP8_activeLayer
   beq @handle_layer_0_active
      dec ZP8_activeLayer       ; it was $01, so change it to $00
      lda #%00010000            ; sprites off, layer 1 off, layer 0 on
      bra @handle_layer_done
@handle_layer_0_active:
      inc ZP8_activeLayer       ; it was $00, so change it to $01
      lda #%00100000            ; sprites off, layer 1 on, layer 0 off
@handle_layer_done:
   stz VERA_CTRL                ; Establish DCSEL=0
   sta VERA_DC0_VIDEO           ; apply control settings
.endscope
.endmacro

.endif
