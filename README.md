# cx16-flip
FLI Player for Commander X16

***
This is a work-in-progress. It doesn't work yet.  After it is working,
it will be merged to main and this "work in progress" disclaimer will
be removed.
***

## Usage

If loaded and run via "RUN" (from BASIC) then it will look in the current
working directory for a file named "IMAGE.FLI" and will play assuming it
is a valid FLI file.

If loaded and run via "RUN:REM FOO" or "RUN:REM FOO BAR" then it will look
in the current working directory for a file named "FOO" and will play it
assuming it is a valid FLI file.

After the image has been played, the program will silently await "any key"
to be pressed.  After you press a key, it will return to BASIC.

### Caveats

The "RUN:REM FOO" trick is crudely implemented. Behavior is undefined
when there are leading spaces, or multiple spaces between arguments.
For example, do NOT do this:  "RUN  :   REM   FOO"


