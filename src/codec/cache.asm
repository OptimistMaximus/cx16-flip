.export func_cache_read_into_vram
.export func_cache_dupe_into_vram

.import bsod
.import func_cache_load_page

.segment "CODE"

.include "../include/narf.inc"
.include "../include/global.inc"
.include "../include/kernal.inc"
.include "../include/math.inc"
.include "../include/vera.inc"

;==============================================================================
; func_cache_dupe_into_vram
;
; @param .A is the number of times to duplicate the input stream's next byte
;==============================================================================
.proc func_cache_dupe_into_vram: near
   phx
      pha
         NARF_READ_INTO_A
      plx
   :  sta VERA_DATA0
      dex
      bne :-
   plx
   rts
.endproc

;==============================================================================
; func_cache_read_into_vram
;
; This reads data from cache and writes it into VRAM using VERA's DATA0.
;
; @param .A holds the number of bytes to transfer
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
   cmp ZP8_cacheRemaining
   bcs @requested_greater_than_or_equal_to_remaining
   jmp handle_lte_read

@requested_greater_than_or_equal_to_remaining:
   bne @requested_greater_than_remaining
   jmp handle_lte_read

@requested_greater_than_remaining:
   jmp handle_gt_read
.endproc


;------------------------------------------------------------------------------
; efficient copy when requested number of bytes are in cache
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
   tmpLoopMax = GR8_scratch1
   tmpRequest = GR8_scratch2
   
   sta tmpRequest           ; squirrel away .A for later
   clc
   adc ZP16_cachePointer    ; add pointer's low byte, $20 + $88 = $A8
   sta tmpLoopMax           ; which is now the loop max

   phy
      ldy ZP16_cachePointer ; pointer low is where to start, e.g. $88
   :  lda CONST_cacheAddr,y ; read at offset  e.g. $500 + $55
      sta VERA_DATA0        ; write to VRAM
      iny
      cpy tmpLoopMax
      bne :-
      sty ZP16_cachePointer ; .Y is $A8 at this point, so make pointer $5A8
   ply

   sec
   lda ZP8_cacheRemaining   ; now subtract the request from remaining
   sbc tmpRequest           ; to get the new remaining value
   sta ZP8_cacheRemaining
   rts
.endproc

;
; Supposing remaining is 5 and requested is 12, we must do a 5 byte read,
; then load a fresh page and try again requesting 7.  Generally speaking,
; if remaining is less than or equal to requested, then do a read for all
; remaining, then adjust the request to reflect that we just read that
; remaining number of bytes, and try again.
;
.proc handle_gt_read: near
   varRequest = GR8_scratch1

   sec                           ; .A holds the request. After draining what
   sbc ZP8_cacheRemaining        ; remains and loading the next page, we'll
   sta varRequest                ; make a request for the difference

   lda ZP8_cacheRemaining        ; handle rare edge case of nothing remaining
   beq @none_remaining
   
   phy
      ldy ZP16_cachePointer
   :  lda CONST_cacheAddr,y
      sta VERA_DATA0
      iny
      cpy ZP8_cacheLoadCount
      bne :-
   ply
   
@none_remaining:
   phx
      phy
         jsr func_cache_load_page ; definitely exhausted, so load a fresh page,
      ply
   plx

   lda varRequest                ; follow-up with a read request for the
   jmp func_cache_read_into_vram ; original request less what we drained
.endproc


