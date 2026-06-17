.ifndef DEBUG_INC
        DEBUG_INC = $1

.import func_print_hex

.include "./global.inc"
.include "./math.inc"
.include "./math2.inc"

; The debug timer assumes your IRQ Handler is incrementing a 16-bit
; value ZP16_vsyncs_total on every VERA interrupt for VSync

.macro DEBUG_PRINT_U8_VAR addr
   lda addr
   jsr func_print_hex
.endmacro

.macro DEBUG_PRINT_U16_VAR addr
   lda addr+1 ; high
   jsr func_print_hex
   lda addr+0 ; low
   jsr func_print_hex
.endmacro

.macro DEBUG_PRINT_NEWLINE
   lda #$0D ; petscii return
   jsr KERNAL_CHROUT
   jsr KERNAL_CHROUT
.endmacro

.macro DEBUG_TIMER_INCREMENT
.ifdef ENABLE_DEBUG_TIMER
   U16_INC GR16_debugTimerVSyncs
.endif
.endmacro

.macro DEBUG_TIMER_START
.ifdef ENABLE_DEBUG_TIMER
   sei
   U16_STZ GR16_debugTimerVSyncs
   U16_STZ GR16_debugSpeedOverrun
   U16_STZ GR16_debugSpeedUnderrun
   stz GR8_biggestChunks
   cli
.endif
.endmacro

.macro DEBUG_TIMER_READ
.ifdef ENABLE_DEBUG_TIMER
   sei
   U16_COPY_VAR GR16_debugTimerValue, GR16_debugTimerVSyncs
   cli
.endif
.endmacro

.macro DEBUG_TIMER_DUMP
.ifdef ENABLE_DEBUG_TIMER

   DEBUG_PRINT_NEWLINE
   DEBUG_PRINT_U16_VAR GR16_frameCount
   DEBUG_PRINT_NEWLINE
   DEBUG_PRINT_U16_VAR GR16_debugTimerValue

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

   DEBUG_PRINT_NEWLINE
   DEBUG_PRINT_U16_VAR GR16_scratch2
   DEBUG_PRINT_NEWLINE
   DEBUG_PRINT_U16_VAR GR16_debugSpeedOverrun
   DEBUG_PRINT_NEWLINE
   DEBUG_PRINT_U16_VAR GR16_debugSpeedUnderrun
   DEBUG_PRINT_NEWLINE
   DEBUG_PRINT_U8_VAR  GR8_biggestChunks
   DEBUG_PRINT_NEWLINE
.endif
.endmacro

.macro DEBUG_TIMER_REGISTER_SPEED_OVERRUN
.ifdef ENABLE_DEBUG_TIMER
   U16_INC GR16_debugSpeedOverrun
.endif
.endmacro

.macro DEBUG_TIMER_REGISTER_SPEED_UNDERRUN
.ifdef ENABLE_DEBUG_TIMER
   U16_INC GR16_debugSpeedUnderrun
.endif
.endmacro

.macro DEBUG_TIMER_REGISTER_BIGGEST_CHUNKS
.ifdef ENABLE_DEBUG_TIMER
   U8_MAX_VAR GR8_biggestChunks, GR8_chunkCount
.endif
.endmacro

.endif
