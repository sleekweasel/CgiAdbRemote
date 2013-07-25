CgiAdbRemote
============

For remotely monitoring and controlling UNROOTED Android devices connected to a
physically inaccessible machine, through a local web browser (only tested on
Chrome currently).

Copyright 2013 Tim Baverstock.

Usage: ./CgiAdbRemote

Run on the machine with the phones plugged in by USB, then browse on some other
machine to http://the.phone.host:8080/ for a list of devices connected via ADB.

Each active device provides a link to a display of its screen which supports
mouse clicks and mouse drags, hard buttons representing POWER, HOME, BACK, and
MENU, a text entry box for sending key events to the device, and the ability to
rotate the display by 90 degrees. The screen updates automatically about half a
second after the last operation unless some other operation resets the timer.
(This is to allow typing and sequential drag/click operations to be performed
rapidly without the screen update getting in the way.)

Adb must be available to this script; the user running it must have permissions
to invoke adb on the phones.

TODO:

0. Restructure, tidy, and comment properly.
0. Strip the occasional 'adb server is not running // adb server has been started' message that infrequently corrupts the screen image.
0. Rotate by 180deg and 270deg.
0. Update the screen unconditionally every few seconds.
0. Prevent the type-in field ever losing focus (or otherwise grab all keys)
0. Make the server multi-threaded, but only per device: serial access is good for typing!
0. See whether it's worth persisting the adb connections per device.
0. Try to support a long slow drag: mouse down, long pause with screen updates, mouse up.
0. Command-line option to invoke with .background() instead of .run(), so the server daemonises itself.
0. Command-line option to specify port.
0. Perhaps some sort of authorisation system for security and to help inform about who else is using a device at the moment.
0. A button to invoke adb kill-server.
0. Something to read the keymap files from the device(s), to present 'fancy keys' buttons.
0. Command-line option for the location of adb.
0. Some means to display whether the phone is in standby ('off').


License: share and enjoy, but attribute me please.

Note: First 'up until 3am' quick hack I've engaged in for a very long time;
hopefully not the last.

Apologies to Carl.

