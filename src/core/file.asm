.export func_open_inputstream
.export func_close_inputstream
.export func_load_library

.include "../codec/api.inc"
.include "../include/kernal.inc"
.include "../include/global.inc"
.include "../include/math.inc"
.include "../include/petscii.inc"

.segment "RODATA"
lib_fn: .asciiz "flip.dll,r"
lib_fn_end:

.segment "CODE"

   FILE_LOGICAL_NUMBER := 1 ; arbitrary logical file number
   FILE_DEVICE_FLOPPY  := 8 ; 8 is the "floppy" SD Card
   FILE_IO_MODE_READ   := 2 ; 2 means read

;==============================================================================
; open file for streaming
;
; @param  .A holds the length of the string
; @param  .X holds low byte of addr where the filename exists
; @param  .Y holds high byte of addr where the filename exists
;
; the filename must must include the access mode suffix (e.g. "foo.txt,r").
;==============================================================================
.proc func_open_inputstream: near
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

;==============================================================================
; func_load_library
;
; This optimistically assumes that there will be no I/O error, such that the
; only reason for READST to return non-zero will be end-of-file.
;==============================================================================
varLoadAddr: .word $0000
varReadCount: .word $0000
.proc func_load_library: near
   lda #(lib_fn_end - lib_fn)
   ldx #<lib_fn
   ldy #>lib_fn
   jsr func_open_inputstream
   U16_COPY_IMM varLoadAddr, FLIP_DLL_LOAD_ADDR
@load_loop:
   clc
   lda #0
   ldx varLoadAddr+0
   ldy varLoadAddr+1
   jsr KERNAL_MACPTR                       ; read a chunk of bytes into memory
   stx varReadCount+0
   sty varReadCount+1
   U16_ADD_VAR varLoadAddr, varReadCount   ; update the load addr
   jsr KERNAL_READST                       ; keep reading until "error"
   beq @load_loop
   jmp func_close_inputstream
.endproc


