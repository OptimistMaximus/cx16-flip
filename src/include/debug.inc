.ifndef DEBUG_INC
        DEBUG_INC = $1

.import func_print_hex
.import debug_print_istring

.include "./math.inc"
.include "./math2.inc"

; The debug timer assumes your IRQ Handler is incrementing a 16-bit
; value ZP16_vsyncs_total on every VERA interrupt for VSync
; DEBUG_TIMER_ENABLED = 1

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
   U16_INC GR16_debugTimerVSyncs
.endif
.endmacro

.macro DEBUG_TIMER_START
.ifdef DEBUG_TIMER_ENABLED
   sei
   U16_STZ GR16_debugTimerVSyncs
   U16_STZ GR16_debugSpeedOverrun
   U16_STZ GR16_debugSpeedUnderrun
   cli
.endif
.endmacro

.macro DEBUG_TIMER_READ
.ifdef DEBUG_TIMER_ENABLED
   sei
   U16_COPY_VAR GR16_debugTimerValue, GR16_debugTimerVSyncs
   cli
.endif
.endmacro

.macro DEBUG_TIMER_DUMP
.ifdef DEBUG_TIMER_ENABLED

   DEBUG_PRINT_CHAR PETSCII_RETURN
   DEBUG_PRINT_STRING "elapsed vsyncs:  $"
   DEBUG_PRINT_U16_VAR GR16_debugTimerValue
   DEBUG_PRINT_CHAR PETSCII_RETURN
   DEBUG_PRINT_STRING "total frames:    $"
   DEBUG_PRINT_U16_VAR GR16_frameCount

   ; FPS calculation is 60 frames per 60th of a second
   ; Assuming we don't have any images with more than $C30 (~3000) frames,
   ; we'll divide the frame count and timer by 2 to bring it into $444 range.

   U16_CMP_IMM GR16_frameCount, 445
   bcc @small_enough
   U16_LSR GR16_frameCount
   U16_LSR GR16_debugTimerValue

   U16_CMP_IMM GR16_frameCount, 445
   bcc @small_enough
   U16_LSR GR16_frameCount
   U16_LSR GR16_debugTimerValue

   U16_CMP_IMM GR16_frameCount, 445
   bcc @small_enough
   U16_LSR GR16_frameCount
   U16_LSR GR16_debugTimerValue

@small_enough:
   U8_COPY_IMM GR8_scratch1, 60
   U16_SLOW_MULTIPLY GR16_scratch1, GR16_frameCount, GR8_scratch1
   U16_SLOW_DIVIDE GR16_scratch2, GR16_scratch1, GR16_debugTimerValue

   DEBUG_PRINT_CHAR PETSCII_RETURN
   DEBUG_PRINT_STRING "average fps:     $"
   DEBUG_PRINT_U16_VAR GR16_scratch2
   DEBUG_PRINT_CHAR PETSCII_RETURN
   DEBUG_PRINT_CHAR PETSCII_RETURN
   DEBUG_PRINT_STRING "speed overruns:  $"
   DEBUG_PRINT_U16_VAR GR16_debugSpeedOverrun
   DEBUG_PRINT_CHAR PETSCII_RETURN
   DEBUG_PRINT_STRING "speed underruns: $"
   DEBUG_PRINT_U16_VAR GR16_debugSpeedUnderrun
   DEBUG_PRINT_CHAR PETSCII_RETURN
.endif
.endmacro

.macro DEBUG_TIMER_REGISTER_SPEED_OVERRUN
.ifdef DEBUG_TIMER_ENABLED
   U16_INC GR16_debugSpeedOverrun
.endif
.endmacro

.macro DEBUG_TIMER_REGISTER_SPEED_UNDERRUN
.ifdef DEBUG_TIMER_ENABLED
   U16_INC GR16_debugSpeedUnderrun
.endif
.endmacro

.endif
