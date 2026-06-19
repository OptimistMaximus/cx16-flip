.export v24_scratch1
.export v32_scratch1
.export v16_scratch1
.export v16_scratch2
.export v8_scratch1
.export v8_scratch2
.export v8_scratch3

.export v32_chunkSize

.export cache_lower
.export cache_upper

.import func_init_vram_table
.import func_vera_setup
.import func_vera_restore
.import func_cache_init
.import func_slurp_header
.import func_slurp_frame

.ifdef FLIPDLL
.segment "DLL_API"
.else
.segment "CODE"
.endif

;==============================================================================
; PAGE-ALIGNED CACHE
;
; The caching algorithm is optimized to work only in the scenario where the
; the cache is page-aligned.  This is most easily acheived by making sure it
; is the very first thing in the DLL_API segment.  This works perfectly
; because it means the subroutine entry points can be situated immediately
; after, and they will exist in the advertised offsets.
;==============================================================================
cache_lower: .res 128, $00
cache_upper: .res 128, $00

;==============================================================================
; VIDEO DRIVER ENTRY POINTS (9 bytes)
;
; Per the library's public API, the first 9 bytes of the library MUST be these
; three entry points.
;==============================================================================
jmp video_driver_init
jmp video_driver_next
jmp video_driver_done

.include "../include/global.inc"
.include "../include/math.inc"

.ifdef FLIPDLL
.segment "CODE"
.else
.include "./cache.inc"
.endif

;==============================================================================
; VOLATILE SCRATCH VARIABLES
;
; These can be used by any subroutine, but since any subroutine can use them,
; it must be under the assumption that they are "volatile" and their contents
; might change if the subroutine does a JSR or JMP to any other subroutine in
; this library.
;
; Note, the variable labels are exported only for purpose of making them
; available in other assembly files that are part of the FLI Player library.
;==============================================================================
v24_scratch1: .res 3, $24
v32_scratch1: .res 4, $32
v16_scratch1: .res 2, $16
v16_scratch2: .res 2, $16
v8_scratch1:  .res 1, $08
v8_scratch2:  .res 1, $08
v8_scratch3:  .res 1, $08

v32_chunkSize:       .res 4, $32
v16_chunkType:       .res 2, $16
v16_frameIndex:      .res 2, $16
v16_frameCount:      .res 2, $16
v8_chunkIndex:       .res 1, $08
v8_chunkCount:       .res 1, $08
v8_speedLimitVSyncs: .res 1, $08
v8_returnCode:       .res 1, $08
v16_returnDetail:    .res 2, $16
v8_cacheStatus:      .res 1, $08

vram_addr_table_lo:
.byte $00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0
.byte $00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0
.byte $00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0
.byte $00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0
.byte $00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0
.byte $00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0
.byte $00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0
.byte $00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0
.byte $00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0
.byte $00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0

vram_addr_table_me:
.byte $FA,$FB,$FC,$FD,$FF,$00,$01,$02,$04,$05,$06,$07,$09,$0A,$0B,$0C,$0E,$0F,$10,$11
.byte $13,$14,$15,$16,$18,$19,$1A,$1B,$1D,$1E,$1F,$20,$22,$23,$24,$25,$27,$28,$29,$2A
.byte $2C,$2D,$2E,$2F,$31,$32,$33,$34,$36,$37,$38,$39,$3B,$3C,$3D,$3E,$40,$41,$42,$43
.byte $45,$46,$47,$48,$4A,$4B,$4C,$4D,$4F,$50,$51,$52,$54,$55,$56,$57,$59,$5A,$5B,$5C
.byte $5E,$5F,$60,$61,$63,$64,$65,$66,$68,$69,$6A,$6B,$6D,$6E,$6F,$70,$72,$73,$74,$75
.byte $77,$78,$79,$7A,$7C,$7D,$7E,$7F,$81,$82,$83,$84,$86,$87,$88,$89,$8B,$8C,$8D,$8E
.byte $90,$91,$92,$93,$95,$96,$97,$98,$9A,$9B,$9C,$9D,$9F,$A0,$A1,$A2,$A4,$A5,$A6,$A7
.byte $A9,$AA,$AB,$AC,$AE,$AF,$B0,$B1,$B3,$B4,$B5,$B6,$B8,$B9,$BA,$BB,$BD,$BE,$BF,$C0
.byte $C2,$C3,$C4,$C5,$C7,$C8,$C9,$CA,$CC,$CD,$CE,$CF,$D1,$D2,$D3,$D4,$D6,$D7,$D8,$D9
.byte $DB,$DC,$DD,$DE,$E0,$E1,$E2,$E3,$E5,$E6,$E7,$E8,$EA,$EB,$EC,$ED,$EF,$F0,$F1,$F2

; Note that if the library size is too big, we can save 200 bytes at the expense of
; a few more CPU cycles ... we'd just start the image buffer at $FF00 instead of
; $FA00, which means every byte in the high table would be $11 except for Line Zero
; which would be $10.  We could just calculate that with a comparison. It spends
; more cycles than just having this table, but if we need to trim the library by
; 200 bytes, then it is a reasonable compromise.  Note, that would also necessitate
; moving the palette buffer down to $FA00.
vram_addr_table_hi:
.byte $10,$10,$10,$10,$10,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
.byte $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
.byte $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
.byte $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
.byte $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
.byte $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
.byte $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
.byte $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
.byte $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
.byte $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11

.proc video_driver_init: near
   jsr func_init_vram_table
   jsr func_vera_setup
   jsr func_cache_init
   jsr func_slurp_header
   U16_STZ GR16_frameIndex
   lda GR8_returnCode
   ldx GR16_returnDetail+0
   ldy GR16_returnDetail+1
   rts
.endproc

.proc video_driver_next: near
   jsr func_slurp_frame
   lda GR8_returnCode
   beq @success
   sec ; no more frames
   ldx #<GR16_returnDetail
   ldy #>GR16_returnDetail
   rts
@success:
   U16_INC     GR16_frameIndex
   U16_CMP_VAR GR16_frameIndex, GR16_frameCount ; indirectly sets carry bit
   lda #0 ; success
   ldx #0 ; FLI does not support per-frame delay
   ldy #0 ; so we'll hard-code it to zero.
   rts
.endproc

.proc video_driver_done: near
   jmp func_vera_restore
.endproc
