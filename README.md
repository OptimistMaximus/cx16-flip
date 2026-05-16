# cx16-flip
FLI Player for Commander X16

## Usage

When the program is run via "RUN" (at the basic prompt) it will look for
a file named IMAGE.FLI in the current working directory.  Then it will
attempt to play that file.

To play a custom filename, use `RUN:REM FOO.FLI` (at the basic prompt)
where FOO.FLI is the name of the file you want to play.

After the FLI animation is done playing, the program will silently await
the user to hit "any key" to continue. After a key is hit, the program
will return to BASIC.

### Caveats and Return Codes

Upon returning to BASIC, it sents the .A register to the return code,
and the .X and .Y registers hold extra details.  You can examine these
via `PRINT PEEK(780)`,  `PRINT PEEK(781)`, and `PRINT PEEK(782)`,
respectively.  The .X and .Y value usually holds the low and high bytes
of a 16-bit detail value.

If the return code wasn't success, the error will be printed to screen
as `ERROR AA [XXYY]`

They are also printed to screen as hex string representation: "AA [XXYY]"

| .A | .A meaning                | .X and .Y meaning                     |
|----|---------------------------|---------------------------------------|
| 0  | success                   | n/a                                   |
| 2  | unsupported file type     | the file type                         |
| 3  | unsupported frame type    | the frame type                        |
| 4  | unsupported chunk type    | the chunk type                        |
| 5  | invalid chunk type        | the chunk type                        |
| 6  | speed too high            | the FLI speed, lower 16-bits only     |


### Version History

- 2026/05/12 Version 0.0.3
  - fixed crash on second running
  - add support for zero length packets (skips within deltas)
  - introduce fast cache writing
  - hide pixelated mess via VSTART/VSTOP
- 2026/05/02 Version 0.0.2
  - basic functionality established
  - pixelated mess shows on-screen
  - ignores "speed" field of header
  - crashes on second running

## IDEAS / TODO

- stream file into VRAM
  - use MACPTR with .A set to 0 and CLC set to not advance, then send data to VRAM.
    MACPTR streams in at most 512 bytes and we have 512 bytes of VRAM unused now.
    ... or maybe just ask for 255 bytes at a time so we have a quick easy 8-bit
    counter to decrement instead of a 16-bit one if we let KERNAL decide.
  - change slurp logic to slurp from VRAM letting auto-inc handle advancement
  - all we need to do is keep track of how many bytes are left from the MACPTR call
    and when the buffer is exhausted, call MACPTR again
  - will this me more efficient than just calling MACPTR a bunch?  Maybe. Less JSRs
    but a lot more fussing with buffer management/loading and keeping track of how
    many bytes left before we need to fill again.  It really depends on how much
    additional overhead there is every time I call MACPTR
- write a delta-specific stage flipper that takes into account the line skip and
  line count ... needn't waste time copying the whole 320x200 as it currently does.
- come up with a more clever way to detect odd byte count of chunk that doesn't
  involve incrementing a counter with every slurp.
  - maybe a look-ahead at the end of the current chunk ... pull in next 6 bytes
    and if bytes at offset 4 and 5 aren't a valid chunk type then it might be that
    there was a padding byte so 4 and 6 are the last byte of the size and the first
    byte of the frame type. That means we need to slurp 1 more byte to get the
    second half of the frame type. Then we can resume from that point.
- make a simpler way to bail out after finding an error while parsing. 







