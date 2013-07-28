CgiAdbRemote
============

###### For remotely monitoring and controlling *unrooted* Android devices connected to a physically inaccessible machine, through a local web browser (only tested on Chrome currently).

Copyright 2013 Tim Baverstock.

Example Usage:  
>./CgiAdbRemote.pl -port=8181

Full options:  
>  -port=       : port upon which the server should run.  
  -banner=     : Message to display in big red at the top of the screen.  
  -adb=        : location of the adb command, if not available on the path.  
  -foreground  : do not run in the background; mainly for development.  
  -autodelay=  : Seconds of idle before reloading the screen.  
  -touchdelay= : Seconds after a touch before reloading the screen.  

Run this on the machine with the devices attached, then browse on some other
machine to http://the.phone.host:8080/ (or other nominated port) for a list of
devices visible to ADB.

Each active device provides a link to a console which displays a screen shot
that supports mouse clicks and mouse drags, together with hard buttons
representing `POWER`, `HOME`, `BACK`, and `MENU`, a text entry box for sending
key events to the device, and buttons to rotate the display.

The screen updates automatically every seven seconds, or one second after the
last operation unless a new operation resets the timer. (This is to allow
typing and sequential drag/click operations to be performed rapidly without the
screen update getting in the way.)

[Adb](http://developer.android.com/tools/help/adb.html) must be available to
this script (ideally, typing 'adb' on the command-line will work, but you can
specify a command-line option); the user running it must have permissions to
invoke adb on the devices.

This script requires Perl and the module HTTP::Server::Simple::CGI

Due to the implementation details, '1' is a reserved value: to pass the value
'1' to a command-line option, write it as '01'.

ISSUES:

[1](https://github.com/sleekweasel/CgiAdbRemote/issues/1). Not all devices implement all the 'input' subcommands used, like 'input swipe'.

TODO:

High

0. M. Restructure, refactor, tidy, and comment properly.
0. M. Prevent the type-in field ever losing focus (or otherwise grab all keys)
0. M. Passwords for view-only and view-and-interact operations
0. M. Some sort of username thing to see who was playing with a device and how recently.

Medium

0. M. Something to read the keymap files from the device(s), to present 'fancy keys' buttons.
0. M. Some per-device config, to remember whether they implement things like 'input swipe' or how those need emulating.
0. M. Support for 'input sendevent' for devices with a primitive 'input' command. http://cjix.info/blog/misc/internal-input-event-handling-in-the-linux-kernel-and-the-android-userspace/
0. H. Try to support a long slow drag: mouse down, long pause with screen updates, mouse up.
0. H. Some means to display whether the phone is in standby ('off') = adb shell dumpsys power ... mPowerState=0/1

Low

0. H. Make the server multi-threaded, but only per device: serial access is good for typing!
0. H. See whether it's worth persisting the adb connections per device.

License: share and enjoy, but attribute me please.

Note: First 'up until 3am' quick hack I've engaged in for a very long time;
hopefully not the last.

Apologies to Carl.

