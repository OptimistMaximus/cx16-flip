.ifndef ZEROPAGE_INC
        ZEROPAGE_INC = 1

;------------------------------------------------------------------------------
; ZERO PAGE
;
; $00           RAM Bank   0     reserved for KERNAL/CBDOS vars & buffers
;                          1-255 available to user (assuming phys mem exists)
;
; $01           ROM Bank   0  KERNAL   KERNAL operating system & drivers
;                          1  KEYBD    Keyboard layout tables
;                          2  CBDOS    CBM-DOS for FAT32 SD Cards
;                          3  GEOS     GEOS KERNAL
;                          4  BASIC    BASIC interpreter
;                          5  MONITOR  Machine Language Monitor
;                          6  CHARSET  PETSCII and ISO charsets
;                          7  CODEX    CodeX16 Interactive ASM Environment
;                          8  GRAPH    Kernal graph and font routines
;
; $02-$21 	16 bit registers r0-r15 for KERNAL API
; $22-$7F 	Available to the user
; $80-$9C 	Used by KERNAL and DOS
; $9D-$A8 	Reserved for DOS/BASIC
; $A9-$D3 	Used by the Math library (and BASIC)
; $D4-$FF 	Used by BASIC
;------------------------------------------------------------------------------

CX16_RAM_BANK := $00
CX16_ROM_BANK := $01

;------------------------------------------------------------------------------
; CX16 API pseudo-registers
;------------------------------------------------------------------------------
CX16_API_R0   := $02
CX16_API_R1   := $04
CX16_API_R2   := $06
CX16_API_R3   := $08
CX16_API_R4   := $0A
CX16_API_R5   := $0C
CX16_API_R6   := $0E
CX16_API_R7   := $10
CX16_API_R8   := $12
CX16_API_R9   := $14
CX16_API_R10  := $16
CX16_API_R11  := $18
CX16_API_R12  := $1A
CX16_API_R13  := $1C
CX16_API_R14  := $1E
CX16_API_R15  := $20

.endif
