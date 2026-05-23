.segment "CODE"

.export func_find_arg

.include "../include/global.inc"
.include "../include/kernal.inc"
.include "../include/petscii.inc"

BASIC_BUFFER    := $0200
BASIC_TOKEN_RUN := $8A
BASIC_TOKEN_REM := $8F

;==============================================================================
; func_find_arg
;
; This simplistic implementation looks at the BASIC buffer and finds an arg
; based on a single space delimiting the args. If you ran the program like so:
;
;       run:rem foo bar
;
; then arg 0 would be "foo" and arg1 would be "bar"
;
; @param  .A is the argument position wanted
;         .X is the low byte of the target address of where to copy the arg
;         .Y is the high byte of the target address
;
; @effect .C is set if the arg could not be found
; @effect .X is clobbered
; @effect .Y is clobbered
;==============================================================================
.proc func_find_arg: near
   stx ZP_VOLATILE_CD+0          ; squirrel away the target address
   sty ZP_VOLATILE_CD+1
   sta ZP_VOLATILE_A             ; squirrel away desired arg index
   stz ZP_VOLATILE_B             ; initialize current arg index

   ldx #1                        ; quick check for $8A,$00 which is what it
   lda BASIC_BUFFER,x            ; looks like if someone just did "RUN"
   bne @args_present
   sec                           ; indicate failure
   rts
@args_present:

@preamble_loop:                  ; if we made it here, there should be a
   inx                           ; colon and a REM token with some number of
   lda BASIC_BUFFER,x            ; spaces. We'll advance to the REM token.
   cmp #BASIC_TOKEN_REM
   bne @preamble_loop

@arg_matching_loop:              ; this is the main loop for matching
   inx
   lda BASIC_BUFFER,x
   beq @arg_matching_done        ; null terminator encountered
   cmp #PETSCII_SPACE
   beq @arg_matching_loop        ; advance if we're in delimiting space

   lda ZP_VOLATILE_B             ; if we fall through to here, we're in an
   cmp ZP_VOLATILE_A             ; actual arg. Is it desired?
   beq @arg_matching_done        ; If so, we are done!

   inc                           ; else we fall through here. Take advantage
   sta ZP_VOLATILE_B             ; of .A still holding the current arg index
@arg_skip_undesired_loop:        ; and increment it now. Then burn through
   inx                           ; characters of the current (the ones that
   lda BASIC_BUFFER,x            ; aren't a space) while also taking care to
   beq @arg_matching_done        ; stop short if we hit the end of buffer or
   cmp #PETSCII_SPACE            ; a NULL. As long as it isn't a space, it's
   bne @arg_skip_undesired_loop  ; part of the undesired arg, so keep skipping
   bra @arg_matching_loop        ; now try again in the big loop.
@arg_matching_done:

   lda ZP_VOLATILE_B             ; if we made it here but the current arg is
   cmp ZP_VOLATILE_A             ; not desired, then return with error
   beq @we_got_a_match
   sec
   rts
@we_got_a_match:

   lda BASIC_BUFFER,x            ; follow-up check: a literal edge case is
   bne @not_an_edge_case         ; when we hit the null terminator, which
   sec                           ; means this "matching" arg is effectively
   rts                           ; null, so return with error.
@not_an_edge_case:

   dex                           ; dex to counteract next loop's inx
   ldy #$FF                      ; -1 to accommodate next loop's iny
@arg_copy_loop:                  ; now we can continue walking with .X
   iny                           ; ... we are in the desired arg now!
   inx                           ; So, walk and copy, as long as we have not
   lda BASIC_BUFFER,x            ; yet hit a space, or the null terminator.
   beq @arg_copy_done
   cmp #PETSCII_SPACE
   beq @arg_copy_done
   sta (ZP_VOLATILE_CD),y
   bra @arg_copy_loop
@arg_copy_done:

   lda #0                        ; null-terminate our copy
   sta (ZP_VOLATILE_CD),y
   clc                           ; indicate success
   rts
.endproc

