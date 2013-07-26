CgiAdbRemote
============

###### For remotely monitoring and controlling *unrooted* Android devices connected to a physically inaccessible machine, through a local web browser (only tested on Chrome currently).

Copyright 2013 Tim Baverstock.

Example Usage:  
>./CgiAdbRemote -port=8181

Full options:  
>  -port=       : port upon which the server should run.  
  -banner=     : Message to display in big red at the top of the screen.  
  -foreground  : do not run in the background; mainly for development.  
  -autodelay=  : Half seconds of idle before reloading the screen.  
  -touchdelay= : Half seconds after a touch before reloading the screen.  

Run this on the machine with the devices attached, then browse on some other
machine to http://the.phone.host:8080/ (or other nominated port) for a list of
devices visible to ADB.

Each active device provides a link to a console which displays a screen shot
that supports mouse clicks and mouse drags, together with hard buttons
representing `POWER`, `HOME`, `BACK`, and `MENU`, a text entry box for sending
key events to the device, and the ability to rotate the display by 90 degrees.

The screen updates automatically every seven seconds, or one second after the
last operation unless a new operation resets the timer. (This is to allow
typing and sequential drag/click operations to be performed rapidly without the
screen update getting in the way.)

[Adb](http://developer.android.com/tools/help/adb.html) must be available to
this script (i.e. typing 'adb' on the command-line must work); the user running
it must have permissions to invoke adb on the devices.

This script requires Perl and the module HTTP::Server::Simple::CGI

Due to the implementation of the Perl -s option, to specify a numeric value of
'1' on the command-line, write it as '01'.

ISSUES:

[1](https://github.com/sleekweasel/CgiAdbRemote/issues/1). Not all devices implement all the 'input' subcommands used, like 'input swipe'.

TODO:

High

0. M. Restructure, refactor, tidy, and comment properly.
0. M. Rotate by 180deg and 270deg.
0. M. Prevent the type-in field ever losing focus (or otherwise grab all keys)
0. M. Passwords for view-only and view-and-interact operations
0. M. Some sort of username thing to see who was playing with a device and how recently.

Medium

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

