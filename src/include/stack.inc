.ifndef STACK_INC
        STACK_INC = 1

.macro U16_STORE_XY targetAddr
   stx targetAddr+0
   sty targetAddr+1
.endmacro

.macro U16_LOAD_XY sourceAddr
   ldx sourceAddr+0
   ldy sourceAddr+1
.endmacro

.macro U8_STACK_PUSH sourceAddr
    lda sourceAddr
    pha
.endmacro

.macro U8_STACK_PULL targetAddr
   pla
   sta targetAddr
.endmacro

.macro U16_STACK_PUSH sourceAddr
    lda sourceAddr+1
    pha
    lda sourceAddr+0
    pha
.endmacro

.macro U16_STACK_PULL targetAddr
   pla
   sta targetAddr+0
   pla
   sta targetAddr+1
.endmacro

;==============================================================================
; U16_STACK_PULL_RETURN_ADDR_INTO_INLINED_ARG_ADDR 
;
; This pulls 2 bytes off the stack assuming they are the return address of the
; subroutine you're in. Then it adds 1 to account for the 6502 oddity of how it
; always pushes the return address minus 1. Thus, the resulting address is the
; first byte of whatever was inlined.
;
; @param targetAddr the address of where to store the inlined arg address
; @effect pulls the return address off the stack, causing stack imbalance
;
; For example, if the subroutine was invoked like this:
;
;    JSR do_stuff
;    .word $1234
;    .byte $56
;
; then the target address now holds the address of the word $1234
;==============================================================================
.macro U16_STACK_PULL_RETURN_ADDR_INTO_INLINED_ARG_ADDR targetAddr
   pla                ; pull low byte
   clc                ; clear carry for upcoming add of 1 (which we need to do
   adc #1             ; because the 6502 pushed the return address minus one)
   sta targetAddr+0   ; store low byte
   pla                ; pull high byte
   adc #0             ; add potential carry
   sta targetAddr+1   ; store high byte
.endmacro

;==============================================================================
; U16_STACK_PUSH_RETURN_ADDR_FROM_INLINED_ARG_ADDR
;
; This pushes 2 bytes onto the stack that are the return address as calculated
; from the inlined argument address plus the length of the inlined args. It
; also accounts for the 6502 oddity of how it assumes the pushed address is
; one less than it is, conceptually.
;
; @param sourceAddr  where to find the exact value previously populated by
;                    U16_STACK_PULL_RETURN_ADDR_INTO_INLINED_ARG_ADDR
; @param .Y          the number of bytes that were inlined.
; @effect sourceAddr is clobbered
;
; For example, set .Y to 3 if the subroutine was invoked like this:
;
;    JSR do_stuff
;    .word $1234
;    .byte $56
;
; Or for another example, set .Y to 6 if the subroutine was invoked like this:
;
;    JSR do_stuff
;    .asciiz "hello"
;
;==============================================================================
.macro U16_STACK_PUSH_RETURN_ADDR_FROM_INLINED_ARG_ADDR sourceAddr
   dey                ; subtract 1 now, when it's convenient and efficient
   tya                ;  
   clc                ; clear carry for upcoming add
   adc sourceAddr+0   ; add the low byte of the inlined arg address
   sta sourceAddr+0   ; then squirrel it away for later
   lda sourceAddr+1   ; now load the high byte ...
   adc #0             ; and add the potential carry
   pha                ; push adjusted high byte onto stack
   lda sourceAddr+0
   pha                ; push squirreled adjusted low byte onto stack
.endmacro

.endif