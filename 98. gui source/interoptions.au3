#include "GUISysLink.au3" ; Used for hyperlink in global hotkey config
#include <GUIConstantsEx.au3> ; Used for $GUI_CHECKED/$GUI_UNCHECKED
#include <GuiListView.au3> ; ListView boxes are used in auto/manual profile config
#include <File.au3> ; Used for _FileListToArray in the graph options
#include <Array.au3> ; Used in graph options
#Include <ColorChooser.au3> ; Graph options
#Include <ColorPicker.au3> ; Graph options

Global $hyperlink, $Dummy

Func _GraphOptionsGui($GUI, $file_path) ; Draw and handle the Graph options GUI
   Local $tempPos = WinGetPos("Intercept Mouse Accel Filter Config")
   Local $changesMade = 0
   $ini_path = $file_path & "settings.ini"

   ; Get list of profiles in directory
   $FileList = _FileListToArray($file_path, "*.profile", 1)
   if @Error = 0 Then
	  _ArrayInsert($FileList, 1, "New")
	  _ArrayInsert($FileList, 1, "Current")
	  $FileList[0] += 2
   Else
	  Dim $FileList[3] = [2, "New", "Current"]
   EndIf


   ; Read ini for list of previously checked profiles and colors
   $Profiles = StringSplit(IniRead($ini_path,"Graph","Profiles","Current\New"), "\")
   $ProfilesChecked = StringSplit(IniRead($ini_path,"Graph","ProfilesChecked","Current\New"), "\")
   $ProfileColors = StringSplit(IniRead($ini_path,"Graph","ProfileColors","00FF00\0000FF"), "\")

   $Col1pos = 10
   $Col2pos = 80
   $RowHeight = 23

   $MaxGUIHeight = 10+$RowHeight*($FileList[0]+2)
   $GraphGUI = GUICreate("Graph Settings", 300, $MaxGUIHeight, $tempPos[0]+50, $tempPos[1]+50, -1, -1, $GUI)

   GUISetFont (9, 800)
   GUICtrlCreateLabel("Color", $Col1pos+10, 10)
   GUICtrlCreateLabel("Show Profile", $Col2pos, 10)
   GUISetFont (9, 400)

   Local $CheckBoxArray[$FileList[0]+1], $ColorArray[$FileList[0]+1]
   $CheckboxArray[0] = $ColorArray[0] = $FileList[0]

   ; Create the color pickers and checkboxes
   for $i = 1 To $FileList[0] Step 1
	  $ColorArray[$i] = _GUIColorPicker_Create('', $Col1pos, 10+$RowHeight*($i), 60, 23, 0x50CA1B, BitOR($CP_FLAG_CHOOSERBUTTON, $CP_FLAG_MAGNIFICATION, $CP_FLAG_ARROWSTYLE), 0, -1, -1, 0, $FileList[$i] & ' Color', 'Custom...', '_ColorChooserDialog')
	  $CheckBoxArray[$i] = GUICtrlCreateCheckbox($FileList[$i], $Col2pos, 10+$RowHeight*($i))
	  for $j = 1 To $Profiles[0] Step 1
		 if $Profiles[$j] = $FileList[$i] Then
			_GUIColorPicker_SetColor($ColorArray[$i], Dec($ProfileColors[$j]))
		 EndIf
	  Next
	  $found = 0
	  for $j = 1 To $ProfilesChecked[0] Step 1
		 if $ProfilesChecked[$j] = $FileList[$i] Then
			$found = 1
			GUICtrlSetState($CheckBoxArray[$i], $GUI_CHECKED)
		 EndIf
	  Next
	  if $found = 0 Then GUICtrlSetState($ColorArray[$i], $GUI_DISABLE)
   Next
   GUISetState()

   While 1
	  $msg = GUIGetMsg(1)
	  Select
		 Case $msg[0] = $GUI_EVENT_CLOSE ; OR $msg = $exititem

			$Profiles = ""
			$ProfilesChecked = ""
			$ProfileColors = ""
			for $i = 1 To $FileList[0] Step 1
			   If BitAND(GUICtrlRead($CheckBoxArray[$i]), $GUI_CHECKED) = $GUI_CHECKED Then $ProfilesChecked &= $Filelist[$i]&"\"
			   $Profiles &= $Filelist[$i]&"\"
			   $ProfileColors &= Hex(_GUIColorPicker_GetColor($ColorArray[$i]))&"\"
			   _GUIColorPicker_Delete($ColorArray[$i])
			Next
			if $changesMade = 1 and MsgBox(0x24, "Save Data?", "Would you like to save your changes?", 0, $GraphGUI) = 6 Then
			   IniWrite($ini_path,"Graph","Profiles",StringTrimRight($Profiles,1)) ; stringtrim is to nuke the trailing "\"
			   IniWrite($ini_path,"Graph","ProfilesChecked",StringTrimRight($ProfilesChecked,1)) ; stringtrim is to nuke the trailing "\"
			   IniWrite($ini_path,"Graph","ProfileColors",StringTrimRight($ProfileColors,1)) ; stringtrim is to nuke the trailing "\"
			EndIf
			GUIDelete($GraphGUI)
			ExitLoop
		 Case _ArraySearch($CheckBoxArray, $msg[0]) <> -1 ; Was a checkbox clicked?
			for $i = 1 To $FileList[0] Step 1 ; Find which one
			   if $msg[0] = $CheckBoxArray[$i] Then
				  ;MsgBox(0, "", "Got checkbox " & $i, 0, $GraphGUI)
				  If BitAND(GUICtrlRead($CheckBoxArray[$i]), $GUI_UNCHECKED) = $GUI_UNCHECKED Then
					 GUICtrlSetState($ColorArray[$i], $GUI_DISABLE)
				  Else
					 GUICtrlSetState($ColorArray[$i], $GUI_ENABLE)
				  EndIf
				  $changesMade = 1
			   EndIf
			Next
		 Case _ArraySearch($ColorArray, $msg[0]) <> -1 ; Was a color picker clicked?
			for $i = 1 To $FileList[0] Step 1 ; Find which one
			   if $msg[0] = $ColorArray[$i] Then
				  $changesMade = 1
				  ;MsgBox(0, "", "Got ColorArray " & $i & " with color " & Hex(_GUIColorPicker_GetColor($ColorArray[$i])), 0, $GraphGUI)
			   EndIf
			Next
	  EndSelect
   WEnd
EndFunc

Func _AutoProfileOptionsGui($GUI, $file_path) ; Draw and handle Profile GUI
   Local $tempPos = WinGetPos("Intercept Mouse Accel Filter Config")
   Local $changesMade = 0
   $ini_path = $file_path & "settings.ini"
   $ProfileGUI = GUICreate("Profile Management", 400, 300, $tempPos[0]+50, $tempPos[1]+50, -1, -1, $GUI)

   GuiCtrlCreateLabel("Automatic loading is checked from top to bottom.  If the first exe on the list is running, that profile is loaded.  If no exes listed are running, the default profile is loaded.", 10, 10, 350, 50)

;   $listview = GUICtrlCreateListView("Profile|Trigger|Active?", 10, 60, 200, 150)
   $listview = GUICtrlCreateListView("", 10, 60, 250, 150)
   _GUICtrlListView_InsertColumn($listview, 0, "Profile", 70)
   _GUICtrlListView_InsertColumn($listview, 1, "Trigger", 70)
   _GUICtrlListView_InsertColumn($listview, 2, "Active", 50)

   ;$graphdensity = IniRead($ini_path,"Graph","Density","200")
   Local $profiles = "", $triggers = "", $actives = ""
   $profiles = IniRead($ini_path,"ProfileSettings","Profiles","")
   $triggers = IniRead($ini_path,"ProfileSettings","Triggers","")
   $actives = IniRead($ini_path,"ProfileSettings","Active","")

   $profilearray = StringSplit($profiles,"\")
   $triggerarray = StringSplit($triggers,"\")
   $activearray = StringSplit($actives,"\")

   for $i = 1 To $profilearray[0] Step 1
	  GUICtrlCreateListViewItem($profilearray[$i] & "|" & $triggerarray[$i] & "|" & $activearray[$i], $listview)
   Next

   ; Add New, Delete, Move up, Move down, Change trigger, Toggle active
   $iOldOpt = Opt("GUICoordMode", 2)
   Local $widthCell = 90, $heightCell = 20, $paddingCell = 5

   $addButton = GUICtrlCreateButton("Add New Entry", 10, -1, $widthCell, $heightCell) ; 10 to the right of the listbox, top
   $deleteButton = GUICtrlCreateButton("Delete Entry", -1, $paddingCell, $widthCell, $heightCell) ; same x as last button, but below
   $upButton = GUICtrlCreateButton("Move Up", -1, $paddingCell, $widthCell, $heightCell) ; same x as last button, but below
   $downButton = GUICtrlCreateButton("Move Down", -1, $paddingCell, $widthCell, $heightCell) ; same x as last button, but below
   $triggerButton = GUICtrlCreateButton("Change Trigger", -1, $paddingCell, $widthCell, $heightCell) ; same x as last button, but below
   $activeButton = GUICtrlCreateButton("Toggle Active", -1, $paddingCell, $widthCell, $heightCell) ; same x as last button, but below
   $iOldOpt = Opt("GUICoordMode", $iOldOpt)

   GUISetState()

   If Not(FileExists($file_path&"default.profile")) Then
	  _WriteProfile($file_path&"default.profile", 1)
	  MsgBox(0, "Default Profile", "Your current settings have been saved as 'default.profile' for when no other profile applies.  You can manually load and edit this profile from the main display.")
   EndIf

   While 1
	  $msg = GUIGetMsg()
	  Select
	  Case $msg = $GUI_EVENT_CLOSE ; OR $msg = $exititem
			if $changesMade = 1 Then
			   if MsgBox(0x24, "Save Data?", "Would you like to save your changes?", 0, $ProfileGUI) = 6 Then
				  ;user clicked yes
				  Local $profiles = "", $triggers = "", $actives = ""
				  for $i = 0 To _GUICtrlListView_GetItemCount($listview)-1 Step 1
					 if _GUICtrlListView_GetItemText($listview, $i, 0) = "" Then ContinueLoop
					 $profiles &= _GUICtrlListView_GetItemText($listview, $i, 0)&"\"
					 $triggers &= _GUICtrlListView_GetItemText($listview, $i, 1)&"\"
					 $actives &= _GUICtrlListView_GetItemText($listview, $i, 2)&"\"
				  Next
				  IniWrite($ini_path,"ProfileSettings","Profiles",StringTrimRight($profiles,1)) ; stringtrim is to nuke the trailing "\"
				  IniWrite($ini_path,"ProfileSettings","Triggers",StringTrimRight($triggers,1))
				  IniWrite($ini_path,"ProfileSettings","Active",StringTrimRight($actives,1))
				  ;IniWrite($file,"MouseSettings","Sensitivity",GUICtrlRead($m_sens))
			   EndIf
			EndIf
			GUIDelete($ProfileGUI)
            ExitLoop
		 Case $msg = $addButton
			$file = FileOpenDialog("Open Profile", $file_path, "Profiles (*.profile)|All (*.*)", 3, "", $ProfileGUI)
			if @error = 0 Then
			   $changesMade = 1
			   $shortfilename = StringRight($file,StringLen($file)-StringInStr($file, "\", 0, -1))
			   $trigger = InputBox("Executable Trigger", "What process do you want to trigger this profile? ('notepad.exe')")
			   _GUICtrlListView_InsertItem($listview,$shortfilename, 0)
			   _GUICtrlListView_AddSubItem($listview, 0, $trigger, 1)
			   _GUICtrlListView_AddSubItem($listview, 0, "Yes", 2)
			EndIf
		 Case $msg = $deleteButton
			$changesMade = 1
			_GUICtrlListView_DeleteItemsSelected($listview)
		 Case $msg = $upButton
			$changesMade = 1
			_GUICtrlListView_MoveItems($ProfileGUI, $listview, -1)
		 Case $msg = $downButton
			$changesMade = 1
			_GUICtrlListView_MoveItems($ProfileGUI, $listview)
		 Case $msg = $triggerButton
			$selected = Number(_GUICtrlListView_GetSelectedIndices($listview))
			$trigger = InputBox("Executable Trigger", "What process do you want to trigger this profile? ('notepad.exe')")
			if @error = 0 Then
			   _GUICtrlListView_SetItemText($listview, $selected, $trigger, 1)
			   $changesMade = 1
			EndIf
		 Case $msg = $activeButton
			$changesMade = 1
			$selected = Number(_GUICtrlListView_GetSelectedIndices($listview))
			$selectedActive = _GUICtrlListView_GetItemText($listview,$selected,2)
			if $selectedActive = "Yes" Then
			   _GUICtrlListView_SetItemText($listview, $selected, "No", 2)
			Else
			   _GUICtrlListView_SetItemText($listview, $selected, "Yes", 2)
			EndIf
	  EndSelect
   WEnd
EndFunc

Func _ManualProfileOptionsGui($GUI, $file_path) ; Draw and handle Profile GUI
   Local $tempPos = WinGetPos("Intercept Mouse Accel Filter Config")
   Local $changesMade = 0
   $ini_path = $file_path & "settings.ini"
   $ProfileGUI = GUICreate("Hotkey Management", 400, 300, $tempPos[0]+50, $tempPos[1]+50, -1, -1, $GUI)

   GuiCtrlCreateLabel("Triggers can be set to a specific key.  You can prefix keys with ! to specify ALT, + to specify SHIFT, ^ to specify CTRL, and # to specify WINKEY.  The modifier keys cannot be set as hotkeys.  Other keys such as arrows can be bound by declaring them as {UP}.  Reference:", 10, 10, 350, 53)
   $hyperlink = _GUICtrlSysLink_Create($ProfileGUI, '<A HREF="http://www.autoitscript.com/autoit3/docs/functions/Send.htm">http://www.autoitscript.com/autoit3/docs/functions/Send.htm</a>', 10, 62, 310, 20)
   $Dummy = GUICtrlCreateDummy()
   GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY")
;   GuiCtrlCreateInput("http://www.autoitscript.com/autoit3/docs/functions/Send.htm", 10, 66, 310, 20)
   GuiCtrlCreateLabel("Warning: Improper input as a trigger could crash this program when you turn on Global Hotkeys.  If you experience crashes, check your triggers!", 10, 260, 350, 30)

;   $listview = GUICtrlCreateListView("Profile|Trigger|Active?", 10, 60, 200, 150)
   $listview = GUICtrlCreateListView("", 10, 90, 250, 150)
   _GUICtrlListView_InsertColumn($listview, 0, "Profile", 70)
   _GUICtrlListView_InsertColumn($listview, 1, "Trigger", 70)
   _GUICtrlListView_InsertColumn($listview, 2, "Active", 50)

   ;$graphdensity = IniRead($ini_path,"Graph","Density","200")
   Local $profiles = "", $triggers = "", $actives = ""
   $profiles = IniRead($ini_path,"HotkeySettings","Profiles","")
   $triggers = IniRead($ini_path,"HotkeySettings","Triggers","")
   $actives = IniRead($ini_path,"HotkeySettings","Active","")

   $profilearray = StringSplit($profiles,"\")
   $triggerarray = StringSplit($triggers,"\")
   $activearray = StringSplit($actives,"\")

   for $i = 1 To $profilearray[0] Step 1
	  GUICtrlCreateListViewItem($profilearray[$i] & "|" & $triggerarray[$i] & "|" & $activearray[$i], $listview)
   Next

   ; Add New, Delete, Move up, Move down, Change trigger, Toggle active
   $iOldOpt = Opt("GUICoordMode", 2)
   Local $widthCell = 90, $heightCell = 20, $paddingCell = 5

   $addButton = GUICtrlCreateButton("Add New Entry", 10, -1, $widthCell, $heightCell) ; 10 to the right of the listbox, top
   $deleteButton = GUICtrlCreateButton("Delete Entry", -1, $paddingCell, $widthCell, $heightCell) ; same x as last button, but below
   $upButton = GUICtrlCreateButton("Move Up", -1, $paddingCell, $widthCell, $heightCell) ; same x as last button, but below
   $downButton = GUICtrlCreateButton("Move Down", -1, $paddingCell, $widthCell, $heightCell) ; same x as last button, but below
   $triggerButton = GUICtrlCreateButton("Change Trigger", -1, $paddingCell, $widthCell, $heightCell) ; same x as last button, but below
   $activeButton = GUICtrlCreateButton("Toggle Active", -1, $paddingCell, $widthCell, $heightCell) ; same x as last button, but below
   $iOldOpt = Opt("GUICoordMode", $iOldOpt)

   GUISetState()

   While 1
	  $msg = GUIGetMsg()
	  Select
	  Case $msg = $GUI_EVENT_CLOSE ; OR $msg = $exititem
			if $changesMade = 1 Then
			   if MsgBox(0x24, "Save Data?", "Would you like to save your changes?", 0, $ProfileGUI) = 6 Then
				  ;user clicked yes
				  Local $profiles = "", $triggers = "", $actives = ""
				  for $i = 0 To _GUICtrlListView_GetItemCount($listview)-1 Step 1
					 if _GUICtrlListView_GetItemText($listview, $i, 0) = "" Then ContinueLoop
					 $profiles &= _GUICtrlListView_GetItemText($listview, $i, 0)&"\"
					 $triggers &= _GUICtrlListView_GetItemText($listview, $i, 1)&"\"
					 $actives &= _GUICtrlListView_GetItemText($listview, $i, 2)&"\"
				  Next
				  IniWrite($ini_path,"HotkeySettings","Profiles",StringTrimRight($profiles,1)) ; stringtrim is to nuke the trailing "\"
				  IniWrite($ini_path,"HotkeySettings","Triggers",StringTrimRight($triggers,1))
				  IniWrite($ini_path,"HotkeySettings","Active",StringTrimRight($actives,1))
				  ;IniWrite($file,"MouseSettings","Sensitivity",GUICtrlRead($m_sens))
			   EndIf
			EndIf
			GUIDelete($ProfileGUI)
            ExitLoop
		 Case $msg = $addButton
			$file = FileOpenDialog("Open Profile", $file_path, "Profiles (*.profile)|All (*.*)", 3, "", $ProfileGUI)
			if @error = 0 Then
			   $changesMade = 1
			   $shortfilename = StringRight($file,StringLen($file)-StringInStr($file, "\", 0, -1))
			   $trigger = InputBox("Hotkey Trigger", "What hotkey do you want to trigger this profile? ('1' for 1 key, '^1' for CTRL+1, '+1' for !, '+{SPACE} for shift+spacebar, '{PGUP}' for PageUp key...) ")
			   _GUICtrlListView_InsertItem($listview,$shortfilename, 0)
			   _GUICtrlListView_AddSubItem($listview, 0, $trigger, 1)
			   _GUICtrlListView_AddSubItem($listview, 0, "Yes", 2)
			EndIf
		 Case $msg = $deleteButton
			$changesMade = 1
			_GUICtrlListView_DeleteItemsSelected($listview)
		 Case $msg = $upButton
			$changesMade = 1
			_GUICtrlListView_MoveItems($ProfileGUI, $listview, -1)
		 Case $msg = $downButton
			$changesMade = 1
			_GUICtrlListView_MoveItems($ProfileGUI, $listview)
		 Case $msg = $triggerButton
			$selected = Number(_GUICtrlListView_GetSelectedIndices($listview))
			$trigger = InputBox("Hotkey Trigger", "What hotkey do you want to trigger this profile? ('1' for 1 key, '^1' for CTRL+1, '+1' for !, '+{SPACE} for shift+spacebar, '{PGUP}' for PageUp key...) ")
			if @error = 0 Then
			   _GUICtrlListView_SetItemText($listview, $selected, $trigger, 1)
			   $changesMade = 1
			EndIf
		 Case $msg = $activeButton
			$changesMade = 1
			$selected = Number(_GUICtrlListView_GetSelectedIndices($listview))
			$selectedActive = _GUICtrlListView_GetItemText($listview,$selected,2)
			if $selectedActive = "Yes" Then
			   _GUICtrlListView_SetItemText($listview, $selected, "No", 2)
			Else
			   _GUICtrlListView_SetItemText($listview, $selected, "Yes", 2)
			EndIf
		 Case $msg = $dummy
			ShellExecute(_GUICtrlSysLink_GetItemUrl($hyperlink, GUICtrlRead($Dummy)))
	  EndSelect
   WEnd
EndFunc

Func _GUICtrlListView_MoveItems($hWnd, $vListView, $iDirection=1, $sIconsFile="", $iIconID_Checked=0, $iIconID_UnChecked=0)
;===============================================================================
; Function Name:    _GUICtrlListView_MoveItems()
; Description:      Move selected item(s) in ListView Up or Down.
;
; Parameter(s):     $hWnd               - Window handle of ListView control (can be a Title).
;                   $vListView          - The ID/Handle/Class of ListView control.
;                   $iDirection         - [Optional], define in what direction item(s) will move:
;                                            1 (default) - item(s) will move Next.
;                                           -1 item(s) will move Back.
;                   $sIconsFile         - Icon file to set image for the items (only for internal usage).
;                   $iIconID_Checked    - Icon ID in $sIconsFile for checked item(s).
;                   $iIconID_UnChecked  - Icon ID in $sIconsFile for Unchecked item(s).
;
; Requirement(s):   #include <GuiListView.au3>, AutoIt 3.2.10.0.
;
; Return Value(s):  On seccess - Move selected item(s) Next/Back.
;                   On failure - Return "" (empty string) and set @error as following:
;                                                                  1 - No selected item(s).
;                                                                  2 - $iDirection is wrong value (not 1 and not -1).
;                                                                  3 - Item(s) can not be moved, reached last/first item.
;
; Note(s):          * This function work with external ListView Control as well.
;                   * If you select like 15-20 (or more) items, moving them can take a while :( (depends on how many items moved).
;
; Author(s):        G.Sandler a.k.a CreatoR (<a href='http://creator-lab.ucoz.ru' class='bbc_url' title='External link' rel='nofollow external'>http://creator-lab.ucoz.ru</a>)
;===============================================================================
    Local $hListView = $vListView
    If Not IsHWnd($hListView) Then $hListView = ControlGetHandle($hWnd, "", $hListView)

    Local $aSelected_Indices = _GUICtrlListView_GetSelectedIndices($hListView, 1)
    If UBound($aSelected_Indices) < 2 Then Return SetError(1, 0, "")
    If $iDirection <> 1 And $iDirection <> -1 Then Return SetError(2, 0, "")

    Local $iTotal_Items = ControlListView($hWnd, "", $hListView, "GetItemCount")
    Local $iTotal_Columns = ControlListView($hWnd, "", $hListView, "GetSubItemCount")

    Local $iUbound = UBound($aSelected_Indices)-1, $iNum = 1, $iStep = 1
    Local $iCurrent_Index, $iUpDown_Index, $sCurrent_ItemText, $sUpDown_ItemText
    Local $iCurrent_Index, $iCurrent_CheckedState, $iUpDown_CheckedState

    If ($iDirection = -1 And $aSelected_Indices[1] = 0) Or _
        ($iDirection = 1 And $aSelected_Indices[$iUbound] = $iTotal_Items-1) Then Return SetError(3, 0, "")

    ControlListView($hWnd, "", $hListView, "SelectClear")

    Local $aOldSelected_IDs[1]
    Local $iIconsFileExists = FileExists($sIconsFile)

    If $iIconsFileExists Then
        For $i = 1 To $iUbound
            ReDim $aOldSelected_IDs[UBound($aOldSelected_IDs)+1]
            _GUICtrlListView_SetItemSelected($hListView, $aSelected_Indices[$i], True)
            $aOldSelected_IDs[$i] = GUICtrlRead($vListView)
            _GUICtrlListView_SetItemSelected($hListView, $aSelected_Indices[$i], False)
        Next
        ControlListView($hWnd, "", $hListView, "SelectClear")
    EndIf

    If $iDirection = 1 Then
        $iNum = $iUbound
        $iUbound = 1
        $iStep = -1
    EndIf

    For $i = $iNum To $iUbound Step $iStep
        $iCurrent_Index = $aSelected_Indices[$i]
        $iUpDown_Index = $aSelected_Indices[$i]+1
        If $iDirection = -1 Then $iUpDown_Index = $aSelected_Indices[$i]-1

        $iCurrent_CheckedState = _GUICtrlListView_GetItemChecked($hListView, $iCurrent_Index)
        $iUpDown_CheckedState = _GUICtrlListView_GetItemChecked($hListView, $iUpDown_Index)

        _GUICtrlListView_SetItemSelected($hListView, $iUpDown_Index)

        For $j = 0 To $iTotal_Columns-1
            $sCurrent_ItemText = _GUICtrlListView_GetItemText($hListView, $iCurrent_Index, $j)
            $sUpDown_ItemText = _GUICtrlListView_GetItemText($hListView, $iUpDown_Index, $j)

            _GUICtrlListView_SetItemText($hListView, $iUpDown_Index, $sCurrent_ItemText, $j)
            _GUICtrlListView_SetItemText($hListView, $iCurrent_Index, $sUpDown_ItemText, $j)
        Next

        _GUICtrlListView_SetItemChecked($hListView, $iUpDown_Index, $iCurrent_CheckedState)
        _GUICtrlListView_SetItemChecked($hListView, $iCurrent_Index, $iUpDown_CheckedState)

        If $iIconsFileExists Then
            If $iCurrent_CheckedState = 1 Then
                GUICtrlSetImage(GUICtrlRead($vListView), $sIconsFile, $iIconID_Checked, 0)
            Else
                GUICtrlSetImage(GUICtrlRead($vListView), $sIconsFile, $iIconID_UnChecked, 0)
            EndIf

            If $iUpDown_CheckedState = 1 Then
                GUICtrlSetImage($aOldSelected_IDs[$i], $sIconsFile, $iIconID_Checked, 0)
            Else
                GUICtrlSetImage($aOldSelected_IDs[$i], $sIconsFile, $iIconID_UnChecked, 0)
            EndIf
        EndIf

        _GUICtrlListView_SetItemSelected($hListView, $iUpDown_Index, 0)
    Next

    For $i = 1 To UBound($aSelected_Indices)-1
        $iUpDown_Index = $aSelected_Indices[$i]+1
        If $iDirection = -1 Then $iUpDown_Index = $aSelected_Indices[$i]-1
        _GUICtrlListView_SetItemSelected($hListView, $iUpDown_Index)
    Next
EndFunc

;~ Func WM_NOTIFY($hWnd, $iMsg, $wParam, $lParam) ; Function for handling hyperlink click

;~     Local $tNMLINK = DllStructCreate($tagNMLINK, $lParam)
;~     Local $hFrom = DllStructGetData($tNMLINK, "hWndFrom")
;~     Local $ID = DllStructGetData($tNMLINK, "Code")

;~     Switch $hFrom
;~         Case $hyperlink
;~             Switch $ID
;~                 Case $NM_CLICK, $NM_RETURN
;~                     GUICtrlSendToDummy($Dummy, DllStructGetData($tNMLINK, "Link"))
;~             EndSwitch
;~     EndSwitch
;~     Return $GUI_RUNDEFMSG
;~ EndFunc   ;==>WM_NOTIFY

