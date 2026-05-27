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

- This implementation only supports the FLI format. It does not
  support FLC files.

- Performance is terrible at the moment, especially for files that have
  huge deltas.  Performance issues will be addressed in future releases.

- If the FLI header's speed is over 297, it will be forced to 297. This
  equates to just over 4 seconds. From dozens of samples of FLI files in
  the wild, none of them had speeds more than 255, so this shouldn't be
  an issue. This limit keeps the player's implementation much simpler.

- The parser will fail if any chunk has a size of more than 2^24 - 1. The
  file format has chunk size as a 32-bit value, but even the most
  inefficiently encoded chunk possible still wouldn't be larger than 128k.
  So there's no need for the parser to waste time on 32-bit math when it
  can be doing 24-bit math instead.

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
| 1    | unsupported file type     | the file type                         |
| 2    | invalid chunk type        | the chunk type                        |
| 3    | read error                | low byte is READST value              |

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

| Version | VSyncs | FPS | Overruns | PRG Bytes |
|---------|--------|-----|----------|-----------|
| 0.1.0   | $0183  |   9 | $0033    | 1825      |
| 0.1.1   | $0176  |   9 | $0032    | 1705      |
| 0.2.1   | $0163  |  10 | $0032    | 1747      |
| 0.3.0   | $00F9  |  15 | $0031    | 2114      |
| 0.4.0   | $00A7  |  21 | $0024    | 1998      |
| 0.5.0   | $009E  |  22 | $0029    | 1948      |

### Version History

- 2026/05/?? Version 0.5.0
  - now detects the next chunk with a sliding window instead of trusting
    the encoded chunk sizes (which are surprisingly wrong in a lot of FLI
    files found in the wild).  The sliding window algorithm works very
    fast for most files that are only off by 1 byte.  But it is much less
    efficient for files with excessive padding.  It also only works when
    the padding is all zeroes (which all files found in the wild seem to
    be so far). It has a chance to not work if encodings pad with random
    bytes and the random bytes happen to look like valid data. So far this
    situation has never been encountered in real life.  It would be much
    nicer if we could trust that all encodings put the correct size values
    in their headers, but alas that is not the case.

- 2026/05/24 Version 0.4.0
  - more performance enhancements

- 2026/05/22 Version 0.3.0
  - introduced crude file input stream buffering
  - enhanced support for encodings with non-standard padding
  - better tolerance of files with garbage bytes after final frame

- 2026/05/19 Version 0.2.1
  - minor tidying up
  - minor performance enhancement

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
- BOOKSPIN (padding, per the spec (align to even boundaries)
- CHOPCITY (very long)
- SAUCER04 (FLI_COPY)
- MOONWALK (BLACK)
- BADAPPLE (excessive padding, well beyond what the spec suggests)

Good FLI files but currently have problems rendering

- 04 F101
  - APPLE
  - ASLAMP
  - BIRDSHOW
  - CARBOARD
  - CHOPCITY
  - CHUBBY03
  - GALLERY2
  - MEMBRANE
  - PUZMORF
  - SNEEZE
  - SOCKET
  - STHELENS
  - WEIRD01
- 04 F100
  - BOOKSPIN
  - VPHORSE
- 04 0000
  - MOONWALK



Bad FLI files:

- PLANET.FLI (used during testing) will not play properly because the RLE count
  is incorrect in one of the packets on line 51, in the first Delta FLI chunk.
  This particular file even has problems playing in industry-standard FLI players,
  but those players have proper sanity checks to avoid buffer overruns, so the
  result is just pixel mess on screen.

## IDEAS / TODO

- since we can't use 32-bit FX cache writes for palette, there might be no benefit
  to storing it in VRAM. Consider storing in "golden" RAM instead.  This way we
  can skip/burn palette entries by just doing inx or iny instead of LDA VERA_DATA0.
  Though, palette updates don't happen as often as FLI_DELTA so optimization should
  focus there first.
- keep a running 24-bit value of our VRAM location, and evaluate each skip ...
  setting VRAM addr takes 26 cycles, and doing 7 LDAs to VERA_DATA0 takes 28 bytes.
  So any skip of 7 or more is faster to do by moving the VRAM address.  But doing
  the ADC to keep that value fresh is also expensive, as is doing a U24_INC with
  every byte written.  Is there a way to ask VERA what its offset currently is?




