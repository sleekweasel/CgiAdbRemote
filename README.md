CgiAdbRemote
============

Hacky Perl HTTP server for controlling Android devices via a web browser.

Copyright 2013 Tim Baverstock.

Usage: ./CgiAdbRemote

Description:

For accessing and controlling Android devices connected to a physically
inaccessible machine, from a browser (only tested on Chrome currently).

Run on the machine with the phones plugged in by USB, then browse on some other
machine to http://localhost:8080/ for a list of devices connected via ADB.

Each active device provides a link to a display of its screen which supports
mouse clicks and mouse drags, hard buttons representing POWER, HOME, BACK, and
MENU, a text entry box for sending key events to the device, and the ability to
rotate the device by 90 degrees. The screen updates automatically about half a
second after the last operation.

TODO:

1. Strip the occasional 'adb server is not running // adb server has been started' message that infrequently corrupts the screen image.
2. Rotate by 180deg and 270deg.
3. Update the screen unconditionally every few seconds.
4. Prevent the type-in field ever losing focus (or otherwise grab all keys)
5. Make the server multi-thread.
6. See whether it's worth persisting the adb connections per device.
7. Try to support a long slow drag: mouse down, long pause with screen updates, mouse up.


License: share and enjoy, but attribute me please.

