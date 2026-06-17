.export func_cache_init
.export func_cache_load_page
.export func_cache_read_into_vram

.ifdef FLIPDLL
.import cache_lower
.import cache_upper
.else
cache_lower = $7100    ; special hack to facilitate testing!
cache_upper = $7180
.endif

.segment "CODE"

.include "../include/global.inc"
.include "../include/kernal.inc"
.include "../include/math.inc"
.include "../include/vera.inc"

; @param targetAddr where to write the result
; @param count how many bytes to request
; @effect ZP8_cacheStatus holds status (0=success, else failure)
;
; Note, status update is conditional, so calling code should do LDA
;       or similar to check it, instead of assuming status flags hold
;       info (since on success it is never touched)
.macro SMACPTR targetAddr, count
   ldx #<targetAddr
   ldy #>targetAddr
   lda #count
   clc ; advance
   jsr KERNAL_MACPTR
   jsr KERNAL_READST
   sta GR8_cacheStatus
.endmacro

;==============================================================================
; func_cache_init
;
; Call this once either before or after opening a fresh input stream, but
; before accessing any data via the cache macros. Once you start reading via
; the cache routines, don't use any direct kernal calls to read anything.
;==============================================================================
.proc func_cache_init: near
   lda #$FF
   sta ZP16_cachePointer+0
   lda #>cache_lower
   sta ZP16_cachePointer+1
   stz GR8_cacheStatus
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
; @effect ZP8_cacheStatus holds status (0=success, else failure)
;
; Note, the cache loading is "greedy" and has no concept of how many bytes have
; been read already, nor how many are still available. It just tries to read
; unconditionally.  In theory, the calling code will never ask for a byte that
; isn't logically justified by the file's encoded content.  So, it should
; never attempt to read from cache the bad/random bytes that would be there
; as we spill over the end of the file.
;
; The status byte is a courtesy and provides a modicum of support for detecting
; problems. If we checked the status after every read we'd kill performance.
; If we don't check the status after every read, we risk processing garbage
; bytes.  The compromise is to be optimistic and assume there are never any
; I/O errors ever, and the only reason why we'd get a read status failure is
; when asked to read beyond the end of the file, which should be fine because
; even though we'll DEFINITELY do that (per the greedy loader), the calling
; logic should never ask for bytes beyond the end of the file.
;==============================================================================
.proc func_cache_load_page: near
   phx
      phy
         lda GR8_cacheStatus
         bne @read_error
         SMACPTR cache_lower, 128
         lda GR8_cacheStatus
         bne @read_error
         SMACPTR cache_upper, 128
@read_error:
      ply
   plx
   rts
.endproc

;------------------------------------------------------------------------------
; func_cache_read_into_vram
;
; @param .A holds the requested amount of bytes
;
; Note that the cache trick involves incrementing FIRST and then reading, so
; we need to take that into account when doing a bulk read.
;------------------------------------------------------------------------------
.proc func_cache_read_into_vram: near
   sta ZP8_cacheRequest
   lda ZP16_cachePointer          ; increment pointer with side-effect of
   inc                            ; leaving the incremented value in .A
   sta ZP16_cachePointer          ; (needed in normal non-edge scenario)
   beq @edge_case_rollover        ; handle literal edge case of rollover

   TWOS_COMPLIMENT_A              ; .A still holds cache pointer, and two's
   cmp ZP8_cacheRequest           ; compliment is conveniently bytes remaining
   bcs @request_gte
   jmp sub_handle_remaining_lt
@request_gte:
   jmp sub_handle_remaining_gte

@edge_case_rollover:              ; we get here if we just rolled over, which
   jsr func_cache_load_page       ; means we need to load in a fresh page, in
   jmp sub_handle_remaining_gte   ; which case there's now enough remaining.

.endproc

;------------------------------------------------------------------------------
; sub_handle_remaining_lt
;
; @param ZP8_cacheRequest set to the number of bytes to read
; @param .A the number of bytes remaining in cache
;
; This gets called when there aren't enough remaining bytes to satisfy the
; request.  For example, the pointer is at $F0 (so there's only $10 bytes left)
; and the request is for $30. The basic idea is to drain the remaining bytes
; and then load in a fresh cache page and call the subroutine to handle
; "less than" requests.  We can be 100% sure that the follow-up request will
; be for less than because the FLI format can only request runs of up to $7E
; and our cache is 256 bytes.
;------------------------------------------------------------------------------
.proc sub_handle_remaining_lt: near
   varRemaining = GR8_scratch1

   sta varRemaining
   sec                      ; the new request will be the original request
   lda ZP8_cacheRequest     ; less the remaining amount
   sbc varRemaining
   sta ZP8_cacheRequest

   ldx ZP16_cachePointer
@loop:
   lda cache_lower,x
   sta VERA_DATA0
   inx
   bne @loop

   ; at this point, .X is zero and we've drained the current cache page,
   ; so we'll load a fresh one.
   stx ZP16_cachePointer
   jsr func_cache_load_page
   jmp sub_handle_remaining_gte
.endproc

;------------------------------------------------------------------------------
; sub_handle_remaining_gte
;
; @param ZP8_cacheRequest set to the number of bytes to read
; @param .A the number of bytes remaining in cache
;
; This gets called when there are enough remaining bytes to satisfy the
; request.  For example, the pointer is at $10 (so there's $F0 bytes left)
; and the request is for $20.  This method is only called by the calling code
; when it knows there's enough space. So, all we need to do is iterate from
; the current pointer to the current pointer plus the request.  When we're
; done, the end point is essentially the new pointer value.
;------------------------------------------------------------------------------
.proc sub_handle_remaining_gte: near
   clc
   lda ZP16_cachePointer
   tax                      ; save a cycle and squirrel into .X now
   adc ZP8_cacheRequest
   sta ZP8_cacheStop
@loop:
   lda cache_lower,x
   sta VERA_DATA0
   inx
   cpx ZP8_cacheStop
   bne @loop
   dex                      ; decrement here since we overshot, above
   stx ZP16_cachePointer
   rts
.endproc
