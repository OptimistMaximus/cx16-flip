.export func_cache_init
.export func_cache_read_into_a
.export func_cache_read_into_vram
.export func_cache_dupe_into_vram
.export smc_anchor_for_cache_size ; for unit test purpose only

.import bsod

.segment "CODE"

.include "../include/global.inc"
.include "../include/kernal.inc"
.include "../include/math.inc"
.include "../include/vera.inc"

;==============================================================================
; func_cache_init
;
; Call this once after opening the input stream, and before calling any other
; cache routines. This initializes the current entry pointer's high byte to
; the page boundary of where cache is located, and from there the low byte is
; manipulated, such that it can be used either as a 16-bit pointer or just the
; low byte can be used as an absolute address offset relative to the cache page
;==============================================================================
.proc func_cache_init: near
   lda #>CONST_cacheAddr   ; high byte of actual cache address
   sta ZP16_cachePointer+1 ; stored as high byte of our pointer
   jmp sub_load_page       ; loads page and zeros low byte of pointer
.endproc

;==============================================================================
; func_cache_read_into_a
;
; @effect .A holds the next available byte as read from cache
; @cycles 30 (on cache hit)
;
; Note that unlike the LDA instruction, the status flags do not reflect what
; byte was just read into the .A buffer.  To get the the same effect, calling
; code can use BIT or CMP.
;
; For example, getting the cached equivalent of
;
;   LDA foo
;   BEQ @label
;
; would be
;
;   JSR func_cache_read_into_a
;   CMP #0
;   BEQ @label
;
; which costs an extra 2 cycles, but that's faster overall than having the
; implementation of this subroutine waste 7 cycles on a stack push/pull.  It
; is assumed that calling code would want to save 5 cycles by default.
;==============================================================================
.proc func_cache_read_into_a: near
   lda ZP8_cacheRemaining
   bne :+
   jsr sub_load_page
:  lda (ZP16_cachePointer)
   dec ZP8_cacheRemaining
   inc ZP16_cachePointer
   rts
.endproc

;==============================================================================
; func_cache_dupe_into_vram
;
; @param .A is the number of times to duplicate the input stream's next byte
;==============================================================================
.proc func_cache_dupe_into_vram: near
   phx
      pha
         jsr func_cache_read_into_a
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
   jsr sub_load_page             ; definitely exhausted, so load a fresh page,

   lda varRequest                ; follow-up with a read request for the
   jmp func_cache_read_into_vram ; original request less what we drained
.endproc

; @cycles 26 + whatever MACPTR costs
; note this does NOT use varScratch, so calling logic is safe to call
; this without risk of losing whatever value it might've put into scratch
sub_load_page:
   phx
      phy
         ldx #<CONST_cacheAddr
         ldy #>CONST_cacheAddr
smc_anchor_for_cache_size:    ; (for unit test convenience)
         lda #CONST_cacheSize ; how many bytes we want
         clc                  ; (advance, since going to RAM)
         jsr KERNAL_MACPTR    ; (actually acquire bytes)
         cpx #0               ; if KERNAL gave us zero, something
         bne @read_success    ; something may have gone wrong

         jsr KERNAL_READST    ; ERROR! BSOD, but make sure we don't
         ply                  ; have a stack imbalance upon exist, so in
         plx                  ; this conditional block, pull .Y and .X
         BSOD_A RC_READ_ERROR
      @read_success:
         stx ZP8_cacheRemaining ; also how many bytes remaining
         stx ZP8_cacheLoadCount ; and for convenience the load count
         stz ZP16_cachePointer  ; reset the pointer
      ply
   plx
   rts

