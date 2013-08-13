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
last interaction unless a new interaction resets the timer. (This is to allow
typing and sequential drag/click operations to be performed rapidly without the
screen update getting in the way.)

Since some devices don't support the `input tap/swipe` command, the
experimental `multitouch` and `older devices` buttons are provided: these are
incomplete, but available in case they're better than nothing. The `Keyboard`
button works once `multitouch` has been engaged, but can in principle operate
with `input` mode too. `Keyboard` buttons don't currently cause a screen
refresh.

[Adb](http://developer.android.com/tools/help/adb.html) must be available to
this script (ideally, typing 'adb' on the command-line will work, but you can
specify a command-line option); the user running it must have permissions to
invoke adb on the devices.

This script requires Perl and the module HTTP::Server::Simple::CGI (On Debian/Ubuntu: `apt-get install libhttp-server-simple-perl` On other systems, see [CPAN](http://www.cpan.org).)

Due to the implementation details, '1' is a reserved value on the command-line:
to pass the value '1' to a command-line option, write it as '01'.

[TODO](https://github.com/sleekweasel/CgiAdbRemote/issues):

0. Move these TODOs into the issues tracker!

High

0. M. Restructure, refactor, tidy, and comment properly.
0. M. Passwords for view-only and view-and-interact operations
0. M. Some sort of username thing to see who is/was playing with a device and how recently.

Medium

0. E. Check sendevent's orientation handling.
0. E. Test sendevent on old non-multitouch devices.
0. E. Persist rotation and possibly scaling per device.
0. M. Make `Keyboard` cause the screen to refresh.
0. H. Make the server multi-threaded, but only per device: serial access is good for typing!
0. H. See whether it's worth persisting the adb connections per device.

Low

0. M. Prevent the type-in field ever losing focus (or otherwise grab all keys)
0. H. Something to read the keymap files from the device(s), to present 'fancy keys' buttons.
0. H. Some means to display whether the phone is in standby ('off') = adb shell dumpsys power ... mPowerState=0/1
0. E. Better options handling.

License: share and enjoy, but attribute me please.

Note: First 'up until 3am' quick hack I've engaged in for a very long time;
hopefully not the last.

Apologies to Carl.

