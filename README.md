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

## Assumptions

This parser gets some of its performance gains by making certain
reasonable assumptions about the file content. An evil hacker could
exploit this to cause all sorts of buffer overruns and what-not, but
this parser is assumed to be used by hobbyists who give it files that
are legitimately and sensibly encoded files.

The parser's assumptions are as follows:

- color chunks never have a packet count of zero, since it would be
  silly to have a color chunk with zero packets. A sensible encoder
  would simply not have created a color chunk.
- color chunks never have a packet count more than 256, since there
  are only 256 colors and it would already be completely silly to
  encode them as 256 packets each having 1 color. A sensible encoder
  would put runs of colors into each packet, resulting in less than
  256 of them overall.
- delta chunks never have a line count of zero, since it would be
  silly to have a delta that does nothing. A sensible encoder would
  simply not have created the delta chunk.
- frames never have more than 255 sub-chunks, since even the most
  inefficiently encoded frame imaginable would be 1 color chunk
  and 200 delta packets each representing 1 line.  No sensible
  encoder would ever do such a thing.

## Caveats

- This implementation only supports the FLI format. It does not
  support FLC files.

- If the FLI header's speed is over 297, it will be forced to 297. This
  equates to just over 4 seconds. From dozens of samples of FLI files in
  the wild, none of them had speeds more than 255, so this shouldn't be
  an issue. This limit keeps the player's implementation much simpler.

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
| 0.6.0   | $009A  |  23 | $0029    | 1951      |
| 0.6.1   | $0072  |  31 | $0024    | 2340      |
| 0.6.2   | $006B  |  33 | $0021    | 2322      |

### Version History

- 2026/05/31 Version 0.6.2
  - minor performance optimizations to column skip and caching

- 2026/05/30 Version 0.6.1
  - significant refactoring of how VERA addresses are manipulated
  - significant performance optimizations for speed (at expense of PRG size)

- 2026/05/27 Version 0.6.0
  - speed is now correctly applied per frame (not per chunk, as incorrectly
    done in prior versions)
  - palette transitions look much better now, since they are postponed
    until the entire new frame has been rendered, and swapped just before
    that new frame is shuffled into VRAM
  - files whose frames have multiple chunks (e.g. a small delta for the
    top of the screen and a small delta for the bottom of the screen) now
    play much smoother.

- 2026/05/26 Version 0.5.0
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
- screen goes white just before first frame loads
- screen tearing and goes a bit wonky on palette changes, because screen updates are not  yet
  synchronized with VSyncs


### TEST RESULTS

Good FLI files for regression test:

- BELL (small, simple)
- OWL  (small, simple)
- BOOKSPIN (padding, per the spec (align to even boundaries)
- CHOPCITY (very long)
- SAUCER04 (FLI_COPY)
- MOONWALK (BLACK)
- BA1 (excessive padding, well beyond what the spec suggests)

Bad FLI files:

- PLANET.FLI (used during testing) will not play properly because the RLE count
  is incorrect in one of the packets on line 51, in the first Delta FLI chunk.
  This particular file even has problems playing in industry-standard FLI players,
  but those players have proper sanity checks to avoid buffer overruns, so the
  result is just pixel mess on screen.

## IDEAS / TODO

- consider saving time by taking phx/plx and phy/ply out of low level caching
  subroutines and put them in the higher level functions that drive them ... we
  are probably needlessly pushing and pulling in some cases that might be in
  big 320x200 pixel loops, so saving 7 cycles per push/pull will really add up.
- postpone the staging copy to happen during vsync.  Basic idea is to have 2 bits:
  FLIP_REQUESTED and FLIP_DONE.  Main code clears FLIP_DONE and sets FLIP_REQUESTED.
  Then waits for FLIP_DONE to become set.  IRQ code looks on VSync if FLIP_REQUESTED
  is set, and if so it flips the stage data then sets FLIP_DONE.
