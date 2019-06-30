#include-once

#include "Memory.au3"
#include "SendMessage.au3"
#include "SysLinkConstants.au3"
#include "UDFGlobalID.au3"
#include "WinAPI.au3"

; #INDEX# =======================================================================================================================
; Title..........: SysLink
; AutoIt version.: 3.2.3++
; Language.......: English
; Description....: Functions that assist with SysLink control management. The SysLink control provides a convenient way to embed
;                  hypertext links in a window.
;                  Minimum Operating Systems: Windows XP
; Author(s)......: Yashied
; ===============================================================================================================================

; #VARIABLES# ===================================================================================================================
Global $_ghSLLastWnd
Global $Debug_SL = False
; ===============================================================================================================================

; #CONSTANTS# ===================================================================================================================
Global Const $__SYSLINKCONSTANT_ClassName = "SysLink"
Global Const $__SYSLINKCONSTANT_DEFAULT_GUI_FONT = 17
Global Const $__SYSLINKCONSTANT_WM_SETFONT = 0x0030
; ===============================================================================================================================

; #CURRENT# =====================================================================================================================
;_GUICtrlSysLink_Create
;_GUICtrlSysLink_Destroy
;_GUICtrlSysLink_GetIdealHeight
;_GUICtrlSysLink_GetIdealSize
;_GUICtrlSysLink_GetItemEnabled
;_GUICtrlSysLink_GetItemFocused
;_GUICtrlSysLink_GetItemHighlighted
;_GUICtrlSysLink_GetItemID
;_GUICtrlSysLink_GetItemState
;_GUICtrlSysLink_GetItemUrl
;_GUICtrlSysLink_GetItemVisited
;_GUICtrlSysLink_GetText
;_GUICtrlSysLink_HitTest
;_GUICtrlSysLink_HitTestEx
;_GUICtrlSysLink_SetItemEnabled
;_GUICtrlSysLink_SetItemFocused
;_GUICtrlSysLink_SetItemHighlighted
;_GUICtrlSysLink_SetItemID
;_GUICtrlSysLink_SetItemState
;_GUICtrlSysLink_SetItemUrl
;_GUICtrlSysLink_SetItemVisited
;_GUICtrlSysLink_SetText
; ===============================================================================================================================

; #INTERNAL_USE_ONLY# ===========================================================================================================
;__GUICtrlSysLink_GetItem
;__GUICtrlSysLink_SetItem
; ===============================================================================================================================

; #FUNCTION# ====================================================================================================================
; Name...........: _GUICtrlSysLink_Create
; Description....: Creates a SysLink control
; Syntax.........: _GUICtrlSysLink_Create ( $hWnd, $sText, $iX, $iY, $iWidth, $iHeight [, $iStyle = -1 [, $iExStyle = -1]] )
; Parameters.....: $hWnd     - Handle to parent or owner window
;                  $sText    - The text that to be added
;                  $iX       - Horizontal position of the control
;                  $iY       - Vertical position of the control
;                  $iWidth   - Control width
;                  $iHeight  - Control height
;                  $iStyle   - Control style, can be one or more of the following values:
;                  |$LWS_TRANSPARENT    - The background mix mode is transparent
;                  |$LWS_IGNORERETURN   - When the link has keyboard focus and the user presses Enter, the keystroke is ignored by the control and passed to the host dialog box
;                  -
;                  |Vista styles:
;                  -
;                  |$LWS_NOPREFIX       - If the text contains an ampersand, it is treated as a literal character rather than the prefix to a shortcut key
;                  |$LWS_USEVISUALSTYLE - The link is displayed in the current visual style
;                  |$LWS_USECUSTOMTEXT  - An NM_CUSTOMTEXT notification is sent when the control is drawn, so that the application can supply text dynamically
;                  |$LWS_RIGHT          - The text is right-justified
;                  -
;                  |Default: None
;                  |Forced: $WS_CHILD, $WS_VISIBLE
;                  $iExStyle - Control extended style. These correspond to the standard $WS_EX_* constants.
; Return values..: Success   - Handle to the newly created SysLink control
;                  Failure   - 0
; Author.........: Yashied
; Modified.......:
; Remarks........:
; Related........: _GUICtrlSysLink_Destroy
; Link...........:
; Example........: Yes
; ===============================================================================================================================

Func _GUICtrlSysLink_Create($hWnd, $sText, $iX, $iY, $iWidth, $iHeight, $iStyle = -1, $iExStyle = -1)
	If Not IsHWnd($hWnd) Then
		Return SetError(1, 0, 0)
	EndIf
	If $iStyle = -1 Then
		$iStyle = BitOR($__UDFGUICONSTANT_WS_VISIBLE, $__UDFGUICONSTANT_WS_CHILD)
	Else
		$iStyle = BitOR($__UDFGUICONSTANT_WS_VISIBLE, $__UDFGUICONSTANT_WS_CHILD, $iStyle)
	EndIf
	If $iExStyle = -1 Then
		$iExStyle = 0
	EndIf
	Local $nCtrlID = __UDF_GetNextGlobalID($hWnd)
	If @error Then
		Return SetError(@error, @extended, 0)
	EndIf
	Local $hSysLink = _WinAPI_CreateWindowEx($iExStyle, $__SYSLINKCONSTANT_ClassName, $sText, $iStyle, $iX, $iY, $iWidth, $iHeight, $hWnd, $nCtrlID)
	_SendMessage($hSysLink, $__SYSLINKCONSTANT_WM_SETFONT, _WinAPI_GetStockObject($__SYSLINKCONSTANT_DEFAULT_GUI_FONT), True)
	Return $hSysLink
EndFunc   ;==>_GUICtrlSysLink_Create

; #FUNCTION# ====================================================================================================================
; Name...........: _GUICtrlSysLink_Destroy
; Description....: Deletes a SysLink control
; Syntax.........: _GUICtrlSysLink_Destroy ( ByRef $hWnd )
; Parameters.....: $hWnd   - Handle to the SysLink control
; Return values..: Success - True, handle is set to 0
;                  Failure - False
; Author.........: Yashied
; Modified.......:
; Remarks........:
; Related........: _GUICtrlSysLink_Create
; Link...........:
; Example........: Yes
; ===============================================================================================================================

Func _GUICtrlSysLink_Destroy(ByRef $hWnd)
	If $Debug_SL Then
		__UDF_ValidateClassName($hWnd, $__SYSLINKCONSTANT_ClassName)
	EndIf
	If Not _WinAPI_IsClassName($hWnd, $__SYSLINKCONSTANT_ClassName) Then
		Return SetError(2, 2, False)
	EndIf
	Local $Result = 0
	If _WinAPI_InProcess($hWnd, $_ghSLLastWnd) Then
		Local $nCtrlID = _WinAPI_GetDlgCtrlID($hWnd)
		Local $hParent = _WinAPI_GetParent($hWnd)
		$Result = _WinAPI_DestroyWindow($hWnd)
		If Not __UDF_FreeGlobalID($hParent, $nCtrlID) Then
			; Can check for errors, for debug
		EndIf
	Else
		Return SetError(1, 1, False)
	EndIf
	If $Result Then
		$hWnd = 0
	EndIf
	Return $Result <> 0
EndFunc   ;==>_GUICtrlSysLink_Destroy

; #FUNCTION# ====================================================================================================================
; Name...........: _GUICtrlSysLink_GetIdealHeight
; Description....: Retrieves the preferred height of a link for the SysLink control's current width
; Syntax.........: _GUICtrlSysLink_GetIdealHeight ( $hWnd )
; Parameters.....: $hWnd   - Handle to the SysLink control
; Return values..: Success - The preferred height of the link text, in pixels
;                  Failure - 0
; Author.........: Yashied
; Modified.......:
; Remarks........:
; Related........: _GUICtrlSysLink_GetIdealSize
; Link...........:
; Example........: Yes
; ===============================================================================================================================

Func _GUICtrlSysLink_GetIdealHeight($hWnd)
	If $Debug_SL Then
		__UDF_ValidateClassName($hWnd, $__SYSLINKCONSTANT_ClassName)
	EndIf
	Return _SendMessage($hWnd, $LM_GETIDEALHEIGHT)
EndFunc   ;==>_GUICtrlSysLink_GetIdealHeight

; #FUNCTION# ====================================================================================================================
; Name...........: _GUICtrlSysLink_GetIdealSize
; Description....: Retrieves the preferred height of a link for the SysLink control's current width
; Syntax.........: _GUICtrlSysLink_GetIdealSize ( $hWnd [, $iMaxWidth = -1] )
; Parameters.....: $hWnd      - Handle to the SysLink control
;                  $iMaxWidth - The maximum width of the SysLink control, in pixels. (-1) - use the control's current width.
; Return values..: Success    - $tagSIZE structure where the "Y" member of this structure indicates the ideal height of the control for the given width.
;                               It adjusts the "X" member to the amount of space actually needed.
;                  Failure    - 0
; Author.........: Yashied
; Modified.......:
; Remarks........: Minimum Operating Systems: Windows Vista
; Related........: _GUICtrlSysLink_GetIdealHeight
; Link...........:
; Example........: Yes
; ===============================================================================================================================

Func _GUICtrlSysLink_GetIdealSize($hWnd, $iMaxWidth = -1)
	If $Debug_SL Then
		__UDF_ValidateClassName($hWnd, $__SYSLINKCONSTANT_ClassName)
	EndIf
	If $iMaxWidth = -1 Then
		$iMaxWidth = _WinAPI_GetClientWidth($hWnd)
	EndIf
	Local $tSize = DllStructCreate($tagSIZE)
	Local $pSize = DllStructGetPtr($tSize)
	If _SendMessage($hWnd, $LM_GETIDEALSIZE, $iMaxWidth, $pSize) Then
		Return $tSIZE
	EndIf
EndFunc   ;==>_GUICtrlSysLink_GetIdealSize

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __GUICtrlSysLink_GetItem
; Description....: Retrieves some or all of a item's attributes
; Syntax.........: __GUICtrlSysLink_GetItem ( $hWnd, ByRef $tItem )
; Parameters.....: $hWnd   - Handle to the SysLink control
;                  $tItem  - $tagLITEM structure used to request/receive item attributes
; Return values..: Success - True
;                  Failure - False
; Author.........: Paul Campbell (PaulIA)
; Modified.......: Yashied
; Remarks........: This function is used internally and should not normally be called by the end user
; Related........: __GUICtrlSysLink_SetItem
; Link...........:
; Example........:
; ===============================================================================================================================

Func __GUICtrlSysLink_GetItem($hWnd, ByRef $tItem)
	Local $pItem = DllStructGetPtr($tItem)
	Local $iRet
	If _WinAPI_InProcess($hWnd, $_ghSLLastWnd) Then
		$iRet = _SendMessage($hWnd, $LM_GETITEM, 0, $pItem, 0, "wparam", "ptr")
	Else
		Local $iSize = DllStructGetSize($tItem)
		Local $tMem
		Local $pMem = _MemInit($hWnd, $iSize, $tMem)
		_MemWrite($tMem, $pItem)
		$iRet = _SendMessage($hWnd, $LM_GETITEM, 0, $pMem, 0, "wparam", "ptr")
		_MemRead($tMem, $pMem, $pItem, $iSize)
		_MemFree($tMem)
	EndIf
	Return $iRet <> 0
EndFunc   ;==>__GUICtrlSysLink_GetItem

; #FUNCTION# ====================================================================================================================
; Name...........: _GUICtrlSysLink_GetItemEnabled
; Description....: Determines whether the specified link of the SysLink control is enabled
; Syntax.........: _GUICtrlSysLink_GetItemEnabled ( $hWnd [, $iLink = 0] )
; Parameters.....: $hWnd   - Handle to the SysLink control
;                  $iLink  - The zero based link index
; Return values..: Success - True
;                  Failure - False
; Author.........: Yashied
; Modified.......:
; Remarks........:
; Related........: _GUICtrlSysLink_SetItemEnabled
; Link...........:
; Example........: Yes
; ===============================================================================================================================

Func _GUICtrlSysLink_GetItemEnabled($hWnd, $iLink = 0)
	Local $iState = _GUICtrlSysLink_GetItemState($hWnd, $iLink)
	If $iState <> -1 Then
		Return BitAND($LIS_ENABLED, $iState) = $LIS_ENABLED
	EndIf
EndFunc   ;==>_GUICtrlSysLink_GetItemEnabled

; #FUNCTION# ====================================================================================================================
; Name...........: _GUICtrlSysLink_GetItemFocused
; Description....: Determines whether the specified link of the SysLink control is focused
; Syntax.........: _GUICtrlSysLink_GetItemFocused ( $hWnd [, $iLink = 0] )
; Parameters.....: $hWnd   - Handle to the SysLink control
;                  $iLink  - The zero based link index
; Return values..: Success - True
;                  Failure - False
; Author.........: Yashied
; Modified.......:
; Remarks........:
; Related........: _GUICtrlSysLink_SetItemFocused
; Link...........:
; Example........: Yes
; ===============================================================================================================================

Func _GUICtrlSysLink_GetItemFocused($hWnd, $iLink = 0)
	Local $iState = _GUICtrlSysLink_GetItemState($hWnd, $iLink)
	If $iState <> -1 Then
		Return BitAND($LIS_FOCUSED, $iState) = $LIS_FOCUSED
	EndIf
EndFunc   ;==>_GUICtrlSysLink_GetItemFocused

; #FUNCTION# ====================================================================================================================
; Name...........: _GUICtrlSysLink_GetItemHighlighted
; Description....: Determines whether the specified link of the SysLink control is highlighted
; Syntax.........: _GUICtrlSysLink_GetItemHighlighted ( $hWnd [, $iLink = 0] )
; Parameters.....: $hWnd   - Handle to the SysLink control
;                  $iLink  - The zero based link index
; Return values..: Success - True
;                  Failure - False
; Author.........: Yashied
; Modified.......:
; Remarks........:
; Related........: _GUICtrlSysLink_SetItemHighlighted
; Link...........:
; Example........: Yes
; ===============================================================================================================================

Func _GUICtrlSysLink_GetItemHighlighted($hWnd, $iLink = 0)
	Local $iState = _GUICtrlSysLink_GetItemState($hWnd, $iLink)
	If $iState <> -1 Then
		Return BitAND($LIS_HOTTRACK, $iState) = $LIS_HOTTRACK
	EndIf
EndFunc   ;==>_GUICtrlSysLink_GetItemHighlighted

; #FUNCTION# ====================================================================================================================
; Name...........: _GUICtrlSysLink_GetItemID
; Description....: Retrieves the ID of the specified link of the SysLink control
; Syntax.........: _GUICtrlSysLink_GetItemID ( $hWnd [, $iLink = 0] )
; Parameters.....: $hWnd   - Handle to the SysLink control
;                  $iLink  - The zero based link index
; Return values..: Success - The current ID string of the link
;                  Failure - The empty string ("") and sets the @error flag to non-zero
; Author.........: Yashied
; Modified.......:
; Remarks........:
; Related........: _GUICtrlSysLink_SetItemID
; Link...........:
; Example........: Yes
; ===============================================================================================================================

Func _GUICtrlSysLink_GetItemID($hWnd, $iLink = 0)
	If $Debug_SL Then
		__UDF_ValidateClassName($hWnd, $__SYSLINKCONSTANT_ClassName)
	EndIf
	Local $tLITEM = DllStructCreate($tagLITEM)
	DllStructSetData($tLITEM, "Mask", BitOR($LIF_ITEMINDEX, $LIF_ITEMID))
	DllStructSetData($tLITEM, "Link", $iLink)
	If __GUICtrlSysLink_GetItem($hWnd, $tLITEM) Then
		Return DllStructGetData($tLITEM, "ID")
	EndIf
	Return SetError(1, 0, "")
EndFunc   ;==>_GUICtrlSysLink_GetItemID

; #FUNCTION# ====================================================================================================================
; Name...........: _GUICtrlSysLink_GetItemState
; Description....: Retrieves the state of the specified link of the SysLink control
; Syntax.........: _GUICtrlSysLink_GetItemState ( $hWnd [, $iLink = 0] )
; Parameters.....: $hWnd   - Handle to the SysLink control
;                  $iLink  - The zero based link index
; Return values..: Success - The current state of the link ($LIS_*)
;                  Failure - -1
; Author.........: Yashied
; Modified.......:
; Remarks........:
; Related........: _GUICtrlSysLink_SetItemState
; Link...........:
; Example........: Yes
; ===============================================================================================================================

Func _GUICtrlSysLink_GetItemState($hWnd, $iLink = 0)
	If $Debug_SL Then
		__UDF_ValidateClassName($hWnd, $__SYSLINKCONSTANT_ClassName)
	EndIf
	Local $tLITEM = DllStructCreate($tagLITEM)
	DllStructSetData($tLITEM, "Mask", BitOR($LIF_ITEMINDEX, $LIF_STATE))
	DllStructSetData($tLITEM, "Link", $iLink)
	DllStructSetData($tLITEM, "StateMask", BitOR($LIS_ENABLED, $LIS_FOCUSED, $LIS_VISITED, $LIS_HOTTRACK, $LIS_DEFAULTCOLORS))
	If __GUICtrlSysLink_GetItem($hWnd, $tLITEM) Then
		Return DllStructGetData($tLITEM, "State")
	EndIf
	Return -1
EndFunc   ;==>_GUICtrlSysLink_GetItemState

; #FUNCTION# ====================================================================================================================
; Name...........: _GUICtrlSysLink_GetItemUrl
; Description....: Retrieves the URL of the specified link of the SysLink control
; Syntax.........: _GUICtrlSysLink_GetItemUrl ( $hWnd [, $iLink = 0] )
; Parameters.....: $hWnd   - Handle to the SysLink control
;                  $iLink  - The zero based link index
; Return values..: Success - The current URL string of the link
;                  Failure - The empty string ("") and sets the @error flag to non-zero
; Author.........: Yashied
; Modified.......:
; Remarks........:
; Related........: _GUICtrlSysLink_SetItemUrl
; Link...........:
; Example........: Yes
; ===============================================================================================================================

Func _GUICtrlSysLink_GetItemUrl($hWnd, $iLink = 0)
	If $Debug_SL Then
		__UDF_ValidateClassName($hWnd, $__SYSLINKCONSTANT_ClassName)
	EndIf
	Local $tLITEM = DllStructCreate($tagLITEM)
	DllStructSetData($tLITEM, "Mask", BitOR($LIF_ITEMINDEX, $LIF_URL))
	DllStructSetData($tLITEM, "Link", $iLink)
	If __GUICtrlSysLink_GetItem($hWnd, $tLITEM) Then
		Return DllStructGetData($tLITEM, "Url")
	EndIf
	Return SetError(1, 0, "")
EndFunc   ;==>_GUICtrlSysLink_GetItemUrl

; #FUNCTION# ====================================================================================================================
; Name...........: _GUICtrlSysLink_GetItemVisited
; Description....: Determines whether the specified link of the SysLink control is visited
; Syntax.........: _GUICtrlSysLink_GetItemVisited ( $hWnd [, $iLink = 0] )
; Parameters.....: $hWnd   - Handle to the SysLink control
;                  $iLink  - The zero based link index
; Return values..: Success - True
;                  Failure - False
; Author.........: Yashied
; Modified.......:
; Remarks........:
; Related........: _GUICtrlSysLink_SetItemVisited
; Link...........:
; Example........: Yes
; ===============================================================================================================================

Func _GUICtrlSysLink_GetItemVisited($hWnd, $iLink = 0)
	Local $iState = _GUICtrlSysLink_GetItemState($hWnd, $iLink)
	If $iState <> -1 Then
		Return BitAND($LIS_VISITED, $iState) = $LIS_VISITED
	EndIf
EndFunc   ;==>_GUICtrlSysLink_GetItemVisited

; #FUNCTION# ====================================================================================================================
; Name...........: _GUICtrlSysLink_GetText
; Description....: Retrieves the text of the SysLink control
; Syntax.........: _GUICtrlSysLink_GetText ( $hWnd )
; Parameters.....: $hWnd   - Handle to the SysLink control
; Return values..: Success - The current text
;                  Failure - The empty string ("") and sets the @error flag to non-zero
; Author.........: Yashied
; Modified.......:
; Remarks........:
; Related........: _GUICtrlSysLink_SetText
; Link...........:
; Example........: Yes
; ===============================================================================================================================

Func _GUICtrlSysLink_GetText($hWnd)
	If $Debug_SL Then
		__UDF_ValidateClassName($hWnd, $__SYSLINKCONSTANT_ClassName)
	EndIf
	If _WinAPI_IsClassName($hWnd, $__SYSLINKCONSTANT_ClassName) Then
		Return _WinAPI_GetWindowText($hWnd)
	EndIf
	Return SetError(2, 2, "")
EndFunc   ;==>_GUICtrlSysLink_GetText

; #FUNCTION# ====================================================================================================================
; Name...........: _GUICtrlSysLink_HitTest
; Description....: Retrieves the index of the link that contains the specified point relative to the SysLink control
; Syntax.........: _GUICtrlSysLink_HitTest ( $hWnd, $iX, $iY )
; Parameters.....: $hWnd   - Handle to the SysLink control
;                  $iX     - X position to test. (-1) - use the current x-coordinate of the mouse cursor position.
;                  $iY     - Y position to test. (-1) - use the current y-coordinate of the mouse cursor position.
; Return values..: Success - The zero based link index
;                  Failure - -1
; Author.........: Yashied
; Modified.......:
; Remarks........:
; Related........: _GUICtrlSysLink_HitTestItem, _GUICtrlSysLink_HitTestEx
; Link...........:
; Example........: Yes
; ===============================================================================================================================

Func _GUICtrlSysLink_HitTest($hWnd, $iX = -1, $iY = -1)
	Local $tHit = DllStructCreate($tagLHITTESTINFO)
	If _GUICtrlSysLink_HitTestEx($hWnd, $iX, $iY, $tHit) Then
		Return DllStructGetData($tHit, "Link")
	EndIf
	Return -1
EndFunc   ;==>_GUICtrlSysLink_HitTest

; #FUNCTION# ====================================================================================================================
; Name...........: _GUICtrlSysLink_HitTestEx
; Description....: Retrieves the information about the location of a point relative to the SysLink control
; Syntax.........: _GUICtrlSysLink_HitTestEx ( $hWnd, $iX, $iY, ByRef $tHit )
; Parameters.....: $hWnd   - Handle to the SysLink control
;                  $iX     - X position to test. (-1) - use the current x-coordinate of the mouse cursor position.
;                  $iY     - Y position to test. (-1) - use the current y-coordinate of the mouse cursor position.
;                  $tHit   - $tagLHITTESTINFO structure that receive the information
; Return values..: Success - True
;                  Failure - False
; Author.........: Yashied
; Modified.......:
; Remarks........:
; Related........: _GUICtrlSysLink_HitTest, _GUICtrlSysLink_HitTestItem
; Link...........:
; Example........: Yes
; ===============================================================================================================================

Func _GUICtrlSysLink_HitTestEx($hWnd, $iX, $iY, ByRef $tHit)
	If $Debug_SL Then
		__UDF_ValidateClassName($hWnd, $__SYSLINKCONSTANT_ClassName)
	EndIf
	If  ($iX = -1) Or ($iY = -1) Then
		Local $tPoint = _WinAPI_GetMousePos()
		If _WinAPI_ScreenToClient($hWnd, $tPoint) Then
			If $iX = -1 Then
				$iX = DllStructGetData($tPoint, 1)
			EndIf
			If $iY = -1 Then
				$iY = DllStructGetData($tPoint, 2)
			EndIf
		Else
			Return SetError(1, 0, False)
		EndIf
	EndIf
	$tHit = DllStructCreate($tagLHITTESTINFO)
	Local $pHit = DllStructGetPtr($tHit)
	Local $iRet
	DllStructSetData($tHit, "X", $iX)
	DllStructSetData($tHit, "Y", $iY)
	If _WinAPI_InProcess($hWnd, $_ghSLLastWnd) Then
		$iRet = _SendMessage($hWnd, $LM_HITTEST, 0, $pHit, 0, "wparam", "ptr")
	Else
		Local $iSize = DllStructGetSize($tHit)
		Local $tMem
		Local $pMem = _MemInit($hWnd, $iSize, $tMem)
		_MemWrite($tMem, $pHit)
		$iRet = _SendMessage($hWnd, $LM_HITTEST, 0, $pMem, 0, "wparam", "ptr")
		_MemRead($tMem, $pMem, $pHit, $iSize)
		_MemFree($tMem)
	EndIf
	If Not $iRet Then
		$tHit = 0
	EndIf
	Return $iRet <> 0
EndFunc   ;==>_GUICtrlSysLink_HitTestEx

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __GUICtrlSysLink_SetItem
; Description....: Sets some or all of a item's attributes
; Syntax.........: __GUICtrlSysLink_SetItem ( $hWnd, ByRef $tItem )
; Parameters.....: $hWnd   - Handle to the SysLink control
;                  $tItem  - $tagLITEM structure that contains the new item attributes
; Return values..: Success - True
;                  Failure - False
; Author.........: Paul Campbell (PaulIA)
; Modified.......: Yashied
; Remarks........: This function is used internally and should not normally be called by the end user
; Related........: __GUICtrlSysLink_GetItem
; Link...........:
; Example........:
; ===============================================================================================================================

Func __GUICtrlSysLink_SetItem($hWnd, ByRef $tItem)
	Local $pItem = DllStructGetPtr($tItem)
	Local $iRet
	If _WinAPI_InProcess($hWnd, $_ghSLLastWnd) Then
		$iRet = _SendMessage($hWnd, $LM_SETITEM, 0, $pItem, 0, "wparam", "ptr")
	Else
		Local $iSize = DllStructGetSize($tItem)
		Local $tMem
		Local $pMem = _MemInit($hWnd, $iSize, $tMem)
		_MemWrite($tMem, $pItem)
		$iRet = _SendMessage($hWnd, $LM_SETITEM, 0, $pMem, 0, "wparam", "ptr")
		_MemFree($tMem)
	EndIf
	Return $iRet <> 0
EndFunc   ;==>__GUICtrlSysLink_SetItem

; #FUNCTION# ====================================================================================================================
; Name...........: _GUICtrlSysLink_SetItemEnabled
; Description....: Sets whether the specified link of the SysLink control is enabled
; Syntax.........: _GUICtrlSysLink_SetItemEnabled ( $hWnd [, $iLink = 0 [, $fSet = True]] )
; Parameters.....: $hWnd   - Handle to the SysLink control
;                  $iLink  - The zero based link index
;                  $fSet   - Specifies whether the link is enabled or not, valid values:
;                  |TRUE   - The link is enabled (Default)
;                  |FALSE  - The link does not
; Return values..: Success - True
;                  Failure - False
; Author.........: Yashied
; Modified.......:
; Remarks........:
; Related........: _GUICtrlSysLink_GetItemEnabled
; Link...........:
; Example........: Yes
; ===============================================================================================================================

Func _GUICtrlSysLink_SetItemEnabled($hWnd, $iLink = 0, $fSet = True)
	Return _GUICtrlSysLink_SetItemState($hWnd, $iLink, $LIS_ENABLED, $fSet)
EndFunc   ;==>_GUICtrlSysLink_SetItemEnabled

; #FUNCTION# ====================================================================================================================
; Name...........: _GUICtrlSysLink_SetItemFocused
; Description....: Sets whether the specified link of the SysLink control is focused
; Syntax.........: _GUICtrlSysLink_SetItemFocused ( $hWnd [, $iLink = 0 [, $fSet = True]] )
; Parameters.....: $hWnd   - Handle to the SysLink control
;                  $iLink  - The zero based link index
;                  $fSet   - Specifies whether the link is focused or not, valid values:
;                  |TRUE   - The link is focused (Default)
;                  |FALSE  - The link does not
; Return values..: Success - True
;                  Failure - False
; Author.........: Yashied
; Modified.......:
; Remarks........:
; Related........: _GUICtrlSysLink_GetItemFocused
; Link...........:
; Example........: Yes
; ===============================================================================================================================

Func _GUICtrlSysLink_SetItemFocused($hWnd, $iLink = 0, $fSet = True)
	Return _GUICtrlSysLink_SetItemState($hWnd, $iLink, $LIS_FOCUSED, $fSet)
EndFunc   ;==>_GUICtrlSysLink_SetItemFocused

; #FUNCTION# ====================================================================================================================
; Name...........: _GUICtrlSysLink_SetItemHighlighted
; Description....: Sets whether the specified link of the SysLink control is highlighted
; Syntax.........: _GUICtrlSysLink_SetItemHighlighted ( $hWnd [, $iLink = 0 [, $fSet = True]] )
; Parameters.....: $hWnd   - Handle to the SysLink control
;                  $iLink  - The zero based link index
;                  $fSet   - Specifies whether the link is highlighted or not, valid values:
;                  |TRUE   - The link is highlighted (Default)
;                  |FALSE  - The link does not
; Return values..: Success - True
;                  Failure - False
; Author.........: Yashied
; Modified.......:
; Remarks........:
; Related........: _GUICtrlSysLink_GetItemHighlighted
; Link...........:
; Example........: Yes
; ===============================================================================================================================

Func _GUICtrlSysLink_SetItemHighlighted($hWnd, $iLink = 0, $fSet = True)
	Return _GUICtrlSysLink_SetItemState($hWnd, $iLink, $LIS_HOTTRACK, $fSet)
EndFunc   ;==>_GUICtrlSysLink_SetItemHighlighted

; #FUNCTION# ====================================================================================================================
; Name...........: _GUICtrlSysLink_SetItemID
; Description....: Sets the ID of the specified link of the SysLink control
; Syntax.........: _GUICtrlSysLink_SetItemID ( $hWnd, $iLink, $sID )
; Parameters.....: $hWnd   - Handle to the SysLink control
;                  $iLink  - The zero based link index
;                  $sID    - The new ID string (maximum number of characters is 47)
; Return values..: Success - True
;                  Failure - False
; Author.........: Yashied
; Modified.......:
; Remarks........:
; Related........: _GUICtrlSysLink_GetItemID
; Link...........:
; Example........: Yes
; ===============================================================================================================================

Func _GUICtrlSysLink_SetItemID($hWnd, $iLink, $sID)
	If $Debug_SL Then
		__UDF_ValidateClassName($hWnd, $__SYSLINKCONSTANT_ClassName)
	EndIf
	Local $tLITEM = DllStructCreate($tagLITEM)
	DllStructSetData($tLITEM, "Mask", BitOR($LIF_ITEMINDEX, $LIF_ITEMID))
	DllStructSetData($tLITEM, "Link", $iLink)
	DllStructSetData($tLITEM, "ID", $sID)
	Return __GUICtrlSysLink_SetItem($hWnd, $tLITEM)
EndFunc   ;==>_GUICtrlSysLink_SetItemID

; #FUNCTION# ====================================================================================================================
; Name...........: _GUICtrlSysLink_SetItemState
; Description....: Sets the state of the specified link of the SysLink control
; Syntax.........: _GUICtrlSysLink_SetItemState ( $hWnd, $iLink, $iState [, $fSet = True] )
; Parameters.....: $hWnd   - Handle to the SysLink control
;                  $iLink  - The zero based link index
;                  $iState - The new link state, can be one or more of the following values:
;                  |$LIS_ENABLED       - The link can respond to user input
;                  |$LIS_FOCUSED       - The link has the keyboard focus
;                  |$LIS_VISITED       - The link has been visited by the user
;                  |$LIS_HOTTRACK      - Indicates that the syslink control will highlight in a different color (COLOR_HIGHLIGHT) when the mouse hovers over the control
;                  |$LIS_DEFAULTCOLORS - Enable custom text colors to be used
;                  $fSet   - Specifies whether the link state is to be set or remove, valid values:
;                  |TRUE   - Set link state (Default)
;                  |FALSE  - Remove link state
; Return values..: Success - True
;                  Failure - False
; Author.........: Yashied
; Modified.......:
; Remarks........: State values can BitOR'ed together as for example BitOR($LIS_ENABLED, $LIS_FOCUSED)
; Related........: _GUICtrlSysLink_GetItemState
; Link...........:
; Example........: Yes
; ===============================================================================================================================

Func _GUICtrlSysLink_SetItemState($hWnd, $iLink, $iState, $fSet = True)
	If $Debug_SL Then
		__UDF_ValidateClassName($hWnd, $__SYSLINKCONSTANT_ClassName)
	EndIf
	Local $tLITEM = DllStructCreate($tagLITEM)
	DllStructSetData($tLITEM, "Mask", BitOR($LIF_ITEMINDEX, $LIF_STATE))
	DllStructSetData($tLITEM, "Link", $iLink)
	If $fSet Then
		DllStructSetData($tLITEM, "State", $iState)
	Else
		DllStructSetData($tLITEM, "State", 0)
	EndIf
	DllStructSetData($tLITEM, "StateMask", $iState)
	Return __GUICtrlSysLink_SetItem($hWnd, $tLITEM)
EndFunc   ;==>_GUICtrlSysLink_SetItemState

; #FUNCTION# ====================================================================================================================
; Name...........: _GUICtrlSysLink_SetItemUrl
; Description....: Sets the URL of the specified link of the SysLink control
; Syntax.........: _GUICtrlSysLink_SetItemUrl ( $hWnd, $iLink, $sUrl )
; Parameters.....: $hWnd   - Handle to the SysLink control
;                  $iLink  - The zero based link index
;                  $sUrl   - The new URL string (maximum number of characters is 2072)
; Return values..: Success - True
;                  Failure - False
; Author.........: Yashied
; Modified.......:
; Remarks........:
; Related........: _GUICtrlSysLink_GetItemUrl
; Link...........:
; Example........: Yes
; ===============================================================================================================================

Func _GUICtrlSysLink_SetItemUrl($hWnd, $iLink, $sUrl)
	If $Debug_SL Then
		__UDF_ValidateClassName($hWnd, $__SYSLINKCONSTANT_ClassName)
	EndIf
	Local $tLITEM = DllStructCreate($tagLITEM)
	DllStructSetData($tLITEM, "Mask", BitOR($LIF_ITEMINDEX, $LIF_URL))
	DllStructSetData($tLITEM, "Link", $iLink)
	DllStructSetData($tLITEM, "Url", $sUrl)
	Return __GUICtrlSysLink_SetItem($hWnd, $tLITEM)
EndFunc   ;==>_GUICtrlSysLink_SetItemUrl

; #FUNCTION# ====================================================================================================================
; Name...........: _GUICtrlSysLink_SetItemVisited
; Description....: Sets whether the specified link of the SysLink control is visited
; Syntax.........: _GUICtrlSysLink_SetItemVisited ( $hWnd [, $iLink = 0 [, $fSet = True]] )
; Parameters.....: $hWnd   - Handle to the SysLink control
;                  $iLink  - The zero based link index
;                  $fSet   - Specifies whether the link is visited or not, valid values:
;                  |TRUE   - The link is visited (Default)
;                  |FALSE  - The link does not
; Return values..: Success - True
;                  Failure - False
; Author.........: Yashied
; Modified.......:
; Remarks........:
; Related........: _GUICtrlSysLink_GetItemVisited
; Link...........:
; Example........: Yes
; ===============================================================================================================================

Func _GUICtrlSysLink_SetItemVisited($hWnd, $iLink = 0, $fSet = True)
	Return _GUICtrlSysLink_SetItemState($hWnd, $iLink, $LIS_HOTTRACK, $fSet)
EndFunc   ;==>_GUICtrlSysLink_SetItemVisited

; #FUNCTION# ====================================================================================================================
; Name...........: _GUICtrlSysLink_SetText
; Description....: Sets the text for a SysLink control
; Syntax.........: _GUICtrlSysLink_SetText ( $hWnd, $sText )
; Parameters.....: $hWnd   - Handle to the SysLink control
;                  $sText  - New text
; Return values..: Success - True
;                  Failure - False
; Author.........: Yashied
; Modified.......:
; Remarks........:
; Related........: _GUICtrlSysLink_GetText
; Link...........:
; Example........: Yes
; ===============================================================================================================================

Func _GUICtrlSysLink_SetText($hWnd, $sText)
	If $Debug_SL Then
		__UDF_ValidateClassName($hWnd, $__SYSLINKCONSTANT_ClassName)
	EndIf
	If _WinAPI_IsClassName($hWnd, $__SYSLINKCONSTANT_ClassName) Then
		Return _WinAPI_SetWindowText($hWnd, $sText)
	EndIf
EndFunc   ;==>_GUICtrlSysLink_SetText
