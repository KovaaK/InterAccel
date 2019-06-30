Extremely beta test version of some accel thing
===============================================

I made a crappy command prompt application which uses the awesome interception library
to do all the various accel driver things.

== WOW == http://www.oblita.com/interception.html == WOW ==

KovaaK adapted his GUI for this program.

STEP [1]

install the 'interception' driver by running 'install_driver.bat' (It will ask for Admin)
in the '1. driver' folder. you will have to reboot at this point.
no test mode required here, but you have to run it with ADMINISTRATOR PRIVILEGES (according
to the interception docs).

Also install the Visual C++ Redistributable for Visual Studio 2015 from 
https://www.microsoft.com/en-us/download/details.aspx?id=48145 if you don't have it.

STEP [2]

Go to one of the application folders (32bit or 64bit, depending on your OS).

Option A): Run interGUI.exe, and configure per http://mouseaccel.blogspot.com/2015/11/quickstart-guide-to-configuring-driver.html
This method will run interaccel.exe hidden in the background while "driver enabled" is checked, 
and restart it any time you save changes.  Note that closing the GUI also closes 
interaccel.exe.  Minimizing it to tray is fine though, and you can start it up with the 
command line parameter "interGUI.exe -m" to start it minimized (good for Windows startup).

Option B):
CAREFULLY edit the settings.txt file. I have done almost no checking of input at this early stage
so you might be able to fuck shit up pretty bad if you change anything but the numbers.
After editting the settings, run 'interaccel.exe' to make the magic happen. Hopefully your
settings from settings.txt will be displayed in a boring windows command prompt window. Ctrl+C or
clicking the [x] at the top right of the window will terminate the application.

STEP [3] 

TEST and have fun??

KNOWN ISSUES

Warning: intercept.dll might looks suspicious as hell to anticheat right now.  After we do some
preliminary testing, I plan on approaching the anticheat vendors and asking for a whitelist
exemption for our executable.

If you use FancyOutput AND resize the window to get scroll bars, clicking and dragging the scrollbar
to scroll will lock the cursor until you alt+tab or do some other magic thing that awakens it again.

FancyOutput may or may not introduce a miniscule amount of input lag.  The GUI stomps over
FancyOutput and puts it to 0 every time you click "Save Changes".

The interception library thing has some kind of GPL license which I swear I will read at some point
and eventually understand what I need to do to make the whole situation right. I have included
the current version of the source code in case thats relevant. It's probably messy I really don't
remember I've been doing this all night.

- povohat & KovaaK