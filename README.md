CgiAdbRemote
============

For remotely monitoring and controlling UNROOTED Android devices connected to a
physically inaccessible machine, through a local web browser (only tested on
Chrome currently).

Copyright 2013 Tim Baverstock.

Usage: ./CgiAdbRemote [-port=8181] [-foreground] [-banner="SOME MESSAGE"]

Run on the machine with the phones plugged in by USB, then browse on some other
machine to http://the.phone.host:8080/ (or other port) for a list of devices
connected via ADB.

Each active device provides a link to a display of its screen which supports
mouse clicks and mouse drags, hard buttons representing POWER, HOME, BACK, and
MENU, a text entry box for sending key events to the device, and the ability to
rotate the display by 90 degrees. The screen updates automatically about half a
second after the last operation unless some other operation resets the timer.
(This is to allow typing and sequential drag/click operations to be performed
rapidly without the screen update getting in the way.)

Adb must be available to this script; the user running it must have permissions
to invoke adb on the phones.

ISSUES:

0. Not all devices implement all the 'input' subcommands used, like 'input swipe'.

TODO:

High
0. E. Update the screen unconditionally every few seconds.
0. M. Restructure, refactor, tidy, and comment properly.
0. M. Rotate by 180deg and 270deg.
0. M. Prevent the type-in field ever losing focus (or otherwise grab all keys)
0. M. Passwords for view-only and view-and-interact operations
0. M. Some sort of username thing to see who was playing with a device and how recently.

Medium
0. E. A button to invoke adb kill-server.
0. E. Command-line option for the location of adb.
0. M. Something to read the keymap files from the device(s), to present 'fancy keys' buttons.
0. M. Some sort of 'adb shell' console, to interrogate devices (similar to, but distinct from, the touch event log iframe).
0. M. Some per-device config, to remember whether they implement things like 'input swipe' or whether (and how) they need emulating.
0. H. Try to support a long slow drag: mouse down, long pause with screen updates, mouse up.
0. H. Some means to display whether the phone is in standby ('off').

Low
0. H. Make the server multi-threaded, but only per device: serial access is good for typing!
0. H. See whether it's worth persisting the adb connections per device.

License: share and enjoy, but attribute me please.

Note: First 'up until 3am' quick hack I've engaged in for a very long time;
hopefully not the last.

Apologies to Carl.

