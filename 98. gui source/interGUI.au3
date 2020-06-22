;NOTE TO SELF - FIX REQUIRE ADMIN AND FILE PATH LINES BEFORE COMPILING

; #RequireAdmin ; not needed in the intercept version - we aren't changing the registry.
Global $file_path = @MyDocumentsDir & "\MouseAccelDriver\"

#cs
This program is an adaptation of the povohat mouse accel GUI.  Instead of changing registry
settings, it reads/writes the settings.txt file used by the newer intercept driver method of
mouse accel.

The text below is from the old kernel-level driver method. (plus changelog updates)

------

A configuration and graphical display tool for Povohat's custom mouse accel driver.
http://accel.drok-radnik.com/ for more information.

Supports saving driver configuration to .profile files, then can manually load them
in the GUI, manually load them with global hotkeys, or automatically load them on a
specific process (.exe) running.

-KovaaK.

Note this was my first attempt at using AutoIT.  I apologize for crap code and abuse of globals.

TODO:
- Simple GUI mode that hides Sensitivity/Pre-scales.

Changelog:
3.02 (01/03/16)
- Fixed crash on startup bug that occured while Windows was too busy (such as during OS startup on a non SSD)
- Added support for 2000hz mice for graphing purposes
- Fixed global hotkeys having a short duration of no acceleration on.  The fix was to get a list of all running
  interaccel.exe's, start a new one, pause for 20ms (while it gets ready to take over), then kill the old ones.
Thanks to "The Man" and nGolf for the help!

3.01 (12/19/15)
- Fixed bug where opening a profile would make the GUI fail to run interaccel.exe or change settings.txt
  (Thanks nGolf!  Turned out the working directory was being changed to the profile directory, so it wasn't
  finding the exe and it was saving settings.txt in the wrong place.  Now before saving settings.txt, it sets
  the working directory to the script directory.)

3.00 (12/4/15)
- Added command-line option to minimize the window on startup (interGUI.exe -m)
- Added configuration wizard to help new users with a set of sample options.
- Added tooltips for settings.
- Added link to blog.
- Replaced registry read/write with settings.txt read/write.
- Made this gui start and stop the mouse accel executable when settings change.
- Also starts/stops the accel executable on GUI open/close.
- Skipped to version 3.00 to specify this is for the intercept driver, and not the kernel-level driver.

2.03 (2/1/15)
- Fixed input of negative values for settings that accepted them.
  (thanks ovaton for the reg expression help)

2.02 (12/12/14)
- Finally fixed the graphing calculation for pre-scale based curves.
- Split post-scale into post-scale Y and post-scale X per povo's changes
- Added options to scale acceleration with changes to pre-scale and post-scale
- Added options to lock pre/post-scale Y to pre/post-scale X

2.01 (11/27/14)
- Corrected Speed Cap to be calculated in graph before post-scale multiplication.

2.0 (11/26/14)
- Realized I was naming my versions internally as 1.0x, but the zip was 1.x.  Decided to jump to 2.0 to avoid confusion.
- Updated GUI for povohat's new settings (Angle Snapping and Speed Cap)

1.05 (10/25/13)
- Correctly made file open/save dialogs prevent clicking back to previous part of GUI.
- Made the link in global hotkey an actual clickable hyperlink.
- Created options to change colors on graph and always display selected profiles.
- Added a "*" to the end of the "current profile" displayed at the top if the current settings have been changed from the saved file.
- Graph settings option lets you select whether to show other profiles on the graph or not.

1.04 (10/22/13)
- Added a warning if you try to close the program with hotkey profiles activated.
- Fixed hotkey spamming screwing up the graph. (I hope)
- Made the graph only refresh upon finishing the update.  This makes it a lot quicker to draw.
- Fixed Right modifier keys getting stuck when used as triggers for profiles.  Side effect:
  Global Hotkey Profiles now activate when modifier keys are released.  Hotkeys that have no
  modifiers still activate upon the key being pressed down.
- Made it so only one copy of the program can run at once.

1.03 (10/21/13)
- Changed plot pen size from 2 to 1 (thinner lines).
- Added option to make graph go by one of the pre-scale settings (X or Y).
- Added global hotkeys similar to auto profile switching.
- Prevented window from being resized (since it screwed with the graph)

1.02 (10/18/13)
- Fixed power calculation
- Properly separated enabled driver checkbox into new/current.
- Graphs now correctly react to the enabled checkbox.
- Option for automatic profile switching when a given process is running.
- Added setting to scale sensitivity cap when post-scale is changed.
  This allows you to keep a "high speed mouse sens" the same while using post-scale to
  change the "low speed mouse sens".
- Program now minimizes to tray

1.01 (10/16/13)
- Removed testing values as defaults (which would be pre-loaded under certain
  conditions, as seen by povohat)
- Added buttons to specify the X and Y graph maximums.
- Properly sanitized inputs for USB polling, DPI, and graph inputs
- Added settings.ini support for USB polling rate, DPI, and graph settings memory.
- Basic Import/Export with .profiles

1.00 (10/14/13)
- Initial release.  Control registry settings and graph current versus 'new' prior to saving to registry.

;~ Ideas/fixes to implement:
- Option to have global hotkeys work on holding down, then upon release return to default
- Bug: double clicking color chooser creates a duplicate that isn't clickable?
- Update graph on changing any new input?
- Graph background and gridline color?
- Legend for colors on graph?
- Checkboxes for listview elements in manual/auto profile config?
#ce

;#include "GUISysLink.au3" ; Used for hyperlink in global hotkey config
;#include <GuiListView.au3> ; ListView boxes are used in auto/manual profile config
;#include <File.au3> ; Used for _FileListToArray in the graph options
;#include <Array.au3> ; Used in graph options
;#Include <ColorChooser.au3> ; Graph options
;#Include <ColorPicker.au3> ; Graph options
;#include <WinAPI.au3> ; Don't believe this is used anymore...

#include "GraphGDIPlus.au3" ; Used for graphing window
#include <GUIConstantsEx.au3> ; Used for $GUI_CHECKED/$GUI_UNCHECKED
#include <ButtonConstants.au3> ; $BS_RIGHTBUTTON for right checkbox
#include <WindowsConstants.au3> ; Used for window settings
#include <Constants.au3> ; Used for minimize to tray
#include <Misc.au3> ; Used for _Singleton to make sure only one copy of the program is running
#include "interoptions.au3" ; Menu options for profile switching (auto and manual) and graph settings
#include <FileConstants.au3> ; Used for reading/writing settings.txt
#include <GUIToolTip.au3> ; Tooltips for the options
#include "GUISysLink.au3" ; Used for hyperlink to blog

#NoTrayIcon
#AutoIt3Wrapper_icon=mouse.ico

Global $GraphStamp = 0 ; used to make sure we aren't drawing an old request
; These are GUI elements - don't touch these.
Global $GUI, $Graph, $ProfileGUI, $ProfileLabel, $hyperlink, $Dummy
Global $m_accelmode, $m_sens, $m_accel, $m_senscap, $m_offset, $m_power, $m_prexscale, $m_preyscale, $m_postxscale, $m_postyscale, $m_angle, $m_driverenabled, $m_anglesnap, $m_speedcap
Global $m_new_accelmode, $m_new_sens, $m_new_accel, $m_new_senscap, $m_new_offset, $m_new_power, $m_new_prexscale, $m_new_preyscale, $m_new_postxscale, $m_new_postyscale, $m_new_angle, $m_new_driverenabled, $m_new_anglesnap, $m_new_speedcap
Global $m_driverenabled, $autoprofilecheckbox, $openprofilebutton, $manualprofilecheckbox
Global $senscapscaleitem, $accelscaleitem, $lockpostscaleitem
Global $senscapscaleitem2, $accelscaleitem2, $lockprescaleitem
Global $wizardoption, $mousesettings
Global $hyperlink, $Dummy
Global $CurrentProfile = ""
; ini-related stuff
Global $ini_path = $file_path & "settings.ini"
Global $graphdensity, $graph_x, $graph_y, $frametime_ms, $mouse_dpi, $graph_scale

;Global $accelExeName = "calc.exe"
Global $accelExeName = "interaccel.exe"

If _Singleton("Intercept Mouse Accel Filter Config", 1) = 0 Then
    MsgBox(0, "Warning", "Intercept Mouse Accel Filter Config is already running.")
    Exit
EndIf

_Main()

Func _KillAllAccelProcesses() ; Closes all instances of the accel exe running.
   Local $process = ProcessList($accelExeName)
   For $i = 1 To $process[0][0]
	  ProcessClose($process[$i][1])
   Next
EndFunc

Func _StringIsNumber($input) ; Checks if an input string is a number.
; 	The default StringIsDigit() function doesn't recognize negatives or decimals.
;   "If $input == String(Number($input))" doesn't recognize ".1" since Number(".1") returns 0.1
;   So, here's a regex I pulled from http://www.regular-expressions.info/floatingpoint.html
   $array = StringRegExp($input, '^[-+]?([0-9]*\.[0-9]+|[0-9]+)$', 3)
   if UBound($array) > 0 Then
	  Return True
   EndIf
   Return False
EndFunc

Func _GetNumberFromString($input) ; uses the above regular expression to pull a proper number
;   $array = StringRegExp($input, '^[-+]?([0-9]*\.[0-9]+|[0-9]+)$', 3) ; this didn't return negatives
   $array = StringRegExp($input, '^([-+])?(\d*\.\d+|\d+)$', 3)
   if UBound($array) > 1 Then
	  Return Number($array[0] & $array[1]) ; $array[0] is "" or "-", $array[1] is the number.
   EndIf
   Return "error"
EndFunc

Func _ConvertAccelMode($input)	;return accelmode as a number for settings.txt
	Switch $input
		Case "QuakeLive"
			Return 0
		Case "Natural"
			Return 1
		Case 0
			Return "QuakeLive"
		case 1
			Return "Natural"
	EndSwitch
EndFunc

Func _ReadIni() ; Read from settings.ini file
   $graphdensity = IniRead($ini_path,"Graph","Density","200")
   $graph_x = IniRead($ini_path,"Graph","Range_X","50")
   $graph_y = IniRead($ini_path,"Graph","Range_Y","3")
   $graph_scale = IniRead($ini_path,"Graph","Scale","X")
   $frametime_ms = IniRead($ini_path,"Mouse","Frametime_ms","2")
   $mouse_dpi = IniRead($ini_path,"Mouse","DPI","0")
   if IniRead($ini_path,"ProfileSettings","AutoSwitch","0") = 1 Then
	  GUICtrlSetState($autoprofilecheckbox, $GUI_CHECKED)
	  GUICtrlSetState($openprofilebutton, $GUI_DISABLE)
	  GUICtrlSetState($manualprofilecheckbox, $GUI_DISABLE)
   EndIf
   if IniRead($ini_path,"Mouse","SensCapScale","0") = 1 Then
	  GUICtrlSetState($senscapscaleitem, $GUI_CHECKED)
   EndIf
   if IniRead($ini_path,"Mouse","SensCapScale2","0") = 1 Then
	  GUICtrlSetState($senscapscaleitem2, $GUI_CHECKED)
   EndIf
   if IniRead($ini_path,"Mouse","AccelScale","0") = 1 Then
	  GUICtrlSetState($accelscaleitem, $GUI_CHECKED)
   EndIf
   if IniRead($ini_path,"Mouse","AccelScale2","0") = 1 Then
	  GUICtrlSetState($accelscaleitem2, $GUI_CHECKED)
   EndIf
   if IniRead($ini_path,"Mouse","LockPreScale","1") = 1 Then
	  GUICtrlSetState($lockprescaleitem, $GUI_CHECKED)
  	  GUICtrlSetState($m_new_preyscale, $GUI_DISABLE)
   EndIf
   if IniRead($ini_path,"Mouse","LockPostScale","1") = 1 Then
	  GUICtrlSetState($lockpostscaleitem, $GUI_CHECKED)
  	  GUICtrlSetState($m_new_postyscale, $GUI_DISABLE)
   EndIf
EndFunc

Func _WriteIni() ; Write to settings.ini file
   IniWrite($ini_path,"Graph","Range_X",$graph_x)
   IniWrite($ini_path,"Graph","Range_Y",$graph_y)
   IniWrite($ini_path,"Graph","Density",$graphdensity)
   IniWrite($ini_path,"Graph","Scale",$graph_scale)
   IniWrite($ini_path,"Mouse","Frametime_ms",$frametime_ms)
   IniWrite($ini_path,"Mouse","DPI",$mouse_dpi)
   If BitAND(GUICtrlRead($autoprofilecheckbox), $GUI_CHECKED) = $GUI_CHECKED Then
	  IniWrite($ini_path,"ProfileSettings","AutoSwitch",1)
   Else
	  IniWrite($ini_path,"ProfileSettings","AutoSwitch",0)
   EndIf
   If BitAND(GUICtrlRead($senscapscaleitem), $GUI_CHECKED) = $GUI_CHECKED Then
	  IniWrite($ini_path,"Mouse","SensCapScale",1)
   Else
	  IniWrite($ini_path,"Mouse","SensCapScale",0)
   EndIf
   If BitAND(GUICtrlRead($senscapscaleitem2), $GUI_CHECKED) = $GUI_CHECKED Then
	  IniWrite($ini_path,"Mouse","SensCapScale2",1)
   Else
	  IniWrite($ini_path,"Mouse","SensCapScale2",0)
   EndIf
   If BitAND(GUICtrlRead($accelscaleitem), $GUI_CHECKED) = $GUI_CHECKED Then
	  IniWrite($ini_path,"Mouse","AccelScale",1)
   Else
	  IniWrite($ini_path,"Mouse","AccelScale",0)
   EndIf
   If BitAND(GUICtrlRead($accelscaleitem2), $GUI_CHECKED) = $GUI_CHECKED Then
	  IniWrite($ini_path,"Mouse","AccelScale2",1)
   Else
	  IniWrite($ini_path,"Mouse","AccelScale2",0)
   EndIf
   If BitAND(GUICtrlRead($lockprescaleitem), $GUI_CHECKED) = $GUI_CHECKED Then
	  IniWrite($ini_path,"Mouse","LockPreScale",1)
   Else
	  IniWrite($ini_path,"Mouse","LockPreScale",0)
   EndIf
   If BitAND(GUICtrlRead($lockpostscaleitem), $GUI_CHECKED) = $GUI_CHECKED Then
	  IniWrite($ini_path,"Mouse","LockPostScale",1)
   Else
	  IniWrite($ini_path,"Mouse","LockPostScale",0)
   EndIf
EndFunc

Func _WriteValsToConfig($silentsuccess = 0) ; Write new values to 'current' values and settings.txt.
   ; If bad values exist, fail before doing anything.
   If Not(GUICtrlRead($m_new_accelmode) == "QuakeLive" Or GUICtrlRead($m_new_accelmode) == "Natural") Then
	   MsgBox(0x10, "Failure", "AccelMode must be either 'QuakeLive' or 'Natural'", 3, $GUI)
	  Return 1
   EndIf
   If _StringIsNumber(GUICtrlRead($m_new_sens)) = False or Number(GUICtrlRead($m_new_sens)) <= 0 Then
	  MsgBox(0x10, "Failure", "Sensitivity must be a number and > 0.", 3, $GUI)
	  Return 1
   EndIf
   If _StringIsNumber(GUICtrlRead($m_new_accel)) = False or Number(GUICtrlRead($m_new_accel)) < 0 Then
	  MsgBox(0x10, "Failure", "Acceleration must be a number and >= 0.", 3, $GUI)
	  Return 1
   EndIf
   If _StringIsNumber(GUICtrlRead($m_new_senscap)) = False or Number(GUICtrlRead($m_new_senscap)) < 0 Then
	  MsgBox(0x10, "Failure", "Sensitivity Cap must be a number and >= 0.", 3, $GUI)
	  Return 1
   EndIf
   If _StringIsNumber(GUICtrlRead($m_new_speedcap)) = False or Number(GUICtrlRead($m_new_speedcap)) < 0 Then
	  MsgBox(0x10, "Failure", "Speed Cap must be a number and >= 0. (0 disables)", 3, $GUI)
	  Return 1
   EndIf
   If _StringIsNumber(GUICtrlRead($m_new_offset)) = False Then
	  MsgBox(0x10, "Failure", "Offset must be a number.", 3, $GUI)
	  Return 1
   EndIf
   If _StringIsNumber(GUICtrlRead($m_new_power)) = False or Number(GUICtrlRead($m_new_power)) < 0 Then
	  MsgBox(0x10, "Failure", "Power must be a number and >= 0.", 3, $GUI)
	  Return 1
   EndIf
   If _StringIsNumber(GUICtrlRead($m_new_prexscale)) = False or Number(GUICtrlRead($m_new_prexscale)) <= 0 Then
	  MsgBox(0x10, "Failure", "Pre-Scale X must be a number and > 0.", 3, $GUI)
	  Return 1
   EndIf
   If _StringIsNumber(GUICtrlRead($m_new_preyscale)) = False or Number(GUICtrlRead($m_new_preyscale)) <= 0 Then
	  MsgBox(0x10, "Failure", "Pre-Scale Y must be a number and > 0.", 3, $GUI)
	  Return 1
   EndIf
   If _StringIsNumber(GUICtrlRead($m_new_postxscale)) = False or Number(GUICtrlRead($m_new_postxscale)) <= 0 Then
	  MsgBox(0x10, "Failure", "Post Scale X must be a number and > 0.", 3, $GUI)
	  Return 1
   EndIf
   If _StringIsNumber(GUICtrlRead($m_new_postyscale)) = False or Number(GUICtrlRead($m_new_postyscale)) <= 0 Then
	  MsgBox(0x10, "Failure", "Post Scale Y must be a number and > 0.", 3, $GUI)
	  Return 1
   EndIf
   If _StringIsNumber(GUICtrlRead($m_new_angle)) = False Then
	  MsgBox(0x10, "Failure", "Angle must be a number.", 3, $GUI)
	  Return 1
   EndIf
   If _StringIsNumber(GUICtrlRead($m_new_anglesnap)) = False or Number(GUICtrlRead($m_new_anglesnap)) < 0 Then
	  MsgBox(0x10, "Failure", "Angle Snap must be a number and >= 0.", 3, $GUI)
	  Return 1
   EndIf

   ; Write new values into current values for GUI.
   GUICtrlSetData($m_accelmode, GUICtrlRead($m_new_accelmode))
   GUICtrlSetData($m_sens, _GetNumberFromString(GUICtrlRead($m_new_sens)))
   GUICtrlSetData($m_accel, _GetNumberFromString(GUICtrlRead($m_new_accel)))
   GUICtrlSetData($m_senscap, _GetNumberFromString(GUICtrlRead($m_new_senscap)))
   GUICtrlSetData($m_speedcap, _GetNumberFromString(GUICtrlRead($m_new_speedcap)))
   GUICtrlSetData($m_offset, _GetNumberFromString(GUICtrlRead($m_new_offset)))
   GUICtrlSetData($m_power, _GetNumberFromString(GUICtrlRead($m_new_power)))
   GUICtrlSetData($m_prexscale, _GetNumberFromString(GUICtrlRead($m_new_prexscale)))
   GUICtrlSetData($m_preyscale, _GetNumberFromString(GUICtrlRead($m_new_preyscale)))
   GUICtrlSetData($m_postxscale, _GetNumberFromString(GUICtrlRead($m_new_postxscale)))
   GUICtrlSetData($m_postyscale, _GetNumberFromString(GUICtrlRead($m_new_postyscale)))
   GUICtrlSetData($m_angle, _GetNumberFromString(GUICtrlRead($m_new_angle)))
   GUICtrlSetData($m_anglesnap, _GetNumberFromString(GUICtrlRead($m_new_anglesnap)))
   If BitAND(GUICtrlRead($m_new_driverenabled), $GUI_CHECKED) = $GUI_CHECKED Then
	  GUICtrlSetState($m_driverenabled, $GUI_CHECKED)
   Else
	  GUICtrlSetState($m_driverenabled, $GUI_UNCHECKED)
   EndIf

   ;Disable power during natural accel
   If GUICtrlRead($m_new_accelmode) == "Natural" Then
	   GUICtrlSetState($m_new_power, $GUI_DISABLE)
	   If GUICtrlRead($m_new_senscap) <= 1 Then
		   MsgBox(0x30, "Warning", "While in Natural accel mode, Senscap must be < 1 for accel to take effect.", 3, $GUI)
	   EndIf
   Else
	   GUICtrlSetState($m_new_power, $GUI_ENABLE)
   EndIf

   ; Write to Config
   FileChangeDir(@ScriptDir)
   Local Const $sFilePath = "settings.txt"
   ; Open the file for writing (overwrite current) and store the handle to a variable.
   Local $hFileOpen = FileOpen($sFilePath, $FO_OVERWRITE)
   If $hFileOpen = -1 Then
	  MsgBox($MB_SYSTEMMODAL, "", "An error occurred whilst writing "&$sFilePath)
	  Return False
   EndIf

    ; Write data to the file using the handle returned by FileOpen.
	FileWriteLine($hFileOpen, "AccelMode = " & _ConvertAccelMode(GUICtrlRead($m_new_accelmode)))
    FileWriteLine($hFileOpen, "Sensitivity = " & GUICtrlRead($m_new_sens))
    FileWriteLine($hFileOpen, "Acceleration = " & GUICtrlRead($m_new_accel))
    FileWriteLine($hFileOpen, "SensitivityCap = " & GUICtrlRead($m_new_senscap))
    FileWriteLine($hFileOpen, "Offset = " & GUICtrlRead($m_new_offset))
    FileWriteLine($hFileOpen, "Power = " & GUICtrlRead($m_new_power))
    FileWriteLine($hFileOpen, "Pre-ScaleX = " & GUICtrlRead($m_new_prexscale))
    FileWriteLine($hFileOpen, "Pre-ScaleY = " & GUICtrlRead($m_new_preyscale))
    FileWriteLine($hFileOpen, "Post-ScaleX = " & GUICtrlRead($m_new_postxscale))
    FileWriteLine($hFileOpen, "Post-ScaleY = " & GUICtrlRead($m_new_postyscale))
    FileWriteLine($hFileOpen, "AngleAdjustment = " & GUICtrlRead($m_new_angle))
    FileWriteLine($hFileOpen, "AngleSnapping = " & GUICtrlRead($m_new_anglesnap))
    FileWriteLine($hFileOpen, "SpeedCap = " & GUICtrlRead($m_new_speedcap))
    FileWriteLine($hFileOpen, "FancyOutput = 0")

    ; Close the handle returned by FileOpen.
    FileClose($hFileOpen)



   If BitAND(GUICtrlRead($m_new_driverenabled), $GUI_CHECKED) = $GUI_CHECKED Then
	  Local $process = ProcessList($accelExeName)
	  Run($accelExeName, "", @SW_HIDE)
	  Sleep(20) ; Hacky-est bullshit ever.
	  For $i = 1 To $process[0][0]
		 ProcessClose($process[$i][1])
	  Next
   Else
	  _KillAllAccelProcesses()
   EndIf

If $silentsuccess = 0 Then
	  If BitAND(GUICtrlRead($autoprofilecheckbox), $GUI_CHECKED) = $GUI_CHECKED OR BitAND(GUICtrlRead($manualprofilecheckbox), $GUI_CHECKED) = $GUI_CHECKED Then
		 MsgBox(0x40, "Success", "Successfully updated settings.txt." & @CRLF & "Note that your .profile was not updated.  Click Save at the top to save that too.", 8, $GUI)
	  Else
		 MsgBox(0x40, "Success", "Successfully updated settings.txt.", 3, $GUI)
	  EndIf
   EndIf
   _Draw_Graph()
   Return 0
EndFunc

Func _ReadValsFromConfig() ; Get existing values from the Config

	Local Const $sFilePath = "settings.txt"
    Local $hFileOpen = FileOpen($sFilePath, 0)
    If $hFileOpen = -1 Then
        MsgBox($MB_SYSTEMMODAL, "", "An error occurred when reading " & $sFilePath)
        Return False
    EndIf

   While 1
	  $line = FileReadLine($hFileOpen)
	  If @error = -1 Then ExitLoop
	  $aVariable = StringSplit($line," = ",1)
	  If $aVariable[1] == "AccelMode" Then
		 GUICtrlSetData($m_accelmode, _ConvertAccelMode($aVariable[2]))
		 GUICtrlSetData($m_new_accelmode, _ConvertAccelMode($aVariable[2]))
	  ElseIf $aVariable[1] == "Sensitivity" Then
		 GUICtrlSetData($m_sens, $aVariable[2])
		 GUICtrlSetData($m_new_sens, $aVariable[2])
	  ElseIf $aVariable[1] == "Acceleration" Then
		 GUICtrlSetData($m_accel, $aVariable[2])
		 GUICtrlSetData($m_new_accel, $aVariable[2])
	  ElseIf $aVariable[1] == "SensitivityCap" Then
		 GUICtrlSetData($m_senscap, $aVariable[2])
		 GUICtrlSetData($m_new_senscap, $aVariable[2])
	  ElseIf $aVariable[1] == "Offset" Then
		 GUICtrlSetData($m_offset, $aVariable[2])
		 GUICtrlSetData($m_new_offset, $aVariable[2])
	  ElseIf $aVariable[1] == "Power" Then
		 GUICtrlSetData($m_power, $aVariable[2])
		 GUICtrlSetData($m_new_power, $aVariable[2])
	  ElseIf $aVariable[1] == "Pre-ScaleX" Then
		 GUICtrlSetData($m_prexscale, $aVariable[2])
		 GUICtrlSetData($m_new_prexscale, $aVariable[2])
	  ElseIf $aVariable[1] == "Pre-ScaleY" Then
		 GUICtrlSetData($m_preyscale, $aVariable[2])
		 GUICtrlSetData($m_new_preyscale, $aVariable[2])
	  ElseIf $aVariable[1] == "Post-ScaleX" Then
		 GUICtrlSetData($m_postxscale, $aVariable[2])
		 GUICtrlSetData($m_new_postxscale, $aVariable[2])
	  ElseIf $aVariable[1] == "Post-ScaleY" Then
		 GUICtrlSetData($m_postyscale, $aVariable[2])
		 GUICtrlSetData($m_new_postyscale, $aVariable[2])
	  ElseIf $aVariable[1] == "AngleAdjustment" Then
		 GUICtrlSetData($m_angle, $aVariable[2])
		 GUICtrlSetData($m_new_angle, $aVariable[2])
	  ElseIf $aVariable[1] == "AngleSnapping" Then
		 GUICtrlSetData($m_anglesnap, $aVariable[2])
		 GUICtrlSetData($m_new_anglesnap, $aVariable[2])
	  ElseIf $aVariable[1] == "SpeedCap" Then
		 GUICtrlSetData($m_speedcap, $aVariable[2])
		 GUICtrlSetData($m_new_speedcap, $aVariable[2])
	  EndIf
   WEnd

   FileClose($hFileOpen)

   ;Disable power during natural accel
   If GUICtrlRead($m_new_accelmode) == "Natural" Then
	   GUICtrlSetState($m_new_power, $GUI_DISABLE)
   Else
	   GUICtrlSetState($m_new_power, $GUI_ENABLE)
   EndIf

   _KillAllAccelProcesses()
   Run($accelExeName, "", @SW_HIDE)
   ; Assume the person starting the GUI wants to start the driver as well.  Check the boxes for him.
   GUICtrlSetState($m_driverenabled, $GUI_CHECKED)
   GUICtrlSetState($m_new_driverenabled, $GUI_CHECKED)

EndFunc

Func _WriteProfile($file, $silentsuccess = 0) ; save current settings to $file
   If StringRight($file, 8) <> ".profile" Then $file &= ".profile"

   IniWrite($file,"MouseSettings","AccelMode",GUICtrlRead($m_accelmode))
   IniWrite($file,"MouseSettings","Sensitivity",GUICtrlRead($m_sens))
   IniWrite($file,"MouseSettings","Acceleration",GUICtrlRead($m_accel))
   IniWrite($file,"MouseSettings","SensitivityCap",GUICtrlRead($m_senscap))
   IniWrite($file,"MouseSettings","SpeedCap",GUICtrlRead($m_speedcap))
   IniWrite($file,"MouseSettings","Offset",GUICtrlRead($m_offset))
   IniWrite($file,"MouseSettings","Power",GUICtrlRead($m_power))
   IniWrite($file,"MouseSettings","Pre-ScaleX",GUICtrlRead($m_prexscale))
   IniWrite($file,"MouseSettings","Pre-ScaleY",GUICtrlRead($m_preyscale))
   IniWrite($file,"MouseSettings","Post-ScaleX",GUICtrlRead($m_postxscale))
   IniWrite($file,"MouseSettings","Post-ScaleY",GUICtrlRead($m_postyscale))
   IniWrite($file,"MouseSettings","AngleSnap",GUICtrlRead($m_anglesnap))
   IniWrite($file,"MouseSettings","Angle",GUICtrlRead($m_angle))

   If BitAND(GUICtrlRead($m_new_driverenabled), $GUI_CHECKED) = $GUI_CHECKED Then
	  IniWrite($file,"MouseSettings","Enabled","1")
   Else
	  IniWrite($file,"MouseSettings","Enabled","0")
   EndIf

   If $silentsuccess = 0 Then MsgBox(0, "", "Saved " & $file, 3, $GUI)
EndFunc

Func _ReadProfile($file, $silentsuccess = 0) ; read $file to current settings
   If NOT(FileExists($file)) Then
	  MsgBox(0, "Warning", $file & " not found.")
	  Return
   EndIf

   GUICtrlSetData($m_new_accelmode, IniRead($file,"MouseSettings","AccelMode","QuakeLive"))
   GUICtrlSetData($m_new_sens, IniRead($file,"MouseSettings","Sensitivity","1"))
   GUICtrlSetData($m_new_accel, IniRead($file,"MouseSettings","Acceleration","0"))
   GUICtrlSetData($m_new_senscap, IniRead($file,"MouseSettings","SensitivityCap","0"))
   GUICtrlSetData($m_new_speedcap, IniRead($file,"MouseSettings","SpeedCap","0"))
   GUICtrlSetData($m_new_offset, IniRead($file,"MouseSettings","Offset","0"))
   GUICtrlSetData($m_new_power, IniRead($file,"MouseSettings","Power","2"))
   GUICtrlSetData($m_new_prexscale, IniRead($file,"MouseSettings","Pre-ScaleX","1"))
   GUICtrlSetData($m_new_preyscale, IniRead($file,"MouseSettings","Pre-ScaleY","1"))
;   GUICtrlSetData($m_new_postscale, IniRead($file,"MouseSettings","Post-Scale","1")) ; old driver version without separate x/y
   GUICtrlSetData($m_new_postxscale, IniRead($file,"MouseSettings","Post-ScaleX",IniRead($file,"MouseSettings","Post-Scale","1"))) ; if the new value isn't there, get the old, or default to 1
   GUICtrlSetData($m_new_postyscale, IniRead($file,"MouseSettings","Post-ScaleY",IniRead($file,"MouseSettings","Post-Scale","1"))) ; if the new value isn't there, get the old, or default to 1
   GUICtrlSetData($m_new_anglesnap, IniRead($file,"MouseSettings","AngleSnap","0"))
   GUICtrlSetData($m_new_angle, IniRead($file,"MouseSettings","Angle","0"))

   if IniRead($file,"MouseSettings","Enabled","1") = "1" Then
	  GUICtrlSetState($m_new_driverenabled, $GUI_CHECKED)
   Else
	  GUICtrlSetState($m_new_driverenabled, $GUI_UNCHECKED)
   EndIf

   _WriteValsToConfig($silentsuccess)
   _Draw_Graph()
EndFunc

Func _Draw_Graph() ; Refreshes graph, starts with current values (green line) then new values (blue line)
   Local $TestStamp = $GraphStamp ; Save the global variable just incase this changes mid-call (due to global hotkeys)
   Local $prescale, $postscale ; determine X/Y to use per $graph_scale
   _GraphGDIPlus_Clear($Graph)
   _GraphGDIPlus_Set_RangeX($Graph,0,$graph_x,5,1,1)
   _GraphGDIPlus_Set_RangeY($Graph,0,$graph_y,10,1,1)
   _GraphGDIPlus_Set_GridX($Graph,$graph_x/5,0xFF6993BE)
   _GraphGDIPlus_Set_GridY($Graph,$graph_y/10,0xFF6993BE)

   $TransparentPen = int(0xC0 * 0x1000000) ; change the first byte to a number between 0x00 and 0xFF.
   $OpaquePen = int(0xFF * 0x1000000) ; not using this, kind of just for reference.

   ;----- Set line color and size -----
    _GraphGDIPlus_Set_PenSize($Graph,1)

   $Profiles = StringSplit(IniRead($ini_path,"Graph","Profiles","Current\New"), "\")
   $ProfilesChecked = StringSplit(IniRead($ini_path,"Graph","ProfilesChecked","Current\New"), "\")
   $ProfileColors = StringSplit(IniRead($ini_path,"Graph","ProfileColors","00FF00\0000FF"), "\")

   For $i = 1 to $ProfilesChecked[0] Step 1
	  If $ProfilesChecked[$i] = "New" or $ProfilesChecked[$i] = "Current" Then ContinueLoop ; skip these since we already covered them
	  If $CurrentProfile = $ProfilesChecked[$i] and StringRight(GuiCtrlRead($ProfileLabel),1) <> "*" Then ContinueLoop ; Skip this profile since it's the current
	  $file = $file_path & $ProfilesChecked[$i]
	  if NOT(FileExists($file)) then ContinueLoop ; don't load deleted profiles

	  $accelmode = IniRead($file, "MouseSettings","AccelMode","QuakeLive")
	  $sens = IniRead($file,"MouseSettings","Sensitivity","1")
	  $accel = IniRead($file,"MouseSettings","Acceleration","0")
	  $senscap = IniRead($file,"MouseSettings","SensitivityCap","0")
	  $speedcap = IniRead($file,"MouseSettings","SpeedCap","0")
	  $offset = IniRead($file,"MouseSettings","Offset","0")
	  $power = IniRead($file,"MouseSettings","Power","2")
	  if $graph_scale = "X" then
		 $prescale = IniRead($file,"MouseSettings","Pre-ScaleX","1")
		 $postscale = IniRead($file,"MouseSettings","Post-ScaleX",IniRead($file,"MouseSettings","Post-Scale","1"))
	  Else
		 $prescale = IniRead($file,"MouseSettings","Pre-ScaleY","1")
		 $postscale = IniRead($file,"MouseSettings","Post-ScaleY",IniRead($file,"MouseSettings","Post-Scale","1"))
	  EndIf
	  $driverenabled = IniRead($file, "MouseSettings", "Enabled", "0")

	  For $j = 1 to $ProfileColors[0] Step 1
		 if $Profiles[$j] = $ProfilesChecked[$i] Then _GraphGDIPlus_Set_PenColor($Graph, $TransparentPen + Dec($ProfileColors[$j])) ; AARRGGBB
	  Next

	  $First = True
	  For $j = 0 to $graph_x Step $graph_x/$graphdensity
		 If $GraphStamp <> $TestStamp Then Return
		 If $driverenabled = 1 Then
			$y = _MouseInputToOutput($j, $accelmode, $sens, $accel, $senscap, $offset, $power, $prescale, $postscale, $speedcap)
		 Else
			$y = 1
		 EndIf
		 If $First = True Then _GraphGDIPlus_Plot_Start($Graph,$j,$y)
		 $First = False
		 _GraphGDIPlus_Plot_Line($Graph,$j,$y)
	  Next

   Next

   if _ArraySearch($ProfilesChecked, "Current") <> -1 Then
	  _GraphGDIPlus_Set_PenColor($Graph,$TransparentPen + Dec($ProfileColors[1])) ; AARRGGBB
	   ;----- draw lines -----
	  $First = True
	  if $graph_scale = "X" then
		 $prescale = GUICtrlRead($m_prexscale)
		 $postscale = GUICtrlRead($m_postxscale)
	  Else
		 $prescale = GUICtrlRead($m_preyscale)
		 $postscale = GUICtrlRead($m_postyscale)
	  EndIf
	  For $i = 0 to $graph_x Step $graph_x/$graphdensity
		 If $GraphStamp <> $TestStamp Then Return ; if the global variable changed since we started, stop updating.
		 If BitAND(GUICtrlRead($m_driverenabled), $GUI_CHECKED) = $GUI_CHECKED Then
			$y = _MouseInputToOutput($i, GUICtrlRead($m_accelmode), GUICtrlRead($m_sens), GUICtrlRead($m_accel), GUICtrlRead($m_senscap), GUICtrlRead($m_offset), GUICtrlRead($m_power), $prescale, $postscale, GUICtrlRead($m_speedcap))
		 Else
			$y = 1
		 EndIf
		 If $First = True Then _GraphGDIPlus_Plot_Start($Graph,$i,$y)
		 $First = False
		 _GraphGDIPlus_Plot_Line($Graph,$i,$y)
	  Next
   EndIf

   if _ArraySearch($ProfilesChecked, "New") <> -1 Then
	  _GraphGDIPlus_Set_PenColor($Graph, $TransparentPen + Dec($ProfileColors[2])) ; AARRGGBB
	  $First = True
	  if $graph_scale = "X" then
		 $prescale = GUICtrlRead($m_new_prexscale)
		 $postscale = GUICtrlRead($m_new_postxscale)
	  Else
		 $prescale = GUICtrlRead($m_new_preyscale)
		 $postscale = GUICtrlRead($m_new_postyscale)
	  EndIf
	  For $i = 0 to $graph_x Step $graph_x/$graphdensity
		 If $GraphStamp <> $TestStamp Then Return
		 If BitAND(GUICtrlRead($m_new_driverenabled), $GUI_CHECKED) = $GUI_CHECKED Then
		   $y = _MouseInputToOutput($i, GUICtrlRead($m_new_accelmode), GUICtrlRead($m_new_sens), GUICtrlRead($m_new_accel), GUICtrlRead($m_new_senscap), GUICtrlRead($m_new_offset), GUICtrlRead($m_new_power), $prescale, $postscale, GUICtrlRead($m_new_speedcap))
		 Else
			$y = 1
		 EndIf
		 If $First = True Then _GraphGDIPlus_Plot_Start($Graph,$i,$y)
		 $First = False
		 _GraphGDIPlus_Plot_Line($Graph,$i,$y)
	  Next
   EndIf

   _GraphGDIPlus_Refresh($Graph)


EndFunc

Func _MouseInputToOutput($input, $accelmode, $sens, $accel, $senscap, $offset, $power, $prescale, $postscale, $speedcap) ; Calculate the effective sensitivity given an input mouse delta and mouse parameters

   Local $output, $rate, $a

   $output = $input ; effectively povohat's dx and dy combined into one var

   $output *= $prescale ; dx *= devExt->preScaleX; dy *= devExt->preScaleY;

   If ($speedcap > 0 AND $output > $speedcap) Then
	  $output = $speedcap ; much simpler in one dimension
   EndIf


   $accelsens = $sens
   $a = $senscap - $sens
   If $accel > 0 Then
	  $rate = $output / $frametime_ms
	  $rate -= $offset
	  if $rate > 0 Then
		  Switch $accelmode
			  Case "QuakeLive"
				  $rate *= $accel
				  $power -= 1
				  if $power < 0 Then	$power = 0
				  $accelsens += Exp($power * Log($rate))
			  Case "Natural"
				  $rate *= $accel
				  $rate /= Abs($a)
				  $rate *= -1
				  $accelsens += $a - ($a * exp($rate))
		  EndSwitch
	  EndIf
	  if $senscap > 0 AND $accelsens > $senscap Then $accelsens = $senscap
   EndIf
   $accelsens /= $sens
   $output *= $accelsens

   $output *= $postscale

   $output /= $input ; Divide by the original input to determine sensitivity

   return $output
EndFunc

#cs
Func _MouseInputToOutput($input, $sens, $accel, $senscap, $offset, $power, $prescale, $postscale, $speedcap) ; Calculate the effective sensitivity given an input mouse delta and mouse parameters

   Local $output, $rate
   $output = $sens * $prescale; start with sens

   If $accel > 0 Then
	  $rate = $input / $frametime_ms
	  $rate -= $offset
	  if $rate > 0 Then
		 $rate *= $accel
		 $power -= 1
		 if $power < 0 Then	$power = 0
		 $output += Exp($power * Log($rate))
		 if $senscap > 0 AND $output > $senscap Then $output = $senscap
	  EndIf
   EndIf
   $output /= $sens

   If ($speedcap > 0 AND $output*$input > $speedcap) Then
	  $output = $speedcap / $input
   EndIf

   $output *= $postscale

   return $output
EndFunc
#ce


Func _Exit()
   If BitAND(GUICtrlRead($autoprofilecheckbox), $GUI_CHECKED) = $GUI_CHECKED Then
	  if MsgBox(0x24, "Close Intercept Mouse Accel Filter Config?", "Automatic Profile Switching only works while this process is running.  Are you sure you want to close this program?", 0, $GUI) = 6 Then
		 _WriteIni()
		 _GraphGDIPlus_Delete($GUI,$Graph)
		 _KillAllAccelProcesses()
		 Exit
	  EndIf
	  ElseIf BitAND(GUICtrlRead($manualprofilecheckbox), $GUI_CHECKED) = $GUI_CHECKED Then
	  if MsgBox(0x24, "Close Intercept Mouse Accel Filter Config?", "Global Hotkey Switching only works while this process is running.  Are you sure you want to close this program?", 0, $GUI) = 6 Then
		 _UnSetHotkeys()
		 _WriteIni()
		 _KillAllAccelProcesses()
		 _GraphGDIPlus_Delete($GUI,$Graph)
		 Exit
	  EndIf
   Else
	  _WriteIni()
	  _GraphGDIPlus_Delete($GUI,$Graph)
	  _KillAllAccelProcesses()
	  Exit
   EndIf
EndFunc

Func _ScaleOption() ; Draw the radio buttons to pick which pre-scale to use for the graph
   Local $tempPos = WinGetPos("Intercept Mouse Accel Filter Config")
   $PreScaleGUI = GUICreate("Scale Selector", 160, 100, $tempPos[0]+50, $tempPos[1]+50, -1, -1, $GUI)

   GUICtrlCreateLabel("Which dimension should be plotted on the graph?", 10, 10, 150, 30)
   $XRadio = GUICtrlCreateRadio("X", 10, 36)
   $YRadio = GUICtrlCreateRadio("Y", 50, 36)
   $OkayButton = GUICtrlCreateButton("Okay", 10, 60)
   $CancelButton =  GUICtrlCreateButton("Cancel", 50, 60)
   If $graph_scale = "Y" Then
	  GUICtrlSetState($YRadio, $GUI_CHECKED)
   Else
	  GUICtrlSetState($XRadio, $GUI_CHECKED)
   EndIf
   GUISetState()

   While 1
	  $msg = GUIGetMsg()
	  Select
	  Case $msg = $GUI_EVENT_CLOSE OR $msg = $CancelButton
			GUIDelete($PreScaleGUI)
			ExitLoop
		 Case $msg = $OkayButton
			If BitAND(GUICtrlRead($XRadio), $GUI_CHECKED) = $GUI_CHECKED Then
			   IniWrite($ini_path,"Graph","Scale","X")
			Else
			   IniWrite($ini_path,"Graph","Scale","Y")
			EndIf
			GUIDelete($PreScaleGUI)
			ExitLoop
	  EndSelect
   WEnd
EndFunc

Func _Restore()
   GuiSetState(@SW_Show, $GUI)
   WinSetState("[TITLE:Intercept Mouse Accel Filter Config]", "", @SW_RESTORE)
   TraySetState(2) ; hide
EndFunc

Func _SetHotkeys()
   $manualtriggerarray = StringSplit($ManualTriggers,"\")
   $manualactivearray = StringSplit($ManualActives,"\")

   for $i = 1 To $manualtriggerarray[0] Step 1
	  if $manualactivearray[$i] = "Yes" Then HotKeySet($manualtriggerarray[$i], "_HandleHotkey")
   Next
EndFunc

Func _UnSetHotkeys()
   $manualtriggerarray = StringSplit($ManualTriggers,"\")
   $manualactivearray = StringSplit($ManualActives,"\")

   for $i = 1 To $manualtriggerarray[0] Step 1
	  if $manualactivearray[$i] = "Yes" Then HotKeySet($manualtriggerarray[$i])
   Next
EndFunc

Func _SendEx($ss, $warn = "")
   ;Send the string $ss after the Shift Alt and Ctrl keys are released. Optionally give a warning after 1 sec if any of those keys are still down.
   ;Requires misc.au3 to be included in the script for the _IsPressed function.
	Local $iT = TimerInit()

	While _IsPressed("10") Or _IsPressed("11") Or _IsPressed("12")
		If $warn <> "" And TimerDiff($iT) > 1000 Then
			MsgBox(262144, "Warning", $warn)
		EndIf
		Sleep(50)
	WEnd
	Send($ss)
EndFunc

Func _HandleHotkey()
   $HotKey = @HotKeyPressed ; Used to make sure we're still looking at the right hotkey that was pressed
   HotKeySet($HotKey) ; Unset the hotkey so we can send it as a normal key
   _SendEx($HotKey) ; Send as normal key
   HotKeySet($HotKey, "_HandleHotkey") ; Re-set hotkey

   If $HotKey <> @HotKeyPressed Then Return ; If the user pressed another hotkey while blocking us from running (by holding a modifier), don't bother running this profile.

   $manualprofilearray = StringSplit($ManualProfiles,"\")
   $manualtriggerarray = StringSplit($ManualTriggers,"\")
   $manualactivearray = StringSplit($ManualActives,"\")

   for $i = 1 To $manualprofilearray[0] Step 1
	  If $manualtriggerarray[$i] = $HotKey and $manualactivearray[$i] = "Yes" Then
		 If $CurrentProfile = $manualprofilearray[$i] Then ExitLoop
		 $CurrentProfile = $manualprofilearray[$i]
		 $GraphStamp += 1
		 If $GraphStamp >= 1000 Then $GraphStamp = 0
		 GUICtrlSetData($ProfileLabel, "Current Profile: " & $CurrentProfile)
		 _ReadProfile($file_path & $manualprofilearray[$i], 1)
		 ExitLoop
	  EndIf
   Next
EndFunc

Func _ToggleGlobalHotkeys()
   If BitAND(GUICtrlRead($manualprofilecheckbox), $GUI_CHECKED) = $GUI_CHECKED Then
	  $ManualProfiles = IniRead($ini_path,"HotkeySettings","Profiles","")
	  $ManualTriggers = IniRead($ini_path,"HotkeySettings","Triggers","")
	  $ManualActives = IniRead($ini_path,"HotkeySettings","Active","")
	  if StringLen($ManualProfiles) = 0 Then
		 MsgBox(0,"Global Hotkeys", "First, save some hotkeys.  Then click on Profiles -> Manage Global Hotkeys to configure this option.")
		 GUICtrlSetState($manualprofilecheckbox, $GUI_UNCHECKED)
	  Else
		 GUICtrlSetState($autoprofilecheckbox, $GUI_DISABLE)
		 _SetHotkeys()
	  EndIf
   Else
	  GUICtrlSetState($autoprofilecheckbox, $GUI_ENABLE)
	  _UnSetHotkeys()
   EndIf
EndFunc

Func _GlobalHKToggleToggle() ; Key binding that turns on/off global hot keys (same as clicking checkbox)
   If BitAND(GUICtrlRead($autoprofilecheckbox), $GUI_UNCHECKED) = $GUI_UNCHECKED Then
	  If BitAND(GUICtrlRead($manualprofilecheckbox), $GUI_CHECKED) = $GUI_CHECKED Then
		 GUICtrlSetState($manualprofilecheckbox, $GUI_UNCHECKED)
	  Else
		 GUICtrlSetState($manualprofilecheckbox, $GUI_CHECKED)
	  EndIf
	  _ToggleGlobalHotkeys()
   EndIf
EndFunc

Func WM_NOTIFY($hWnd, $iMsg, $wParam, $lParam) ; Function for handling hyperlink click
    Local $tNMLINK = DllStructCreate($tagNMLINK, $lParam)
    Local $hFrom = DllStructGetData($tNMLINK, "hWndFrom")
    Local $ID = DllStructGetData($tNMLINK, "Code")

    Switch $hFrom
        Case $hyperlink
            Switch $ID
                Case $NM_CLICK, $NM_RETURN
                    GUICtrlSendToDummy($Dummy, DllStructGetData($tNMLINK, "Link"))
            EndSwitch
    EndSwitch
    Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_NOTIFY

Func _ConfigurationWizard() ; Auto configure settings per user input (DPI and HZ)
   ; Pull in the USB rate and DPI
   Local $newframetime_ms = 0, $cancelled = 0
   While $newframetime_ms <> 0.5 AND $newframetime_ms <> 1 AND $newframetime_ms <> 2 AND $newframetime_ms <> 4 AND $newframetime_ms <> 8 AND $cancelled = 0
	  $newframetime_ms = 1000 / InputBox("USB Rate", "What is your mouse USB refresh rate in Hz? (125, 250, 500, 1000, or 2000) ")
	  $cancelled = @error
   WEnd
   if $cancelled = 0 Then
	  $frametime_ms = $newframetime_ms
   Else
	  Return
   EndIf

   If $mouse_dpi > 0 Then
	  GUICtrlSetData($mousesettings, 1000 / $frametime_ms & "Hz, " & $mouse_dpi & " DPI")
   Else
	  GUICtrlSetData($mousesettings, 1000 / $frametime_ms & "Hz")
   EndIf

   Local $newmouse_dpi = -1, $cancelled = 0
   While $newmouse_dpi < 0 AND $cancelled = 0
	  $newmouse_dpi = InputBox("Mouse DPI", "What is your mouse DPI? (400, 800, 1200, 2400, etc.)")
	  $cancelled = @error
   WEnd
   if $cancelled = 0 Then
	  $mouse_dpi = $newmouse_dpi
   Else
	  Return
   EndIf

   If $mouse_dpi > 0 Then
	  GUICtrlSetData($mousesettings, 1000 / $frametime_ms & "Hz, " & $mouse_dpi & " DPI")
   Else
	  GUICtrlSetData($mousesettings, 1000 / $frametime_ms & "Hz")
   EndIf

   ; default settings for these
   GUICtrlSetData($m_new_senscap, 2)
   GUICtrlSetData($m_new_sens, 1)
   GUICtrlSetData($m_new_speedcap, 0)
   GUICtrlSetData($m_new_offset, 0)
   GUICtrlSetData($m_new_power, 2)
   GUICtrlSetData($m_new_prexscale, 1)
   GUICtrlSetData($m_new_preyscale, 1)
   GUICtrlSetData($m_new_anglesnap, 0)
   GUICtrlSetData($m_new_angle, 0)

;   GUICtrlSetData($m_new_accel, 69/($mouse_dpi*$frametime_ms))
   GUICtrlSetData($m_new_accel, 69/$mouse_dpi)
   GUICtrlSetData($m_new_postxscale, 690/$mouse_dpi)
   GUICtrlSetData($m_new_postyscale, 690/$mouse_dpi)



   $graph_y = 690/$mouse_dpi*3
   $graph_x = 2/69*$mouse_dpi*$frametime_ms

   If _WriteValsToConfig(1) = 0 and $CurrentProfile <> "" Then GUICtrlSetData($ProfileLabel, "Current Profile: " & $CurrentProfile & " *")
   _Draw_Graph()

   MsgBox(0, "Success!", 'Sample accel settings have been provided based on your input.  Give it a test!  Tweak the post-scale settings to affect your starting mouse sensitivity.  Acceleration determines how quickly your sensitivity grows.  Sensitivity cap is a multiplier of how much higher the sensitivity will go from its starting point.'&@CRLF&@CRLF&'You can run this wizard again from the File menu.')

EndFunc

Func _Main() ; Draw and handle the GUI

   Opt("TrayOnEventMode",1)
   Opt("TrayMenuMode",3)
   TraySetOnEvent($TRAY_EVENT_PRIMARYDOUBLE,"_Restore")

   TrayCreateItem("Show Settings")
   TrayItemSetOnEvent(-1,"_Restore")
   TrayCreateItem("Exit")
   TrayItemSetOnEvent(-1, "_Exit")

   TraySetState()

   $GUI = GUICreate("Intercept Mouse Accel Filter Config",710,530,-1, -1 , BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPSIBLINGS))
   GUISetState()
   Opt("GUICloseOnESC", 0)

   $style = _WinAPI_GetWindowLong($GUI, $GWL_STYLE)
   If BitAnd($style,BitOr($WS_SIZEBOX,$WS_MAXIMIZEBOX)) Then _WinAPI_SetWindowLong($GUI,$GWL_STYLE,BitXOR($style,$WS_SIZEBOX,$WS_MAXIMIZEBOX))

   $filemenu = GUICtrlCreateMenu("&File")
   $wizardoption = GUICtrlCreateMenuItem("Configuration &Wizard", $filemenu)
   $usbitem = GUICtrlCreateMenuItem("Set &USB refresh rate", $filemenu)
   $dpiitem = GUICtrlCreateMenuItem("Set Mouse &DPI (for reference only)", $filemenu)
   GUICtrlCreateMenuItem("", $filemenu, 3) ; create a separator line
   $exititem = GUICtrlCreateMenuItem("E&xit", $filemenu)

   $settingsmenu = GUICtrlCreateMenu("&Settings")
   $graphoptions = GUICtrlCreateMenuItem("Change &Graph settings", $settingsmenu)
   $prescaleitem = GUICtrlCreateMenuItem("Choose which (X|Y) to plot for &Pre/Post-Scale", $settingsmenu)
   GUICtrlCreateMenuItem("", $settingsmenu, 2) ; create a separator line
   $lockpostscaleitem = GUICtrlCreateMenuItem("Lock Post-Scale Y to Post-Scale X",$settingsmenu)
   $accelscaleitem = GUICtrlCreateMenuItem("Scale Accel with Post-Scale X",$settingsmenu)
   $senscapscaleitem = GUICtrlCreateMenuItem("Scale SensCap with Post-Scale X",$settingsmenu)
   GUICtrlCreateMenuItem("", $settingsmenu, 6) ; create a separator line
   $lockprescaleitem = GUICtrlCreateMenuItem("Lock Pre-Scale Y to Pre-Scale X",$settingsmenu)
   $accelscaleitem2 = GUICtrlCreateMenuItem("Scale Accel with Pre-Scale X",$settingsmenu)
   $senscapscaleitem2 = GUICtrlCreateMenuItem("Scale SensCap with Pre-Scale X",$settingsmenu)

   $profilesmenu = GUICtrlCreateMenu("&Profiles")
   $autoprofileoptionsitem = GUICtrlCreateMenuItem("Manage &Automatic Profiles", $profilesmenu)
   $manualprofileoptionsitem = GUICtrlCreateMenuItem("Manage &Global Hotkeys", $profilesmenu)


   ;GUICtrlSetState(-1, $GUI_UNCHECKED) ; FIXME: What the hell was this doing here?

   $helpmenu = GUICtrlCreateMenu("&Help")
   $blogoption = GUICtrlCreateMenuItem("Mouse Accel &Blog (for this driver/program)", $helpmenu)
   $mousesensweboption = GUICtrlCreateMenuItem("Mouse-&Sensitivity.com (same sens, different game)", $helpmenu)

   ; Blog link - moved to the "Help" menu.
;~    $hyperlink = _GUICtrlSysLink_Create($GUI, 'Need more help?  Want to see if anything is new?  Check out the <A HREF="http://mouseaccel.blogspot.com">blog!</a>', 330, 15, 380, 20)
;~    $Dummy = GUICtrlCreateDummy()
;~    GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY")

   ; Draw the settings labels/inputs
   Local $widthCell, $iOldOpt
   $iOldOpt = Opt("GUICoordMode", 2)

   $widthCell = 90
   $heightCell = 5
   GUISetFont (9, 800)
   GUICtrlCreateLabel("Driver Settings", 10, 70, $widthCell) ; first cell 70 width
   GUICtrlCreateLabel("New", 0, -1) ; next Cell
   GUICtrlCreateLabel("Current", 0, -1) ; next Cell
   GUISetFont (9, 400)
   GUICtrlCreateLabel("AccelMode", -3 * $widthCell, $heightCell) ; next line
   $m_new_accelmode = GUICtrlCreateCombo("QuakeLive", 0, -1) ; same line, next cell
   GUICtrlSetData($m_new_accelmode, "Natural")
   $m_accelmode = GUICtrlCreateLabel("QuakeLive", 0, -1) ; same line, next cell
   GUICtrlCreateLabel("Sensitivity", -3 * $widthCell, $heightCell) ; next line
   $m_new_sens = GUICtrlCreateInput("1", 0, -1) ; same line, next cell
   $m_sens = GUICtrlCreateLabel("1", 0, -1) ; same line, next cell
   GUICtrlCreateLabel("Acceleration", -3 * $widthCell, $heightCell) ; next line, back a cell
   $m_new_accel = GUICtrlCreateInput("0", 0, -1) ; same line, next cell
   $m_accel = GUICtrlCreateLabel("0", 0, -1) ; same line, next cell
   GUICtrlCreateLabel("Sensitivity Cap", -3 * $widthCell, $heightCell) ; next line, back a cell
   $m_new_senscap = GUICtrlCreateInput("0", 0, -1) ; same line, next cell
   $m_senscap = GUICtrlCreateLabel("0", 0, -1) ; same line, next cell
   GUICtrlCreateLabel("Speed Cap", -3 * $widthCell, $heightCell) ; next line, back a cell
   $m_new_speedcap = GUICtrlCreateInput("0", 0, -1) ; same line, next cell
   $m_speedcap = GUICtrlCreateLabel("0", 0, -1) ; same line, next cell
   GUICtrlCreateLabel("Offset", -3 * $widthCell, $heightCell) ; next line, back a cell
   $m_new_offset = GUICtrlCreateInput("0", 0, -1) ; same line, next cell
   $m_offset = GUICtrlCreateLabel("0", 0, -1) ; same line, next cell
   GUICtrlCreateLabel("Power", -3 * $widthCell, $heightCell) ; next line, back a cell
   $m_new_power = GUICtrlCreateInput("2", 0, -1) ; same line, next cell
   $m_power = GUICtrlCreateLabel("2", 0, -1) ; same line, next cell
   GUICtrlCreateLabel("Pre-Scale X", -3 * $widthCell, $heightCell) ; next line, back a cell
   $m_new_prexscale = GUICtrlCreateInput("1", 0, -1) ; same line, next cell
   $m_prexscale = GUICtrlCreateLabel("1", 0, -1) ; same line, next cell
   GUICtrlCreateLabel("Pre-Scale Y", -3 * $widthCell, $heightCell) ; next line, back a cell
   $m_new_preyscale = GUICtrlCreateInput("1", 0, -1) ; same line, next cell
   $m_preyscale = GUICtrlCreateLabel("1", 0, -1) ; same line, next cell
   GUICtrlCreateLabel("Post-Scale X", -3 * $widthCell, $heightCell) ; next line, back a cell
   $m_new_postxscale = GUICtrlCreateInput("1", 0, -1) ; same line, next cell
   $m_postxscale = GUICtrlCreateLabel("1", 0, -1) ; same line, next cell
   GUICtrlCreateLabel("Post-Scale Y", -3 * $widthCell, $heightCell) ; next line, back a cell
   $m_new_postyscale = GUICtrlCreateInput("1", 0, -1) ; same line, next cell
   $m_postyscale = GUICtrlCreateLabel("1", 0, -1) ; same line, next cell
   GUICtrlCreateLabel("AngleSnapping", -3 * $widthCell, $heightCell) ; next line, back a cell
   $m_new_anglesnap = GUICtrlCreateInput("0", 0, -1) ; same line, next cell
   $m_anglesnap = GUICtrlCreateLabel("0", 0, -1) ; same line, next cell
   GUICtrlCreateLabel("Angle", -3 * $widthCell, $heightCell) ; next line, back a cell
   $m_new_angle = GUICtrlCreateInput("0", 0, -1) ; same line, next cell
   $m_angle = GUICtrlCreateLabel("0", 0, -1) ; same line, next cell

;   Local $hToolTip = _GUIToolTip_Create(0, BitOR($_TT_ghTTDefaultStyle, $TTS_BALLOON)); balloon style tooltip
   Local $hToolTip = _GUIToolTip_Create(0); default tooltip
   ;Set the tooltip to last 30 seconds.
   _GUIToolTip_SetDelayTime($hToolTip, $TTDT_AUTOPOP, 30000) ; if I set this to 60 seconds, it seems to go back to 5.
   _GUIToolTip_SetDelayTime($hToolTip, $TTDT_RESHOW, 500) ; don't show a new tooltip till 0.5 secs later
   _GUIToolTip_SetMaxTipWidth($hToolTip, 500)
   Local $h_new_accelmode = GUICtrlGetHandle($m_new_accelmode)
   _GUIToolTip_AddTool($hToolTip, 0, "Select which mode of acceleration to use.", $h_new_accelmode)
   Local $h_new_sens = GUICtrlGetHandle($m_new_sens)
   _GUIToolTip_AddTool($hToolTip, 0, "This value is used for replicating QuakeLive mouse settings.  If you aren't coming from QL, leave this value at 1.", $h_new_sens)
   Local $h_new_accel = GUICtrlGetHandle($m_new_accel)
   _GUIToolTip_AddTool($hToolTip, 0, "Controls how quickly the mouse sensitivity will go up.  Dependent on your mouse DPI and USB refresh rate, as well as Sensitivity, Pre-Scale, Post-Scale, and Power variables.", $h_new_accel)
   Local $h_new_senscap = GUICtrlGetHandle($m_new_senscap)
   _GUIToolTip_AddTool($hToolTip, 0, "Determines where your mouse sensitivity will stop being raised by accel.  Consider it a multiplier off of the post-scale variables (e.g.: sens cap of 2 means accel will at most double your sensitivity).", $h_new_senscap)
   Local $h_new_speedcap = GUICtrlGetHandle($m_new_speedcap)
   _GUIToolTip_AddTool($hToolTip, 0, "Gimmick variable.  This allows you to lock the max cursor speed, causing a serious dropoff in sensitivity.  Recommend leaving this at 0.", $h_new_speedcap)
   Local $h_new_offset = GUICtrlGetHandle($m_new_offset)
   _GUIToolTip_AddTool($hToolTip, 0, "Determines how fast you have to move your mouse before accel kicks in.  Allows you to emulate no accel for slower movements.", $h_new_offset)
   Local $h_new_power = GUICtrlGetHandle($m_new_power)
   _GUIToolTip_AddTool($hToolTip, 0, "The power of the acceleration curve.  2 = linear, 3 = quadratic.  Accepts floats.", $h_new_power)
   Local $h_new_prexscale = GUICtrlGetHandle($m_new_prexscale)
   _GUIToolTip_AddTool($hToolTip, 0, "Flat multiplier for horiztonal movements on top of everything else.  It occurs before other calculations, which makes it scale awkwardly.  HIGHLY RECOMMEND USING POST-SCALE VARIABLES INSTEAD OF PRE-SCALE.", $h_new_prexscale)
   Local $h_new_preyscale = GUICtrlGetHandle($m_new_preyscale)
   _GUIToolTip_AddTool($hToolTip, 0, "Flat multiplier for vertical movements on top of everything else.  It occurs before other calculations, which makes it scale awkwardly.  HIGHLY RECOMMEND USING POST-SCALE VARIABLES INSTEAD OF PRE-SCALE.", $h_new_preyscale)
   Local $h_new_postxscale = GUICtrlGetHandle($m_new_postxscale)
   _GUIToolTip_AddTool($hToolTip, 0, "Flat multiplier for horiztonal movements on top of everything else.  It occurs after other calculations.  Consider these your main variables for changing your sensitivity.", $h_new_postxscale)
   Local $h_new_postyscale = GUICtrlGetHandle($m_new_postyscale)
   _GUIToolTip_AddTool($hToolTip, 0, "Flat multiplier for vertical movements on top of everything else.  It occurs after other calculations.  Consider these your main variables for changing your sensitivity.", $h_new_postyscale)
   Local $h_new_anglesnap = GUICtrlGetHandle($m_new_anglesnap)
   _GUIToolTip_AddTool($hToolTip, 0, "Takes mouse movements that are close to right angles and snaps them to right angles.  Allows for easy drawing of horizontal/vertical lines.", $h_new_anglesnap)
   Local $h_new_angle = GUICtrlGetHandle($m_new_angle)
   _GUIToolTip_AddTool($hToolTip, 0, "Rotation of initial mouse movement.  Intended to correct for oddly placed mouse sensors where straight left/right movement of your mouse doesn't correspond to straight left/right movement of your cursor.", $h_new_angle)


   $iOldOpt = Opt("GUICoordMode", $iOldOpt)

   ; Local $tempPos = ControlGetPos("", "", $m_angle)
   $checkx = 8
   ; $checky = $tempPos[1] + 23
   $checky = 458

   Local $savebutton, $drawbutton, $msg
   ; Draw the checkbox and buttons
   $m_new_driverenabled = GUICtrlCreateCheckbox("Driver Enabled", $checkx, $checky, 106, 20, $BS_RIGHTBUTTON)
   $m_driverenabled = GUICtrlCreateCheckbox("", $checkx+172, $checky, 20, 20, $BS_RIGHTBUTTON)
   ;$style = _WinAPI_GetWindowLong(GUICtrlGetHandle($m_new_driverenabled), $GWL_STYLE)
   ;_WinAPI_SetWindowLong(GUICtrlGetHandle($m_new_driverenabled), $GWL_STYLE, $style+4) ; make this checkbox read-only
   GUICTRLSetState($m_driverenabled, $GUI_DISABLE)
   $drawbutton = GUICtrlCreateButton("Preview Changes", 20, $checky+25)
   $savebutton = GUICtrlCreateButton("Save Changes", 130, $checky+25)

   ;Profile Text
   GUISetFont (9, 800)
   $ProfileLabel = GUICtrlCreateLabel("Current Profile: ", 10, 7, 200, 16)
;   GUICtrlCreateLabel("Profiles", 30, 7)
   GUISetFont (9, 400)
   $openprofilebutton = GUICtrlCreateButton("Open", 10, 25)
   $saveprofilebutton = GUICtrlCreateButton("Save", 47, 25)
   $saveasprofilebutton = GUICtrlCreateButton("Save As", 81, 25)

   GUISetFont (7, 400)
   $autoprofilecheckbox = GUICtrlCreateCheckbox("Auto-Profile Switching", 135, 25, 150, 12)
   $manualprofilecheckbox = GUICtrlCreateCheckbox("Global Hotkey Switching", 135, 40, 150, 12)
   GUISetFont (9, 400)

   _ReadValsFromConfig() ; Get driver values from Config

   Local $firstTimeRunningGUI = 1
   if FileExists($ini_path) then $firstTimeRunningGUI = 0

   _ReadIni() ; Get program settings from settings.ini (or go by defaults if it isn't there)

   Local $graphxpos = 330, $graphypos = 65 ; variables to keep the scale buttons and labels in the right places
   Local $graphwidth = 370, $graphheight = 370

   ; Zoom buttons for graph
   $buttonYscaleup = GUICtrlCreateButton("+", $graphxpos-50, $graphypos+15, 15, 15)
   $buttonYscaleset = GUICtrlCreateButton("...", $graphxpos-50, $graphypos+30, 15, 15)
   $buttonYscaledown = GUICtrlCreateButton("-", $graphxpos-50, $graphypos+45, 15, 15)

   $buttonXscaleup = GUICtrlCreateButton("+", $graphxpos+$graphwidth-55, $graphypos+$graphheight+30, 15, 15)
   $buttonXscaleset = GUICtrlCreateButton("...", $graphxpos+$graphwidth-40, $graphypos+$graphheight+30, 15, 15)
   $buttonXscaledown = GUICtrlCreateButton("-", $graphxpos+$graphwidth-25, $graphypos+$graphheight+30, 15, 15)

   ; Graph Axes
   GUISetFont (7, 400)
   GUICtrlCreateLabel("Effective mouse sensitivity", $graphxpos-80, $graphypos+$graphheight/2-20, 50, 50)
   GUICtrlCreateLabel("Mouse movement in a single update", $graphxpos+$graphwidth/2-65, $graphypos+$graphheight+25)
   GUISetFont (9, 400)

   ; USB polling rate and DPI text
   $mousesettings = GUICtrlCreateLabel("500Hz", $graphxpos+130, $graphypos-17, 100, 16)
   If $mouse_dpi > 0 Then
	  GUICtrlSetData($mousesettings, 1000 / $frametime_ms & "Hz, " & $mouse_dpi & " DPI")
   Else
	  GUICtrlSetData($mousesettings, 1000 / $frametime_ms & "Hz")
   EndIf

   ;----- Create Graph area -----
   $Graph = _GraphGDIPlus_Create($GUI,$graphxpos,$graphypos,$graphwidth,$graphheight,0xFF000000,0xFF88B3DD)

   _Draw_Graph()

   If Not(FileExists($file_path)) Then DirCreate($file_path) ; used for settings.ini and profiles

   Local $AutoProfiles, $AutoTriggers, $AutoActives
   $AutoProfiles = IniRead($ini_path,"ProfileSettings","Profiles","")
   $AutoTriggers = IniRead($ini_path,"ProfileSettings","Triggers","")
   $AutoActives = IniRead($ini_path,"ProfileSettings","Active","")
   $autoprofilearray = StringSplit($AutoProfiles,"\")
   $autotriggerarray = StringSplit($AutoTriggers,"\")
   $autoactivearray = StringSplit($AutoActives,"\")

   HotKeySet("!{F5}", "_GlobalHKToggleToggle")

   Global $ManualProfiles, $ManualTriggers, $ManualActives
   $ManualProfiles = IniRead($ini_path,"HotkeySettings","Profiles","")
   $ManualTriggers = IniRead($ini_path,"HotkeySettings","Triggers","")
   $ManualActives = IniRead($ini_path,"HotkeySettings","Active","")
   $manualprofilearray = StringSplit($ManualProfiles,"\")
   $manualtriggerarray = StringSplit($ManualTriggers,"\")
   $manualactivearray = StringSplit($ManualActives,"\")

   Local $AutoProfileCounter = 0

   if $firstTimeRunningGUI then
	  if MsgBox(68, "First run", "This looks like your first time running this program.  Would you like to run the quick configuration wizard?") == 6 Then
		 _ConfigurationWizard()
	  Else
		 _Draw_Graph()
	  EndIf
   EndIf

   if $CmdLine[0] > 0 and $CmdLine[1] == "-m" Then ; If you start the program with -m, minimize it.
	  GuiSetState(@SW_HIDE)
	  TraySetState(1) ; show
	  TraySetToolTip ("Intercept Mouse Accel Filter Config")
   EndIf

   ; Main GUI Loop
   While 1
	  If BitAND(GUICtrlRead($autoprofilecheckbox), $GUI_CHECKED) = $GUI_CHECKED Then
		 ; Check if we need to switch profiles automatically
		 $AutoProfileCounter += 1 ; counter to prevent CPU usage from spiking to hell
		 if $AutoProfileCounter > 500 Then
			$AutoProfileCounter -= 500
			Local $UseDefault = 1 ; assume we should switch to default unless proven otherwise
			for $i = 1 To $autoprofilearray[0] Step 1
			   If $autoactivearray[$i] = "Yes" AND $CurrentProfile = $autoprofilearray[$i] AND ProcessExists($autotriggerarray[$i]) Then
				  $UseDefault = 0 ; We're on a legit profile, don't switch to default later.
				  ExitLoop
			   EndIf
			   If $autoactivearray[$i] = "Yes" AND $CurrentProfile <> $autoprofilearray[$i] AND ProcessExists($autotriggerarray[$i]) Then
;				  MsgBox(0,"test","Found " & $autotriggerarray[$i] & " to run " & $autoprofilearray[$i])
				  $CurrentProfile = $autoprofilearray[$i]
				  GUICtrlSetData($ProfileLabel, "Current Profile: " & $CurrentProfile)
				  _ReadProfile($file_path & $autoprofilearray[$i], 1)
				  $UseDefault = 0 ; Found a legit profile, don't switch to default later.
				  ExitLoop
			   EndIf
			Next
			If $UseDefault = 1 AND $CurrentProfile <> "default.profile" Then ; We didn't find any profiles to use
			   $CurrentProfile = "default.profile"
			   GUICtrlSetData($ProfileLabel, "Current Profile: " & $CurrentProfile)
			   _ReadProfile($file_path & "default.profile", 1)
			EndIf
		 EndIf
	  EndIf
	  $msg = GUIGetMsg()
	  Select
		 Case $msg = $GUI_EVENT_CLOSE OR $msg = $exititem
		 _Exit()
         Case $msg = $GUI_EVENT_MINIMIZE
            GuiSetState(@SW_HIDE)
            TraySetState(1) ; show
            TraySetToolTip ("Intercept Mouse Accel Filter Config")
		 Case $msg = $savebutton
			If _WriteValsToConfig() = 0 and $CurrentProfile <> "" Then GUICtrlSetData($ProfileLabel, "Current Profile: " & $CurrentProfile & " *")
			_Draw_Graph()
		 Case $msg = $drawbutton
			_Draw_Graph()
		 Case $msg = $buttonYscaleup
			$graph_y /= 1.25
			_Draw_Graph()
		 Case $msg = $buttonYscaledown
			$graph_y *= 1.25
			_Draw_Graph()
		 Case $msg = $buttonXscaleup
			$graph_x /= 1.25
			_Draw_Graph()
		 Case $msg = $buttonXscaledown
			$graph_x *= 1.25
			_Draw_Graph()
		 Case $msg = $buttonYscaleset
			Local $newscale = 0, $cancelled = 0
			While $newscale <= 0 AND $cancelled = 0
			   $newscale = InputBox("Graph Y range", "Please enter the maximum Y range (greater than 0)")
			   $cancelled = @error ; @error gets reset on using Number(), so I save it this way
			   $newscale = Number($newscale)
			WEnd
			If $cancelled = 0 Then
			   $graph_y = $newscale
			   _Draw_Graph()
			EndIf
		 Case $msg = $buttonXscaleset
			Local $newscale = 0, $cancelled = 0
			While $newscale <= 0 AND $cancelled = 0
			   $newscale = InputBox("Graph X range", "Please enter the maximum X range (greater than 0)")
			   $cancelled = @error
			   $newscale = Number($newscale)
			WEnd
			If $cancelled = 0 Then
			   $graph_x = $newscale
			   _Draw_Graph()
			EndIf
		 Case $msg = $wizardoption
			_ConfigurationWizard()
		 Case $msg = $usbitem
			Local $newframetime_ms = 0, $cancelled = 0
			While $newframetime_ms <> 0.5 AND $newframetime_ms <> 1 AND $newframetime_ms <> 2 AND $newframetime_ms <> 4 AND $newframetime_ms <> 8 AND $cancelled = 0
			   $newframetime_ms = 1000 / InputBox("USB Rate", "What is your mouse USB refresh rate in Hz? (125, 250, 500, 1000, or 2000) ")
			   $cancelled = @error
			WEnd
			if $cancelled = 0 Then $frametime_ms = $newframetime_ms
			If $mouse_dpi > 0 Then
			   GUICtrlSetData($mousesettings, 1000 / $frametime_ms & "Hz, " & $mouse_dpi & " DPI")
			Else
			   GUICtrlSetData($mousesettings, 1000 / $frametime_ms & "Hz")
			EndIf
			_Draw_Graph()
		 Case $msg = $dpiitem
			Local $newmouse_dpi = -1, $cancelled = 0
			While $newmouse_dpi < 0 AND $cancelled = 0
			   $newmouse_dpi = InputBox("Mouse DPI", "What is your mouse DPI? (400, 800, 1200, 2400, etc.)")
			   $cancelled = @error
			WEnd
			if $cancelled = 0 Then $mouse_dpi = $newmouse_dpi
			If $mouse_dpi > 0 Then
			   GUICtrlSetData($mousesettings, 1000 / $frametime_ms & "Hz, " & $mouse_dpi & " DPI")
			Else
			   GUICtrlSetData($mousesettings, 1000 / $frametime_ms & "Hz")
			EndIf
		 Case $msg = $senscapscaleitem
			If BitAND(GUICtrlRead($senscapscaleitem), $GUI_CHECKED) = $GUI_CHECKED Then
			  GUICtrlSetState($senscapscaleitem, $GUI_UNCHECKED)
			Else
			  GUICtrlSetState($senscapscaleitem, $GUI_CHECKED)
			EndIf
		 Case $msg = $senscapscaleitem2
			If BitAND(GUICtrlRead($senscapscaleitem2), $GUI_CHECKED) = $GUI_CHECKED Then
			  GUICtrlSetState($senscapscaleitem2, $GUI_UNCHECKED)
			Else
			  GUICtrlSetState($senscapscaleitem2, $GUI_CHECKED)
		   EndIf
		 Case $msg = $accelscaleitem
			If BitAND(GUICtrlRead($accelscaleitem), $GUI_CHECKED) = $GUI_CHECKED Then
			  GUICtrlSetState($accelscaleitem, $GUI_UNCHECKED)
			Else
			  GUICtrlSetState($accelscaleitem, $GUI_CHECKED)
		   EndIf
		 Case $msg = $accelscaleitem2
			If BitAND(GUICtrlRead($accelscaleitem2), $GUI_CHECKED) = $GUI_CHECKED Then
			  GUICtrlSetState($accelscaleitem2, $GUI_UNCHECKED)
			Else
			  GUICtrlSetState($accelscaleitem2, $GUI_CHECKED)
		   EndIf
		 Case $msg = $lockprescaleitem
			If BitAND(GUICtrlRead($lockprescaleitem), $GUI_CHECKED) = $GUI_CHECKED Then
			   GUICtrlSetState($lockprescaleitem, $GUI_UNCHECKED)
			   GUICtrlSetState($m_new_preyscale, $GUI_ENABLE)
			Else
			   GUICtrlSetState($lockprescaleitem, $GUI_CHECKED)
			   GUICtrlSetState($m_new_preyscale, $GUI_DISABLE)
			   GUICtrlSetData($m_new_preyscale, GUICtrlRead($m_new_prexscale))
		   EndIf
		 Case $msg = $lockpostscaleitem
			If BitAND(GUICtrlRead($lockpostscaleitem), $GUI_CHECKED) = $GUI_CHECKED Then
			   GUICtrlSetState($lockpostscaleitem, $GUI_UNCHECKED)
			   GUICtrlSetState($m_new_postyscale, $GUI_ENABLE)
			Else
			   GUICtrlSetState($lockpostscaleitem, $GUI_CHECKED)
			   GUICtrlSetState($m_new_postyscale, $GUI_DISABLE)
			   GUICtrlSetData($m_new_postyscale, GUICtrlRead($m_new_postxscale))
		   EndIf
		 Case $msg = $m_new_postxscale
			If BitAND(GUICtrlRead($senscapscaleitem), $GUI_CHECKED) = $GUI_CHECKED Then
			   GUICtrlSetData($m_new_senscap, Round(GUICtrlRead($m_senscap)*GUICtrlRead($m_postxscale)/GUICtrlRead($m_new_postxscale),4))
			EndIf
			If BitAND(GUICtrlRead($accelscaleitem), $GUI_CHECKED) = $GUI_CHECKED Then
			   GUICtrlSetData($m_new_accel, Round(GUICtrlRead($m_accel)*GUICtrlRead($m_postxscale)/GUICtrlRead($m_new_postxscale),4))
			EndIf
			If BitAND(GUICtrlRead($lockpostscaleitem), $GUI_CHECKED) = $GUI_CHECKED Then
			   GUICtrlSetData($m_new_postyscale, GUICtrlRead($m_new_postxscale))
			EndIf
		 Case $msg = $m_new_prexscale
			If BitAND(GUICtrlRead($senscapscaleitem2), $GUI_CHECKED) = $GUI_CHECKED Then
			   GUICtrlSetData($m_new_senscap, Round(GUICtrlRead($m_senscap)*GUICtrlRead($m_prexscale)/GUICtrlRead($m_new_prexscale),4))
			EndIf
			If BitAND(GUICtrlRead($accelscaleitem2), $GUI_CHECKED) = $GUI_CHECKED Then
			   Local $old, $new, $power, $factor
			   $old = GUICtrlRead($m_prexscale)
			   $new = GUICtrlRead($m_new_prexscale)
			   $power = GUICtrlRead($m_power)
			   $factor = ($old/$new)^$power
;			   MsgBox(0,"Test", "old = "& $old &", new = "& $new &", power = " & $power &", factor = "& $factor &@CRLF)
			   GUICtrlSetData($m_new_accel, Round($factor*GUICtrlRead($m_accel),4))
			EndIf
			If BitAND(GUICtrlRead($lockprescaleitem), $GUI_CHECKED) = $GUI_CHECKED Then
			   GUICtrlSetData($m_new_preyscale, GUICtrlRead($m_new_prexscale))
			EndIf
		 Case $msg = $openprofilebutton
			$file = FileOpenDialog("Open Profile", $file_path, "Profiles (*.profile)|All (*.*)", 3, "", $GUI)
			if @error = 0 Then
			   $CurrentProfile = StringRight($file,StringLen($file)-StringInStr($file, "\", 0, -1))
			   GUICtrlSetData($ProfileLabel, "Current Profile: " & $CurrentProfile)
			   _ReadProfile($file)
			EndIf
		 Case $msg = $saveasprofilebutton
			$file = FileSaveDialog("Save Profile", $file_path, "Profiles (*.profile)|All (*.*)", 18, "", $GUI)
			if @error = 0 Then
			   $CurrentProfile = StringRight($file,StringLen($file)-StringInStr($file, "\", 0, -1))
			   GUICtrlSetData($ProfileLabel, "Current Profile: " & $CurrentProfile)
			   _WriteProfile($file)
			   _Draw_Graph()
			Endif
		 Case $msg = $saveprofilebutton
			if $CurrentProfile = "" Then
			   $file = FileSaveDialog("Save Profile", $file_path, "Profiles (*.profile)|All (*.*)", 18, "", $GUI)
			   if @error = 0 Then
				  $CurrentProfile = StringRight($file,StringLen($file)-StringInStr($file, "\", 0, -1))
				  _WriteProfile($file)
			   Endif
			Else
			   _WriteProfile($file_path & $CurrentProfile)
			EndIf
			GUICtrlSetData($ProfileLabel, "Current Profile: " & $CurrentProfile)
		   _Draw_Graph()
		 Case $msg = $autoprofileoptionsitem
			GUISetState(@SW_DISABLE, $GUI)
			_AutoProfileOptionsGui($GUI, $file_path)
			GUISetState(@SW_ENABLE, $GUI)
			WinActivate("[TITLE:Intercept Mouse Accel Filter Config]", "") ; restore focus to this GUI
			If BitAND(GUICtrlRead($autoprofilecheckbox), $GUI_CHECKED) = $GUI_CHECKED Then
			      $AutoProfiles = IniRead($ini_path,"ProfileSettings","Profiles","")
				  $AutoTriggers = IniRead($ini_path,"ProfileSettings","Triggers","")
				  $AutoActives = IniRead($ini_path,"ProfileSettings","Active","")
				  $autoprofilearray = StringSplit($AutoProfiles,"\")
				  $autotriggerarray = StringSplit($AutoTriggers,"\")
				  $autoactivearray = StringSplit($AutoActives,"\")
			EndIf
		 Case $msg = $manualprofileoptionsitem
			If BitAND(GUICtrlRead($manualprofilecheckbox), $GUI_CHECKED) = $GUI_CHECKED Then _UnSetHotkeys()
			GUISetState(@SW_DISABLE, $GUI)
			_ManualProfileOptionsGui($GUI, $file_path)
			GUISetState(@SW_ENABLE, $GUI)
			WinActivate("[TITLE:Intercept Mouse Accel Filter Config]", "") ; restore focus to this GUI
			If BitAND(GUICtrlRead($manualprofilecheckbox), $GUI_CHECKED) = $GUI_CHECKED Then
			      $ManualProfiles = IniRead($ini_path,"HotkeySettings","Profiles","")
				  $ManualTriggers = IniRead($ini_path,"HotkeySettings","Triggers","")
				  $ManualActives = IniRead($ini_path,"HotkeySettings","Active","")
				  If StringLen($ManualProfiles) = 0 Then
					 GUICtrlSetState($manualprofilecheckbox, $GUI_UNCHECKED)
				  Else
					 _SetHotkeys()
				  EndIf
			EndIf
		 Case $msg = $prescaleitem
			$oldscale = $graph_scale
			GUISetState(@SW_DISABLE, $GUI)
			_ScaleOption()
			GUISetState(@SW_ENABLE, $GUI)
			WinActivate("[TITLE:Intercept Mouse Accel Filter Config]", "") ; restore focus to this GUI
			$graph_scale = IniRead($ini_path,"Graph","Scale","X")
			if $graph_scale <> $oldscale Then	_Draw_Graph()
		 Case $msg = $autoprofilecheckbox
			If BitAND(GUICtrlRead($autoprofilecheckbox), $GUI_CHECKED) = $GUI_CHECKED Then
			   $AutoProfiles = IniRead($ini_path,"ProfileSettings","Profiles","")
			   $AutoTriggers = IniRead($ini_path,"ProfileSettings","Triggers","")
			   $AutoActives = IniRead($ini_path,"ProfileSettings","Active","")
			   $autoprofilearray = StringSplit($AutoProfiles,"\")
			   $autotriggerarray = StringSplit($AutoTriggers,"\")
			   $autoactivearray = StringSplit($AutoActives,"\")
			   if StringLen($AutoProfiles) = 0 Then
				  MsgBox(0,"Auto Profiles", "First, save some profiles.  Then click on Profiles -> Manage Automatic Profiles to configure this option.")
				  GUICtrlSetState($autoprofilecheckbox, $GUI_UNCHECKED)
			   Else
				  GUICtrlSetState($openprofilebutton, $GUI_DISABLE)
				  GUICtrlSetState($manualprofilecheckbox, $GUI_DISABLE)
			   EndIf
			Else
			   GUICtrlSetState($openprofilebutton, $GUI_ENABLE)
			   GUICtrlSetState($manualprofilecheckbox, $GUI_ENABLE)
			EndIf
		 Case $msg = $manualprofilecheckbox
			_ToggleGlobalHotkeys()
		 Case $msg = $graphoptions
			GUISetState(@SW_DISABLE, $GUI)
			_GraphOptionsGui($GUI, $file_path)
			GUISetState(@SW_ENABLE, $GUI)
			WinActivate("[TITLE:Intercept Mouse Accel Filter Config]", "") ; restore focus to this GUI
			_Draw_Graph()
;~ 		 Case $msg = $dummy
;~ 			MsgBox(0,"test",_GUICtrlSysLink_GetItemUrl($hyperlink, GUICtrlRead($Dummy)))
;~ 			ShellExecute(_GUICtrlSysLink_GetItemUrl($hyperlink, GUICtrlRead($Dummy)))
		 Case $msg = $blogoption
			ShellExecute("http://mouseaccel.blogspot.com")
		 Case $msg = $mousesensweboption
			ShellExecute("http://mouse-sensitivity.com")
	  EndSelect
   WEnd
EndFunc