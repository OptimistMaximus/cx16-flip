.ifndef KERNAL_INC
        KERNAL_INC = 1

KERNAL_IRQ_VECTOR         := $0314
KERNAL_BRK_VECTOR         := $0316
KERNAL_NMI_VECTOR         := $0318
KERNAL_IOPEN_VECTOR       := $031A
KERNAL_ICLOSE_VECTOR      := $031C

;------------------------------------------------------------------------------
; Memory Banks ... RAM Bank 0 is reserved for KERNAL use
;------------------------------------------------------------------------------
SYSTEM_RAM_SELECTOR_ADDR  := $00
SYSTEM_ROM_SELECTOR_ADDR  := $01

SYSTEM_ROM_BANK_KERNAL    := 0  ; KERNAL operating system and drivers
SYSTEM_ROM_BANK_KEYBD     := 1  ; Keyboard layout tables
SYSTEM_ROM_BANK_CMDRDOS   := 2  ; The computer-based CMDR-DOS for FAT32 SD cards
SYSTEM_ROM_BANK_FAT32     := 3  ; The FAT32 driver itself
SYSTEM_ROM_BANK_BASIC     := 4  ; BASIC interpreter
SYSTEM_ROM_BANK_MONITOR   := 5  ; Machine Language Monitor
SYSTEM_ROM_BANK_CHARSET   := 6  ; PETSCII and ISO character sets (uploaded into VRAM)
SYSTEM_ROM_BANK_DIAG      := 7  ; Memory diagnostic
SYSTEM_ROM_BANK_GRAPH     := 8  ; Kernal graph and font routines
SYSTEM_ROM_BANK_DEMO      := 9  ; Demo routines
SYSTEM_ROM_BANK_AUDIO     := 10 ; Audio API routines
SYSTEM_ROM_BANK_UTIL      := 11 ; System Configuration (Date/Time, Display Preferences)
SYSTEM_ROM_BANK_BANNEX    := 12 ; BASIC Annex (code for some added BASIC functions)
SYSTEM_ROM_BANK_X16EDIT_A := 13 ; The built-in text editor (part 1 of 2)
SYSTEM_ROM_BANK_X16EDIT_B := 14 ; The built-in text editor (part 2 of 2)
SYSTEM_ROM_BANK_BASLOAD   := 15 ; A transpiler that converts BASLOAD dialect to BASIC V2

SYSTEM_RAM_BANK_ADDR      := $A000 ; [A000-BFFF]
SYSTEM_ROM_BANK_ADDR      := $C000 ; [C000-FFFF]

.macro SWITCH_RAM_BANK_IMM bankNumber
   lda #bankNumber
   sta SYSTEM_RAM_SELECTOR_ADDR
.endmacro

.macro SWITCH_RAM_BANK_VAR bankNumberAddr
   lda bankNumberAddr
   sta SYSTEM_RAM_SELECTOR_ADDR
.endmacro

.macro SWITCH_RAM_BANK_NEXT
   inc SYSTEM_RAM_SELECTOR_ADDR ; whatever the current bank is, advance it
.endmacro

.macro SWITCH_ROM_BANK bankNumber
   lda #bankNumber
   sta SYSTEM_ROM_SELECTOR_ADDR
.endmacro

;------------------------------------------------------------------------------
; Channel I/O
;------------------------------------------------------------------------------

KERNAL_GET_CLOCK  := $FF50  ; Get system date and time

KERNAL_GETIN      := $FFE4  ; Get character from keyboard
KERNAL_MACPTR     := $FF44  ; Read multiple bytes from the peripheral bus
KERNAL_ACPTR      := $FFA5  ; Read single byte from the peripheral bus

KERNAL_CINT       := $FF81  ; Restore VERA to original settings

KERNAL_READST     := $FFB7  ; Read Status Word
KERNAL_SETLFS     := $FFBA  ; Set logical file parameters
KERNAL_SETNAM     := $FFBD  ; Set logical file name
KERNAL_OPEN       := $FFC0  ; Open a logical file
KERNAL_CLOSE      := $FFC3  ; Close a logical file
KERNAL_CHKIN      := $FFC6  ; Set file to be used for character input
KERNAL_CLRCHN     := $FFCC  ; Clear Channel (set I/O back to keyboard & screen)
KERNAL_CHROUT     := $FFD2  ; Write a character to the default output device

;------------------------------------------------------------------------------
; VERA FX Graphics
;------------------------------------------------------------------------------

KERNAL_GRAPH_INIT          := $FF20 ; initialize graphics
KERNAL_GRAPH_CLEAR         := $FF23 ; clear screen
KERNAL_GRAPH_SET_WINDOW    := $FF26 ; set clipping region
KERNAL_GRAPH_SET_COLORS    := $FF29 ; set stroke, fill and background colors
KERNAL_GRAPH_DRAW_LINE     := $FF2C ; draw a line
KERNAL_GRAPH_DRAW_RECT     := $FF2F ; draw a rectangle (optionally filled)
KERNAL_GRAPH_MOVE_PIXELS   := $FF32 ; move pixels
KERNAL_GRAPH_DRAW_OVAL     := $FF35 ; draw an oval or circle
KERNAL_GRAPH_DRAW_IMAGE    := $FF38 ; draw a rectangular image
KERNAL_GRAPH_SET_FONT      := $FF3B ; set the current font
KERNAL_GRAPH_GET_CHAR_SIZE := $FF3E ; get size and baseline of a character
KERNAL_GRAPH_PUT_CHAR      := $FF41 ; print a character

;------------------------------------------------------------------------------
; BASIC Params ... poke here (from Basic) before invoking a program, the value
;                  will be prepped into the associated register/flags before
;                  the program is executed
;              ... after the program returns, these same memory locations will
;                  be populated with the register/flag values at time of RTS
;------------------------------------------------------------------------------

BASIC_ARG_A       := $030C  ; Accumulator
BASIC_ARG_X       := $030D  ; X Register
BASIC_ARG_Y       := $030E  ; Y Register
BASIC_ARG_P       := $030F  ; Status Flags

;------------------------------------------------------------------------------
; VIA Timers (comments with | convey context of Write vs Read)
;
; Auxiliary Control Register Format:
;     b7,b7 = Timer Control          00 Timed Interrupt each time T is loaded
;                                    01 Continuous Interrupts
;                                    10 Timed interrupt each time T1 is loaded
;                                       (One shot output)
;                                    11 Continuous interrupts
;                                       (square wave output)
;
; Note, IER bit 7 determines what the other bits mean.
;       b7 1 means when other bits are 1, those things should be "set"
;              and when other bits are 0, those things should be left alone
;       b7 0 means when other bits are 1, those things should be "cleared"
;              and when other bits are 0, those things should be left alone
;
; Note, IFR bit 7 is a "summary" or "FYI" bit (not sure what it means)
;       and all the other bits are always "1 means clear, 0 means leave alone"
;------------------------------------------------------------------------------
VIA1_RB           := $9F00   ; Output Register B         | Input Register B
VIA1_RA           := $9F01   ; Output Register A         | Input Register A
VIA1_DDRB         := $9F02   ; Data Direction Register B
VIA1_DDRA         := $9F03   ; Data Direction Register A
VIA1_T1C_L        := $9F04   ; T1 Low-Order Latches      | T1 Low-Order Counter
VIA1_T1C_H        := $9F05   ; T1 High-Order Counter     | T1 High-Order Counter
VIA1_T1L_L        := $9F06   ; T1 Low-Order Latches
VIA1_T1L_H        := $9F07   ; T1 High-Order Latches
VIA1_T2C_L        := $9F08   ; T2 Low-Order Latches      | T2 Low-Order Counter
VIA1_T2C_H        := $9F09   ; T2 High-Order Counter     | T2 High-Order Counter
VIA1_SR           := $9F0A   ; Shift Register
VIA1_ACR          := $9F0B   ; Auxiliary Control Register
VIA1_PCR          := $9F0C   ; Peripheral Control Register
VIA1_IFR          := $9F0D   ; Interrupt Flag Register (W1C semantics)
                             ;   b7 IRQ set/clear (read only summary flag)
                             ;   b6 Timer 1
                             ;   b5 Timer 2
                             ;   b4 CB1
                             ;   b3 CB2
                             ;   b2 Shift Register
                             ;   b1 CA1
                             ;   b0 CA2
VIA1_IER          := $9F0E   ; Interrupt Enable Register (Command Semantics)
                             ;   b7 IRQ set/clear (command bit controlling other bits)
                             ;   b6 Timer 1
                             ;   b5 Timer 2
                             ;   b4 CB1
                             ;   b3 CB2
                             ;   b2 Shift Register
                             ;   b1 CA1
                             ;   b0 CA2
VIA1_RA_NO_HS     := $9F0F   ; Same as Register A except no "Handshake"

VIA2_RB           := $9F10   ; Output Register B         | Input Register B
VIA2_RA           := $9F11   ; Output Register A         | Input Register A
VIA2_DDRB         := $9F12   ; Data Direction Register B
VIA2_DDRA         := $9F13   ; Data Direction Register A
VIA2_T1C_L        := $9F14   ; T1 Low-Order Latches      | T1 Low-Order Counter
VIA2_T1C_H        := $9F15   ; T1 High-Order Counter
VIA2_T1L_L        := $9F16   ; T1 Low-Order Latches
VIA2_T1L_H        := $9F17   ; T1 High-Order Latches
VIA2_T2C_L        := $9F18   ; T2 Low-Order Latches      | T2 Low-Order Counter
VIA2_T2C_H        := $9F19   ; T2 High-Order Counter
VIA2_SR           := $9F1A   ; Shift Register
VIA2_ACR          := $9F1B   ; Auxiliary Control Register
VIA2_PCR          := $9F1C   ; Peripheral Control Register
VIA2_IFR          := $9F1D   ; Interrupt Flag Register
VIA2_IER          := $9F1E   ; Interrupt Enable Register
VIA2_RA_NO_HS     := $9F1F   ; Same as Register A except no "Handshake"


.endif