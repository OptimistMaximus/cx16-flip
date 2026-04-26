.export func_open_inputstream
.export func_close_inputstream

.segment "CODE"

.include "../include/kernal.inc"
.include "../include/global.inc"

FILE_LOGICAL_NUMBER := 1 ; arbitrary logical file number
FILE_DEVICE_FLOPPY  := 8 ; 8 is the "floppy" SD Card
FILE_IO_MODE_READ   := 2 ; 2 means read

; prep:
;   .A length of filename
;   .X low byte of filename addr
;   .Y high byte of filename addr
sub_open_inputstream:

   jsr KERNAL_SETNAM              ; inform kernal of a file that is to be later opened

   lda #FILE_LOGICAL_NUMBER       ; A is the logical file number
   ldx #FILE_DEVICE_FLOPPY        ; X is the device number (8 is the SD card)
   ldy #FILE_IO_MODE_READ         ; Y is the secondary address, for OPEN, 2 means READ
   jsr KERNAL_SETLFS              ; set file parameters

   jsr KERNAL_OPEN                ; opens a channel

   ldx #FILE_LOGICAL_NUMBER       ; X is the logical file number (same value we used for SETLFS)
   jsr KERNAL_CHKIN               ; set channel for character input
   rts



;-----------------------------------------------------------------------------
; open file for streaming (via ACPTR or MACPTR)
;
; param: X holds low byte of addr where the filename exists
; param: Y holds high byte of addr where the filename exists
; clobbers: .Y
;
; the filename should be a null-terminated string, and must include the access
; mode suffix (e.g. "foo.txt,r").
;-----------------------------------------------------------------------------
.proc func_open_inputstream: near
   stx ZP16_VOLATILE_AB+0
   sty ZP16_VOLATILE_AB+1

   ldy #0
@loop:
   lda (ZP16_VOLATILE_AB),y
   beq @loop_done
   iny
   bra @loop
@loop_done:     
   tya
   jsr sub_open_inputstream
   rts
.endproc

;-----------------------------------------------------------------------------
; close file opened via func_open_inputstream
;-----------------------------------------------------------------------------
.proc func_close_inputstream: near
   jsr KERNAL_CLRCHN        ; restore I/O to keyboard and screen
   lda #FILE_LOGICAL_NUMBER ; A is the logical file number
   jmp KERNAL_CLOSE         ; close the file
.endproc

