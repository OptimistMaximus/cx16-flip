.ifndef NARF_INC
        NARF_INC = $1

.import func_cache_load_page

;==============================================================================
; NARF_READ_INTO_A
;
; @effect .A holds the next available byte as read from cache
;
; Note that unlike the LDA instruction, the status flags do not reflect what
; byte was just read into the .A buffer.
;==============================================================================
.macro NARF_READ_INTO_A
.scope
   lda ZP8_cacheRemaining
   bne data_is_available
   jsr func_cache_load_page
data_is_available:
   lda (ZP16_cachePointer)
   dec ZP8_cacheRemaining
   inc ZP16_cachePointer
.endscope
.endmacro











.endif
