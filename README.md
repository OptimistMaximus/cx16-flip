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
| 1  | cannot open file          | .X is CHKIN statis, .Y is OPEN status |
| 2  | unsupported file type     | the file type                         |
| 3  | unsupported frame type    | the frame type                        |
| 4  | unsupported chunk type    | the chunk type                        |
| 5  | width too big             | the image width                       |
| 6  | height too big            | the image height                      |
| 7  | depth too big             | the color depth                       |
| 8  | speed too high            | the FLI speed, lower 16-bits only     |
| 9  | delay too long            | the FLC delay                         |





