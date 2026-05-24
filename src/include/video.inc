.ifndef VIDEO_INC
        VIDEO_INC = 1

.include "./global.inc"
.include "./math.inc"
.include "./vera.inc"

VRAM_IMAGE        := $00000 ; $00000-$0F9FF 320x200 @ 8bpp
VRAM_BUFF_IMAGE   := $0FA00 ; $0FA00-$1F3FF 320x200 @ 8bpp
VRAM_BUFF_PALETTE := $1F400 ; $1F400-$1F5FF 256 colors at 2 bytes each

.macro ADVANCE_LINE_FOR_ACTIVE_BUFFERING
   U24_ADD_IMM ZP24_vramOffset, 320
   SET_VERA_ADDR24_VAR $00, ZP24_vramOffset, $10
.endmacro

.endif
