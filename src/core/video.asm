.export func_vera_setup
.export func_vera_restore
.export func_vera_flip_stage
.export func_print_hex
.export func_load_palette
.export func_prep_for_active_buffering

.segment "CODE"

.include "../include/global.inc"
.include "../include/kernal.inc"
.include "../include/vera.inc"
.include "../include/video.inc"
.include "../include/zeropage.inc"

;==============================================================================
; print byte as hex text to screen (assuming text mode)
;
; @param:  .A holds the value you want to print to screen
;==============================================================================
.proc func_print_hex: near
   pha               ; push A onto stack
      lsr            ; shift left 4 times, i.e.  A = A >> 4
      lsr            ;  the end result is the high nibble is
      lsr            ;  now in the low nibble
      lsr
      jsr sub_print_hex_nibble
   pla
   and #$0F          ; the end result is the high nibble is gone
   jmp sub_print_hex_nibble ; final jsr optimized to jmp
.endproc

.proc sub_print_hex_nibble: near
   cmp #$0A          ; compare with $0A
   bcs @letter       ; i.e. (A >= 10) then A must be a letter
   ora #$30          ; else it's a digit, convert to PETSCII by adding $30
   bra @print        ; jump ahead to print
@letter:
   clc
   adc #$37          ; convert to PETSCII ... A=$41, B=$42, etc
@print:
   jmp KERNAL_CHROUT ; print whatever's in A
.endproc

;==============================================================================
; func_vera_setup
;
; Initialize VERA conditions (do this once at startup, after reading and
; validating the header).  We begin with Layer 1 "active", in that that's
; where we buffer the first image, while Layer 0 remains the one being shown
; on-screen
;==============================================================================
.proc func_vera_setup: near

   ; is this what's causing a flash-bang?
   stz VERA_CTRL                            ; DCSEL=0
   stz VERA_DC0_VIDEO                       ; disable everything

   U16_STZ CX16_API_R0                      ; use default driver
   jsr KERNAL_GRAPH_INIT

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
   SET_VERA_ADDR24_IMM $00, PALETTE_BUFFER, $10
   SET_VERA_ADDR24_IMM $01, VERA_ADDR_PALETTE, $10
   ldy #(512 / 4)
@loop:
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

;==============================================================================
; PREP_VERA_FOR_ACTIVE_BUFFERING
;
; This is a special optimization to calculate a VRAM offset in 320x240 mode
; where the line number is less than 204. This means the calculated result will
; be within the 16-bit range, so we can save a few cycles due to not worrying
; about the most significant byte (it can be unconditionally forced to zero)
;
; @param  .A the line number (having value 0-197)
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
;
; Also, although it is VERY tempting to make a special optimization for full
; frames (where the line is always zero), we do not have such a macro if only
; because full frames are presumed to be exceedingly rare in a FLI, so from a
; code maintenance standpoint, having a super-special optimization for an
; extremely rare case isn't worth it.
;==============================================================================
.proc func_prep_for_active_buffering
   scratchAddr = ZP_VOLATILE_EF

   sta ZP24_vramOffset+0                     ; .A is now in the 24-bit result
   stz ZP24_vramOffset+1                     ; which is the basis for our
   stz ZP24_vramOffset+2
   U16_ASL ZP24_vramOffset                   ; multiplication optimization
   U16_ASL ZP24_vramOffset
   U16_ASL ZP24_vramOffset
   U16_ASL ZP24_vramOffset
   U16_ASL ZP24_vramOffset
   U16_ASL ZP24_vramOffset
   U16_COPY_VAR scratchAddr, ZP24_vramOffset ; squirrel 6x value
   U16_ASL ZP24_vramOffset
   U16_ASL ZP24_vramOffset
   U16_ADD_VAR ZP24_vramOffset, scratchAddr  ; add in 6x value
   U24_ADD_IMM ZP24_vramOffset, $0FA00       ; shift to after stage fold
   SET_VERA_ADDR24_VAR $00, ZP24_vramOffset, $10
   rts
.endproc

;==============================================================================
; func_vera_flip_stage
;
; If Stage 0 is active, that means we've been buffering to it, so now it is
; time to "show" Stage 0, and change the active Stage value so we'll start
; buffering to to Stage 1 next.  If Layer 1 then essentially do the opposite.
;
; After establishing the new active stage, it is now safe to prime the freshly
; active stage with what the now-shown stage has, so that relative changes to
; it (coming up soon) will build off the same base established by the previous
; active stage.
;
; @effect .X clobbered
; @effect .Y clobbered
;==============================================================================
.proc func_vera_flip_stage: near
   PREP_BULK_VRAM_COPY $00000, $0FA00
   EXEC_BULK_VRAM_COPY 198, 320
   rts
.endproc
