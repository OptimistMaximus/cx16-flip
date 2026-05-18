.ifndef DEBUG_INC
        DEBUG_INC = $1

.import func_print_hex
.import debug_print_istring

; The debug timer assumes your IRQ Handler is incrementing a 16-bit
; value ZP16_vsyncs_total on every VERA interrupt for VSync
 DEBUG_TIMER_ENABLED = 1



.macro DEBUG_PRINT_U8_VAR addr
   pha
      lda addr
      jsr func_print_hex
   pla
.endmacro

.macro DEBUG_PRINT_LABEL label
   pha
      lda #>label ; high
      jsr func_print_hex
      lda #<label ; low
      jsr func_print_hex
   pla
.endmacro

.macro DEBUG_PRINT_U8_IMM value
   pha
      lda #value
      jsr func_print_hex
   pla
.endmacro

.macro DEBUG_PRINT_U16_IMM value
   pha
      lda #>value ; high
      jsr func_print_hex
      lda #<value ; low
      jsr func_print_hex
   pla
.endmacro

.macro DEBUG_PRINT_U16_VAR addr
   pha
      lda addr+1 ; high
      jsr func_print_hex
      lda addr+0 ; low
      jsr func_print_hex
   pla
.endmacro

.macro DEBUG_PRINT_U24_VAR addr
   pha
      lda addr+2 ; bank
      jsr func_print_hex
      lda addr+1 ; high
      jsr func_print_hex
      lda addr+0 ; low
      jsr func_print_hex
   pla
.endmacro

.macro DEBUG_PRINT_U32_VAR addr
   pha
      lda addr+3
      jsr func_print_hex
      lda addr+2
      jsr func_print_hex
      lda addr+1
      jsr func_print_hex
      lda addr+0
      jsr func_print_hex
   pla
.endmacro

.macro DEBUG_PRINT_STRING stringLiteral
   pha
      jsr debug_print_istring
      .asciiz stringLiteral
   pla
.endmacro

.macro DEBUG_PRINT_NEWLINE
   pha
      lda #$0D ; petscii return
      jsr KERNAL_CHROUT
   pla
.endmacro

.macro DEBUG_PRINT_CHAR petscii
   pha
      lda #petscii
      jsr KERNAL_CHROUT
   pla
.endmacro

.macro DEBUG_PRINT_CHAR_A
   pha
      jsr KERNAL_CHROUT
   pla
.endmacro

.macro DEBUG_PRINT_HEX_A
   pha
      jsr func_print_hex
   pla
.endmacro

.macro DEBUG_PRINT_HEX_X
   pha
      phx
         txa
         jsr func_print_hex
      plx
   pla
.endmacro

.macro DEBUG_PRINT_HEX_Y
   pha
      phy
         tya
         jsr func_print_hex
      ply
   pla
.endmacro

.macro DEBUG_TIMER_INCREMENT
.ifdef DEBUG_TIMER_ENABLED
   U16_INC GOLDEN_debugTimerVSyncs
.endif
.endmacro

.macro DEBUG_TIMER_START
.ifdef DEBUG_TIMER_ENABLED
   sei
   U16_STZ GOLDEN_debugTimerVSyncs
   U16_STZ GOLDEN_debugSpeedSkips
   cli
.endif
.endmacro

.macro DEBUG_TIMER_READ destAddr
.ifdef DEBUG_TIMER_ENABLED
   sei
   U16_COPY_VAR destAddr, GOLDEN_debugTimerVSyncs
   cli
.endif
.endmacro

.macro DEBUG_TIMER_DUMP stopAddr
.ifdef DEBUG_TIMER_ENABLED
   DEBUG_PRINT_CHAR PETSCII_RETURN
   DEBUG_PRINT_STRING "elapsed vsyncs: $"
   DEBUG_PRINT_U16_VAR stopAddr
   DEBUG_PRINT_CHAR PETSCII_RETURN
   DEBUG_PRINT_CHAR PETSCII_RETURN
   DEBUG_PRINT_STRING "speed overruns: $"
   DEBUG_PRINT_U16_VAR GOLDEN_debugSpeedSkips
   DEBUG_PRINT_CHAR PETSCII_RETURN
.endif
.endmacro

.macro DEBUG_TIMER_REGISTER_SPEED_VIOLATION
.ifdef DEBUG_TIMER_ENABLED
   U16_INC GOLDEN_debugSpeedSkips
.endif
.endmacro



.endif
