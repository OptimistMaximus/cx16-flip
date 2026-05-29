.export func_cache_init
.export func_cache_load_page
.export smc_anchor_for_cache_size ; for unit test purpose only

.import bsod

.segment "CODE"

.include "../include/global.inc"
.include "../include/kernal.inc"

;==============================================================================
; func_cache_init
;
; Call this once just after opening a fresh input stream, and before accessing
; any data in it. To keep consistent, only access the input stream through the
; macros in this file, instead of accessing directly with KERNAL routines.
;==============================================================================
.proc func_cache_init: near
   lda #>CONST_cacheAddr   ; high byte of actual cache address
   sta ZP16_cachePointer+1 ; stored as high byte of our pointer
   jmp func_cache_load_page
.endproc


;==============================================================================
; func_cache_load_page
;
; Load data from input stream into the cache page.  This subroutine is
; intended for use only by subroutines and macros involved in cache management.
; Please don't call it directly.
;
; @effect .X clobbered
; @effect .Y clobbered
;==============================================================================
func_cache_load_page:
   phx
      phy
      
         ldx #<CONST_cacheAddr
         ldy #>CONST_cacheAddr
smc_anchor_for_cache_size:
         lda #CONST_cacheSize   ; how many bytes we want
         clc                    ; (advance, since going to RAM)
         jsr KERNAL_MACPTR      ; (actually acquire bytes)

         cpx #0                 ; .X is number of bytes actually read
         bne @read_success      ; (non-zero means we read something)
         jsr KERNAL_READST      ; if read status zero (i.e. no error) then
         beq @read_success      ; it seems this was a transient issue.
         ply                    ; else fall through and bail out
         plx                    ; (making sure to balance the stack first)
         BSOD_A RC_READ_ERROR

@read_success:
       stx ZP8_cacheRemaining ; .X (bytes read) is now bytes remaining
       stx ZP8_cacheLoadCount ;    and for convenience the load count
       stz ZP16_cachePointer  ; reset the pointer

      ply
   plx
   rts
