.export func_cache_init
.export func_cache_load_page

.segment "CODE"

.include "../include/global.inc"
.include "../include/kernal.inc"

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
   lda #>CONST_cacheLowerAddr
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
         SMACPTR CONST_cacheLowerAddr, 128
         lda GR8_cacheStatus
         bne @read_error
         SMACPTR CONST_cacheUpperAddr, 128
@read_error:
      ply
   plx
   rts
.endproc

