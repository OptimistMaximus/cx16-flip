.segment "CODE"

.export func_find_arg

.include "../include/global.inc"
.include "../include/kernal.inc"
.include "../include/petscii.inc"


;------------------------------------------------------------------------------
; func_find_arg
;
; This simplistic implementation looks at the BASIC buffer and finds an arg
; based on a single space delimiting the args. If you ran the program like so:
;
;       run:rem foo bar
;
; then arg 0 would be "foo" and arg1 would be "bar"
;
; The implementation is crude and does not tolerate leading spaces, nor
; multiple spaces between arguments. If you have leading spaces or multiple
; spaces between arguments, behavior is undefined.
;
; @param  .A is the argument position wanted
;         .X is the low byte of the target address of where to copy the arg
;         .Y is the high byte of the target address
;
; @effect .C is set if the arg could not be found
;------------------------------------------------------------------------------
.proc func_find_arg: near
   stx ZP_VOLATILE_CD+0                ; squirrel away the target address
   sty ZP_VOLATILE_CD+1
   sta ZP_VOLATILE_A                    ; squirrel away desired arg index
   lda #$FD                              ; establish current index as -3
   sta ZP_VOLATILE_B                    ; (i.e. RUN:REM are args -3, -2, -1)

   ldx #$FF                              ; start at -1 because we INX first
arg_matching_loop:                       ; this is the main loop for matching
   inx
   cpx #KERNAL_BASIC_BUFFER_LEN
   beq arg_matching_done                 ; end of buffer encountered
   lda KERNAL_BASIC_BUFFER,x
   beq arg_matching_done                 ; null terminator encountered
   cmp #PETSCII_SPACE
   beq arg_matching_loop                 ; advance if we're in delimiting space
   lda ZP_VOLATILE_B                    ; we found an arg, so bump the found index
   inc
   sta ZP_VOLATILE_B
   cmp ZP_VOLATILE_A                    ; if it matches the arg we want, we're done
   beq arg_matching_done

arg_skip_loop:                           ; if it didn't match then we fall through
   inx                                   ; ... this is essentially the same code as
   cpx #KERNAL_BASIC_BUFFER_LEN          ; above, but burning through non-space
   beq arg_matching_done                 ; instead of space.  We still need to
   lda KERNAL_BASIC_BUFFER,x             ; bail if NULL or end-of-buffer encounterd
   beq arg_matching_done
   cmp #PETSCII_SPACE
   bne arg_matching_loop
   bra arg_matching_loop

arg_matching_done:

   lda ZP_VOLATILE_B                    ; if we didn't find it, bail
   cmp ZP_VOLATILE_A
   bne done

   dex                                   ; dex to counteract next loop's inx
   ldy #$FF                              ; -1 to accommodate next loop's iny
arg_copy_loop:                           ; now we can continue walking with .X
   iny
   inx                                   ; and copying along the way
   cpx #KERNAL_BASIC_BUFFER_LEN          ; ... making sure to stop in the
   beq arg_copy_done                     ; literal edge case of hitting the
   lda KERNAL_BASIC_BUFFER,x             ; end of the buffer, or the NULL
   beq arg_copy_done                     ; terminator
   cmp #PETSCII_SPACE
   beq arg_copy_done
   sta (ZP_VOLATILE_CD),y
   bra arg_copy_loop
arg_copy_done:

   lda #0                                ; null-terminate our copy
   sta (ZP_VOLATILE_CD),y
   clc                                   ; confirm success
   bra done_success

done:
   sec                                   ; assume failure
done_success:
   rts
.endproc

