### [ Download Latest Version.](https://github.com/KovaaK/InterAccel/releases/latest)
[![Screenshot 1](https://i.imgur.com/4vy7XYf.png)](https://github.com/KovaaK/InterAccel/releases/latest)
# Interception Acceleration

The included programs allow you to use QuakeLive style mouse acceleration across your entire OS and any game, regardless of whether the game uses RawInput, DirectInput, or whatever else.  It makes use of the [Interception Driver](http://www.oblita.com/interception.html) to capture mouse movements before they are sent to the OS and modify them according to the same math that QL performs.

To install, you need :
1. Install the 'interception' driver by running 'install_driver.bat' from the "1. driver" folder (It will ask for Admin priviledges)
2. Install the Visual C++ Redistributable for Visual Studio 2015 from 
https://www.microsoft.com/en-us/download/details.aspx?id=48145 if you don't have it.
3. Reboot.  Yes, you actually need to reboot because of first step, or it won't work.

Then after you've rebooted, you should be able to run it.  Go to one of the "application" folders and run interGUI.exe.  The program will run a configuration wizard to give you a starting point for mouse acceleration, but you are welcome to use whatever settings you prefer.

Important notes:
- Interaccel.exe is the program that actually performs live mouse acceleration, and it only reads the configuration values when it is first run.
- InterGUI.exe runs Interaccel.exe in the background and automatically closes/restarts it when you change configuration values.
- If you close InterGUI.exe or Interaccel.exe, then *NO* mouse accel will be applied by the interception driver, and your input will be the same as if you didn't install the driver at all.
- You can minimize InterGUI.exe to your system tray and it will still work.  You can also schedule the program to start automatically in Windows and add "-m" to the command line parameters to force it to start minimized.
- There is a hidden setting called "FancyOutput" in settings.txt that when set to "1" can show the live sensitivity/acceleration output if you run interaccel.exe directly instead of using the GUI.  But it cases a small amount of input lag, so any time the GUI takes over it forces FancyOutput to 0.

- povohat & KovaaK