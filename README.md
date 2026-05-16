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
will return to BASIC, with the program still loaded.

## Caveats

This assumes the "speed" (i.e. the delay between frames) is less than
2293 units, where FLI measures speed in seventieths of a second.  That
equates to about 32 seconds.  It should be reasonable, and the reason is
to keep the implementation's delay math simple and within the 16-bit range.

This implementation only supports the FLI format. It does not FLC files.

### Error Codes

If something goes wrong at runtime, it will attempt to switch to text mode,
then will display 2 values on screen. The first is an 8-bit error code, 
and the second is a 16-bit "detail" value.

The it waits for you to press "any key" to continue, after which it soft
resets to BASIC (effectively unloading the program).

| Code | Meaning                   | Detail                                |
|------|---------------------------|---------------------------------------|
| 2    | unsupported file type     | the file type                         |
| 3    | unsupported frame type    | the frame type                        |
| 4    | unsupported chunk type    | the chunk type                        |
| 5    | invalid chunk type        | the chunk type                        |
| 6    | speed too high            | the FLI speed, lower 16-bits only     |


### Version History

- 2026/05/16 Version 0.0.5
  - fixed random band of color at bottom of image

- 2026/05/16 Version 0.0.4
  - plays all frames in the file now (rather than stopping after the frame count found in the header)
  - changed the way errors are handled (see "Error Codes" section above)
  - lots of experimental code and refactoring and minor bug fixes
  - performance still poor, since the focus is still on functionality, not optimization
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

## HOW TO BUILD

The assembly files are written for the cc65 assembler.

Assuming you have a Bourne like shell, and the necessary binaries are resolvable by your PATH (make, cl65, ar65, x16emu) you should be able to just type "make run" and have it compile then launch in the emulator.

The Makefile is a bit clunky, but hopefully isn't too hard to follow. The main targets are
- run (to run the main program)
- test (to run the test suite)
- debug (to run the main program in debug mode)
- clean (to clean)

 
## KNOWN BUGS

- crashes or wonky colors on subsequent runs
- sometimes screen goes wonky, probably due to time lag between loading the next color palette and showing the next image.  The spec says that encoders should assume color palettes take effect immediately, so in theory there should be no problem (they'd only modify parts of the palette needed by the next frame that aren't used on the current frame) but encoders don't seem to consider that, as they likely assumed the next frame would be rendered immediately after.  This problem should lessen or go away after I start optimizing the implementation. Right now the focus is on functionality, not performance.

### TEST RESULTS

- 03 F101
  - APPLE
  - ASLAMP 
  - BATTLE
  - BIRDSHOW
  - CARBOARD
  - CHOPCITY
  - CHUBBY03
  - MEMBRANE
  - PUZMORF
  - SNEEZE
  - STHELENS
  - WEIRD01
  
  
- 03 F100
  - BOOKSPIN

- 02 1000 (seemingly as last frame)
  - CDROMCLB
  - NAYLOR
  - PUZZLE5
  - SAUCER04
  
- 02 0D00
  - MOONWALK
  
- 03 B7B8
  - PLANET (with squawk)

## IDEAS / TODO

- stream file into RAM or ZP
  - use MACPTR with .A set to 0 and CLC set to advance, then send data to a 
    512 byte block in "golden RAM" ... this streams from disk as fast as possible
    but is slower to deal with as the buffer offset is 16-bits.
  - consider using MACPTR but setting .A to $FF (and checking .X and .Y to see
    if it read $00FF bytes or less) ... same idea as above but now the buffer 
    offset is 8-bit and faster to inc/dec
  - will this me more efficient than just calling MACPTR a bunch?  Maybe. Less JSRs
    but a lot more fussing with buffer management/loading and keeping track of how
    many bytes left before we need to fill again.  It really depends on how much
    additional overhead there is every time I call MACPTR
- write a delta-specific stage flipper that takes into account the line skip and
  line count ... needn't waste time copying the whole 320x200 as it currently does.

