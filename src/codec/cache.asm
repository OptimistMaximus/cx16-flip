.export func_cache_read_into_vram
.export func_cache_dupe_into_vram
.export func_cache_init
.export func_cache_load_page
.export smc_anchor_for_cache_size ; for unit test purpose only
.export func_cache_discard_bytes

.import bsod

.segment "CODE"

.include "../include/global.inc"
.include "../include/kernal.inc"
.include "../include/math.inc"
.include "../include/slurp.inc"
.include "../include/video.inc"
.include "../include/vera.inc"

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
; func_cache_discard_bytes
;
; @param .A holds the number of bytes to discard
;
; Note, this is inefficient for large numbers of bytes, but we only do large
; discards rarely (once in the header and once per frame) so for now it is not
; worth fretting over for performance reasons.
;==============================================================================
.proc func_cache_discard_bytes: near
   phx
      tax
   @loop:
      SLURP_INTO_A ; this uses an anonymous label, so we mustn't use too
      dex
      bne @loop
   plx
   rts
.endproc

;==============================================================================
; func_cache_load_page
;
; Load data from input stream into the cache page.  This subroutine is
; intended for use only by subroutines and macros involved in cache management.
; Please don't call it directly.
;
; Since it gets used in various places where calling code might not expect
; .X and .Y to be clobbered, and since it gets called relatively infrequently,
; its implmenetation makes sure to preserve .X and .Y
;
; @effect .X preserved
; @effect .Y preserved
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
       stx ZP8_cacheLoadCount ;    and for convenience the load count
       stz ZP16_cachePointer  ; reset the pointer

      ply
   plx
   rts

;==============================================================================
; func_cache_dupe_into_vram
;
; @param .A is the number of times to duplicate the input stream's next byte
; @effect .X clobbered
; @effect .Y preserved
;==============================================================================
.proc func_cache_dupe_into_vram: near
   tax
   SLURP_INTO_A
:  sta VERA_DATA0
   dex
   bne :-
   rts
.endproc

;==============================================================================
; func_cache_read_into_vram
;
; This reads data from cache and writes it into VRAM using VERA's DATA0.
;
; @param .A holds the number of bytes to transfer
; @effect .X clobbered
; @effect .Y preserved
;
; This has various cycle counts based on how many bytes are requested, and
; how many of them are available in cache already. The branching strategy is
; optimized assuming all bytes are available in cache more often than not.
; This makes lots of small reads faster, at the expense of making some large
; reads slower, though hopefully the performance hit washes out due to the
; efficiencies gained when doing large MACPTR calls.
;
; Note that crude timing tests in the emulator show that MACPTR takes anywhere
;      from 600 to 750 cycles depending on the number of bytes requested.
;==============================================================================
.proc func_cache_read_into_vram: near
   cmp #6                ; if >= 6 then batching is faster
   bcs @batch_is_faster

   tax
@brute_loop:
   SLURP_INTO_A
   sta VERA_DATA0
   dex
   bne @brute_loop
   rts
   
@batch_is_faster:

   sta ZP8_cacheScratch   ; the original request, saved as state
   sec
   lda ZP8_cacheLoadCount
   sbc ZP16_cachePointer
   beq @nothing_remaining

   cmp ZP8_cacheScratch
   bcs @plenty_remaining
   jmp handle_gt_read     ; this guy assumes scratch holds original request
@plenty_remaining:
   jmp handle_lte_read    ; this guy assumes scratch holds original request
@nothing_remaining:
   jsr func_cache_load_page   ; load a fresh page and try again
   lda ZP8_cacheScratch       ; re-establish .A as having the original request
   jmp func_cache_read_into_vram ; i.e. try again
.endproc

;------------------------------------------------------------------------------
; efficient copy when requested number of bytes are in cache
;
; @effect .X clobbered
; @effect .Y preserved
;
; Comments here use the following scenario for illustration purpose. Suppose
; the pointer is presently $588 and someone requested $20 bytes (.A has $20)
; and remaining bytes was $30.
;
; The low byte of the pointer is $88, which acts as our loop index relative
; to the page-aligned cache buffer.  By the time we're done, the pointer
; should be $5A8 ($588+$20) and remaining should be $10 ($30-$20).
;------------------------------------------------------------------------------
.proc handle_lte_read: near
   clc
   lda ZP8_cacheScratch     ; prep .A with the original request
   adc ZP16_cachePointer    ; add pointer's low byte, $20 + $88 = $A8
   sta ZP8_cacheScratch     ; scratch is now the loop max

   ldx ZP16_cachePointer ; pointer low is where to start, e.g. $88
:  lda CONST_cacheAddr,x ; read at offset  e.g. $500 + $55
   sta VERA_DATA0        ; write to VRAM
   inx
   cpx ZP8_cacheScratch  ; see if we hit loop max yet
   bne :-
   stx ZP16_cachePointer ; .Y is $A8 at this point, so make pointer $5A8
   rts
.endproc

;
; Supposing remaining is 5 and requested is 12, we must do a 5 byte read,
; then load a fresh page and try again requesting 7.  Generally speaking,
; if remaining is less than or equal to requested, then do a read for all
; remaining, then adjust the request to reflect that we just read that
; remaining number of bytes, and try again.
;
; @effect .X clobbered
; @effect .Y preserved
.proc handle_gt_read: near

   varRequest = ZP8_cacheScratch ; the original request
   varRemaining = GR8_scratch1

   sec                           ; establish .A has having the bytes
   lda ZP8_cacheLoadCount        ; remaining (i.e. how much we need to
   sbc ZP16_cachePointer         ; drain) and squirrel it in .Y
   sta varRemaining
   ldx ZP16_cachePointer
:  lda CONST_cacheAddr,x
   sta VERA_DATA0
   inx
   cpx ZP8_cacheLoadCount
   bne :-
   stx ZP16_cachePointer         ; .Y is conveniently the end

   sec
   lda varRequest
   sbc varRemaining

   jmp func_cache_read_into_vram ; original request less what we drained
.endproc


