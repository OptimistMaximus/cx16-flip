.export func_open_inputstream
.export func_close_inputstream
.export func_append_access_mode
.import func_strlen

.segment "CODE"

.include "../include/kernal.inc"
.include "../include/global.inc"
.include "../include/math.inc"
.include "../include/petscii.inc"

   FILE_LOGICAL_NUMBER := 1 ; arbitrary logical file number
   FILE_DEVICE_FLOPPY  := 8 ; 8 is the "floppy" SD Card
   FILE_IO_MODE_READ   := 2 ; 2 means read

;==============================================================================
; append access mode to filename
;
; This subroutine assumes it is safe to write two more bytes to the end of the
; supplied filename buffer location.
;
; @param  .A holds the desired access mode, as PETSCII ('w','a','r','m')
; @param  .X holds low byte of addr where the filename exists
; @param  .Y holds high byte of addr where the filename exists
; @effect .A holds the new string length
;==============================================================================
.proc func_append_access_mode: near
   nameAddr = ZP_VOLATILE_PTR
   accessMode = GR8_scratch1

   phy
      stx nameAddr+0
      sty nameAddr+1
      sta accessMode
      ldy #$FF
   @append_access_mode_loop:                  ; this loop advances us to the
      iny                                     ; position of the NULL terminator
      lda (nameAddr),y
      bne @append_access_mode_loop
      lda #PETSCII_COMMA                      ; now append the access mode
      sta (nameAddr),y
      iny
      lda accessMode
      sta (nameAddr),y
      iny
      lda #PETSCII_NULL
      sta (nameAddr),y
      tya
   ply
   rts
.endproc

;==============================================================================
; open file for streaming
;
; @param  .X holds low byte of addr where the filename exists
; @param  .Y holds high byte of addr where the filename exists
;
; the filename must be a null-terminated string, and must include the access
; mode suffix (e.g. "foo.txt,r").
;==============================================================================
.proc func_open_inputstream: near
   jsr func_strlen                ; preps .A for SETNAM
   jsr KERNAL_SETNAM              ; inform kernal of a file that is to be later opened

   lda #FILE_LOGICAL_NUMBER       ; A is the logical file number
   ldx #FILE_DEVICE_FLOPPY        ; X is the device number (8 is the SD card)
   ldy #FILE_IO_MODE_READ         ; Y is the secondary address, for OPEN, 2 means READ
   jsr KERNAL_SETLFS              ; set file parameters

   jsr KERNAL_OPEN                ; opens a channel

   ldx #FILE_LOGICAL_NUMBER       ; X is the logical file number (same value we used for SETLFS)
   jmp KERNAL_CHKIN               ; set channel for character input
.endproc

;==============================================================================
; close file opened via func_open_inputstream
;==============================================================================
.proc func_close_inputstream: near
   jsr KERNAL_CLRCHN        ; restore I/O to keyboard and screen
   lda #FILE_LOGICAL_NUMBER ; A is the logical file number
   jmp KERNAL_CLOSE         ; close the file
.endproc
