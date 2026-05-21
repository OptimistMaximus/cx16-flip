.export func_cache_init
.export func_cache_read_into_a
.export func_cache_read_into_vram
.export func_cache_dupe_into_vram
.export smc_anchor_for_cache_size ; for unit test purpose only

.segment "CODE"

.include "../include/global.inc"
.include "../include/kernal.inc"
.include "../include/math.inc"
.include "../include/vera.inc"

varCacheAddr := GOLDEN_cacheAddr
varPointer   := ZP16_cachePointer
varRemaining := ZP8_cacheRemaining
varScratch   := ZP8_cacheScratch
constReadLen := GOLDEN_cacheSize

;==============================================================================
; func_cache_init
;
; Call this once after opening the input stream, and before calling any other
; cache routines.
;==============================================================================
.proc func_cache_init: near
   lda #>varCacheAddr  ; high byte of actual cache address
   sta varPointer+1    ; stored as high byte of our pointer
   jmp sub_load_page   ; loads page and zeros low byte of pointer
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
; is assumed that calling code knows best why it calls this subroutine and
; would want to save 5 cycles by default.
;
; Note, crude timing tests in the emulator show that ACPTR takes 475 cycles.
; The results are not consistent though, so it is unclear how accurate the
; emulator is with its cycle count value in the lower right corner. Suffice
; it to say, it's a lot slower than 30 cycles that we get on a cache hit
; here.  Similar crude tests with MACPTR show it takes between 600 and 750
; cycles depending on the requested byte count.  So, 100 ACPTR calls would
; cost 47500 cycles, but 1 MACPTR call and 100 cache hits would be 3700 cycles.
;==============================================================================
.proc func_cache_read_into_a: near
   lda varRemaining
   bne :+
   jsr sub_load_page
:  lda (varPointer)
   dec varRemaining
   inc varPointer
   rts
.endproc

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
   cmp varRemaining
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
   pha                         ; squirrel away .A ($20) for later
      clc                      ;
      adc varPointer           ; .A is now $20 + $88 = $A8
      sta varScratch           ; store it in scratch to use as loop max

      phy
         ldy varPointer        ; pointer low is where to start, e.g. $88
      :  lda varCacheAddr,y    ; read at offset  e.g. $500 + $55
         sta VERA_DATA0        ; write to VRAM
         iny
         cpy varScratch
         bne :-
         sty varPointer        ; .Y is $A8 at this point, so make pointer $5A8
      ply
   pla
   sta varScratch              ; we're done using varScratch so it can be
   lda varRemaining            ; repurposed to hold original request ($20)
   sec                         ; and use it to subtract from var remaining
   sbc varScratch              ; e.g. $30 - $20, now .A holds $10
   sta varRemaining            ; and now varRemaining is updated
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
   pha                         ; squirrel requested amount

      lda varRemaining         ; Note, if nothing is remaining, then skip
      sta varScratch           ; over the drain loop. Regardless, we need
      beq @remaining_drained   ; to know the remaining count later to adjust
                               ; the follow-up read, so store in scratch.

      phy
         ldy #0                ; reading to the end is a special case that
      :  lda (varPointer),y    ; can be done more efficiently than the
         sta VERA_DATA0        ; general purpose LTE implementation.
         iny
         cpy varRemaining
         bne :-
      ply

      @remaining_drained:      ; by the time we reach here, the cache is
      jsr sub_load_page        ; definitely exhausted, so load a fresh page,
   pla                         ;
   sec                         ;  .A now holds original request. Subtract
   sbc varScratch              ; the previous remaining to get the new request

   jmp func_cache_read_into_vram ; i.e. try again
.endproc

; @cycles 26 + whatever MACPTR costs
; note this does NOT use varScratch, so calling logic is safe to call
; this without risk of losing whatever value it might've put into scratch
sub_load_page:
   phx
      phy
         ldx #<varCacheAddr
         ldy #>varCacheAddr
smc_anchor_for_cache_size:    ; (for unit test convenience)
         lda #constReadLen    ; how many bytes we want
         clc                  ; (advance, since going to RAM)
         jsr KERNAL_MACPTR    ; (actually acquire bytes)
         stx varRemaining     ; also how many bytes remaining
         stz varPointer       ; reset the pointer
      ply
   plx
   rts

