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

- This implementation only supports the FLI format. It does not FLC files.

- Performance is terrible at the moment, especially for files that have
  huge deltas.  Performance issues will be addressed in future releases.

- If the FLI header's speed is over 297, it will be forced to 297. This
  equates to just over 4 seconds. From dozens of samples of FLI files in
  the wild, none of them had speeds more than 255, so this shouldn't be
  an issue. This limit keeps the player's implementation much simpler.

- The render time is measured at runtime and is subtracted from the "speed"
  after each image is rendered. This means the overall overall frame rate
  should be consistent, but images themselves might not be on-screen for
  for the proper amount of time.

- This implementation optimistically assumes the file is properly encoded.
  If the file is not properly encoded, the player can easily get into
  situations where it overruns buffers and writes beyond the usable
  region of VRAM, usually resulting in squawks from the speaker (depending
  on what bytes were written into the PSG registers) or it will show
  wonky colors (if the system palette was clobbered) or pixel mess on screen.

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

### Performance Timing Info

When the program is compiled with `DEBUG_TIMER_ENABLED` defined, after the
image has been rendered, it will display the total elapsed vsyncs starting
from just before the header was parsed, until just after the final chunk
was parsed and rendered.  The time spent waiting for you to press "any key"
is not included in the timer result.

When the compiled in this mode, the "speed" is not honored, so that the
timing result represents ONLY the time spent processing the images. It does,
however, keep track of how many times the processing took longer than the
speed.  Ideally the count should be zero, which means processing was fast
enough that it happened within the allowed speed.

For apples-to-apples comparisons across releases, the file "STARTREK.FLI"
will be used.  The results are tracked here, for each released version:

| Version | VSyncs | Overruns | PRG Bytes |
|---------|--------|----------|-----------|
| 0.1.0   | $0183  | $0033    | 1825      |
| 0.1.1   | $0176  | $0032    | 1705      |

### Version History

- 2026/05/17 Version 0.1.1
  - minor performance enhancement

- 2026/05/17 Version 0.1.0
  - basic functionality seems stable
  - code is still quite messy and inefficient

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

Good FLI files for regression test:

- BELL (small, simple)
- OWL  (small, simple)
- BOOKSPIN (has padding)
- CHOPCITY (very long)
- PLANET (squawks)
- SAUCER04 (FLI_COPY)
- MOONWALK (BLACK)

Bad FLI files:

PLANET.FLI (used during testing) will not play properly because the RLE count
is incorrect in one of the packets on line 51, in the first Delta FLI chunk.
This particular file even has problems playing in industry-standard FLI players,
but those players have proper sanity checks to avoid buffer overruns, so the
result is just pixel mess on screen.

For reference, here is the run of bytes where the problem exists:

```
12
  38 F9 4C
  00 1D 4D4F505152535455 565758595A5B5C5D
        5E5F606263646566 6768696B6C
  00 FB 6D
  00 FA 6E
  00 FA 6F
  00 5C 6E6D6C6B69686766 6564636261605F5E
        5C5B5A5857565453 51504F4D4C4B4A49
        4948484847474646 4545454444434445
        46474849494A4B4C 4D4E4F5051515354
        55565758595B5C5D 5E5F606163636364
        6464646465656565 65666666
  00 0C 6666656464636262 6161605F
  00 03 5F5E01

  5D

  00 FB 5C
  00 FC 5B
  00 FB 5A
  00 0A 59595A5A5A5B5B5C 5C5C
  00 03 5D5D5E
  00 01 5E
  00 F7 5F
  00 F8 5E
  00 03 5D5C5B

0F
  37 F7 57
```

Whitespace above has been added to help visualize the 12 packets in the
line.  Next are 12 packets, having format SKIP COUNT DATA.  When COUNT
is negative it means there is 1 byte of data to be replicated.  When COUNT
is positive, it means there are that many bytes of data to follow.

Everything looks fine until packet `00 03 5F5E01` ... it's count should
have been 04 because a count of 03 means that 5D is interpreted as the
SKIP of the next packet, and then everything after that makes no sense.
If we ignore that 5D, then everything else after that DOES make sense.

## IDEAS / TODO

- stream file into RAM or ZP
  - use MACPTR with .A set to 0 and CLC set to advance, then send data to a
    512 byte block in "golden RAM" ... this streams from disk as fast as possible
    but is slower to deal with as the buffer offset is 16-bits.
  - consider using MACPTR but setting .A to $FF (and checking .X and .Y to see
    if it read $00FF bytes or less) ... same idea as above but now the buffer
    offset is 8-bit and faster to inc/dec
  - consider buffering in ZP since we have $40-$7F free ... would the performance
    gain of having data in ZP overcome the performance loss of having a much smaller
    ($40 byte instead of $FF byte) buffer?
  - will this me more efficient than just calling MACPTR a bunch?  Maybe. Less JSRs
    but a lot more fussing with buffer management/loading and keeping track of how
    many bytes left before we need to fill again.  It really depends on how much
    additional overhead there is every time I call ACPTR or MACPTR
- write a delta-specific stage flipper that takes into account the line skip and
  line count ... needn't waste time copying the whole 320x200 as it currently does.
- since we can't use 32-bit FX cache writes for palette, there might be no benefit
  to storing it in VRAM. Consider storing in "golden" RAM instead.  This way we
  can skip/burn palette entries by just doing inx or iny instead of LDA VERA_DATA0.
  Though, palette updates don't happen as often as FLI_DELTA so optimization should
  focus there first.
