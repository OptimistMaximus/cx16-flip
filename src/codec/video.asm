.export func_vera_setup
.export func_vera_restore
.export func_load_palette
.export func_load_image

.import v24_scratch1
.import vram_addr_table_lo
.import vram_addr_table_me
.import vram_addr_table_hi

.segment "CODE"

.include "../include/global.inc"
.include "../include/kernal.inc"
.include "../include/vera.inc"
.include "./video.inc"
.include "../include/zeropage.inc"
.include "./api.inc"

;==============================================================================
; func_vera_setup
;
; Initialize VERA conditions (do this once at startup, after reading and
; validating the header).  We begin with Layer 1 "active", in that that's
; where we buffer the first image, while Layer 0 remains the one being shown
; on-screen
;==============================================================================
.proc func_vera_setup: near

   jsr sub_init_palette

   stz VERA_CTRL                            ; DCSEL=0
   lda #64
   sta VERA_DC0_HSCALE                      ; 640 -> 320
   sta VERA_DC0_VSCALE                      ; 480 -> 240

   lda #%00000111                           ; bitmap mode, 8bpp color
   sta VERA_L0_CONFIG

   stz VERA_L0_TILEBASE                     ; VRAM $00000, W=320
   stz VERA_L0_HSCROLL_L                    ; (unused)
   stz VERA_L0_HSCROLL_H                    ; Palette Offset 0

   U8_COPY_IMM VERA_CTRL,       $02         ; DCSEL=1
   U8_COPY_IMM VERA_DC1_HSTART, (0 >> 2)    ; These next 4 values are
   U8_COPY_IMM VERA_DC1_HSTOP,  (640 >> 2)  ; all based on 640x480
   U8_COPY_IMM VERA_DC1_VSTART, (0 >> 1)    ; regardless of screen mode
   U8_COPY_IMM VERA_DC1_VSTOP,  (400 >> 1)  ; i.e. use 400 for 200

   stz VERA_CTRL                            ; DCSEL=0
   lda #%00010001                           ; enable Layer 0, VGA mode
   sta VERA_DC0_VIDEO

   rts
.endproc

;==============================================================================
; func_vera_restore
;
; Restore VERA to default conditions (do this once before returning to BASIC)
;==============================================================================
.proc func_vera_restore: near
   jmp KERNAL_CINT
.endproc

;==============================================================================
; func_load_palette
;
; This loads the 512 byte palette buffer into VERA's actual palette. Due to a
; quirk of how VERA handles its palette, we can't use the "fast cache write"
; trick for palette transfer.  It should be OK though, since the palette is
; relatively small.
;==============================================================================
.proc func_load_palette: near
   SET_VERA_ADDR24_IMM $00, VRAM_BUFF_PALETTE, $10
   SET_VERA_ADDR24_IMM $01, VERA_ADDR_PALETTE, $10
   ldy #(512 / 8)
@loop:
   lda VERA_DATA0
   sta VERA_DATA1
   lda VERA_DATA0
   sta VERA_DATA1
   lda VERA_DATA0
   sta VERA_DATA1
   lda VERA_DATA0
   sta VERA_DATA1
   lda VERA_DATA0
   sta VERA_DATA1
   lda VERA_DATA0
   sta VERA_DATA1
   lda VERA_DATA0
   sta VERA_DATA1
   lda VERA_DATA0
   sta VERA_DATA1
   dey
   bne @loop
   rts
.endproc

.proc sub_init_palette: near
   SET_VERA_ADDR24_IMM $00, VERA_ADDR_PALETTE, $10
   ldy #(512 / 4)
   lda #0
@loop:
   sta VERA_DATA0
   sta VERA_DATA0
   sta VERA_DATA0
   sta VERA_DATA0
   dey
   bne @loop
   rts
.endproc



;==============================================================================
; func_load_image
;
; @param .X holds line skip
; @param .A holds line count
;
; Since loading an image uses staging as source, where we want to start at
; a line offset, then auto-inc by 1, we can re-use the macro for calculating
; a delta's initial VRAM address.  That macro forces the VERA data channel to
; DATA0, so that's what we'll use as the "source".
;
; The "target" will then be $FA00 less than that, since that's our stage fold.
; We'll do this with bespoke math that sw
;==============================================================================
.proc func_load_image: near

   pha                                 ; squirrel .A line count for later
      SET_VRAM_ADDR_FOR_DELTA_LINE     ; effectively set source (stage)
      SET_VRAM_ADDR_FOR_SCREEN_LINE    ; set target with auto-inc 4
      BATCH_COPY_ENABLE
   plx                                 ; pull line count into .X
@bulk_vram_copy_outer_loop:
   ldy #(320 / 32)                     ; .Y is for columns, batched
@bulk_vram_copy_inner_loop:
   BATCH_COPY
   BATCH_COPY
   BATCH_COPY
   BATCH_COPY
   BATCH_COPY
   BATCH_COPY
   BATCH_COPY
   BATCH_COPY
   dey
   bne @bulk_vram_copy_inner_loop
   dex
   bne @bulk_vram_copy_outer_loop

   BATCH_COPY_DISABLE
   rts
.endproc
