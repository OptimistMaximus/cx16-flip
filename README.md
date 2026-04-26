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

Note that the parser that interprets the REM suffix is fairly simplistic
and has undefined behavior if you have any spaces around the colon, or
multiple spaces between arguments. For example, do NOT run it like this:
`RUN :  REM     FOO`

Upon returning to BASIC, it sents the .A register to the return code,
and the .X and .Y registers hold extra details.  You can examine these
via `PRINT PEEK(780)`,  `PRINT PEEK(781)`, and `PRINT PEEK(782)`,
respectively.  

| .A | .A meaning                  | .X and .Y meaning                    |
|----|-----------------------------|--------------------------------------|
| 0  | success                     | n/a                                  |
| 1  | cannot open file            | .X .Y holds CHKIN and OPEN status    |





