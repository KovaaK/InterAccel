#include-once

#include <StructureConstants.au3>

; #INDEX# =======================================================================================================================
; Title..........: SysLink_Constants
; AutoIt Version.: 3.2
; Language.......: English
; Description....: GUI control SysLink styles and much more constants.
; Author(s)......: Yashied
; ===============================================================================================================================

; #CONSTANTS# ===================================================================================================================
Global Const $LIF_ITEMINDEX = 0x01
Global Const $LIF_STATE = 0x02
Global Const $LIF_ITEMID = 0x04
Global Const $LIF_URL = 0x08

Global Const $LIS_ENABLED = 0x02
Global Const $LIS_FOCUSED = 0x01
Global Const $LIS_VISITED = 0x04
Global Const $LIS_HOTTRACK = 0x08
Global Const $LIS_DEFAULTCOLORS = 0x10
; ===============================================================================================================================

; #STYLES# ======================================================================================================================
Global Const $LWS_TRANSPARENT = 0x0001 ; The background mix mode is transparent
Global Const $LWS_IGNORERETURN = 0x0002 ; When the link has keyboard focus and the user presses Enter, the keystroke is ignored by the control and passed to the host dialog box
; Vista
Global Const $LWS_NOPREFIX = 0x0004 ; If the text contains an ampersand, it is treated as a literal character rather than the prefix to a shortcut key
Global Const $LWS_USEVISUALSTYLE = 0x0008 ; The link is displayed in the current visual style
Global Const $LWS_USECUSTOMTEXT = 0x0010 ; An NM_CUSTOMTEXT notification is sent when the control is drawn, so that the application can supply text dynamically
Global Const $LWS_RIGHT = 0x0020 ; The text is right-justified
; ===============================================================================================================================

; #MESSAGES# ====================================================================================================================
Global Const $LM_GETIDEALHEIGHT = 0x0701
Global Const $LM_GETITEM = 0x0703
Global Const $LM_HITTEST = 0x0700
Global Const $LM_SETITEM = 0x0702
; Vista
Global Const $LM_GETIDEALSIZE = $LM_GETIDEALHEIGHT
; ===============================================================================================================================

; #NOTIFICATIONS# ===============================================================================================================
;~Global Const $NM_CLICK = -2 ; Notifies a control's parent window that the user has clicked a hyperlink with the left mouse button within the control
; ===============================================================================================================================

; #STRUCTURES# ==================================================================================================================
$tagLITEM = "uint Mask;int Link;uint State;uint StateMask;wchar ID[48];wchar Url[2073]"
$tagLHITTESTINFO = "int X;int Y;" & $tagLITEM
If @AutoItX64 Then
	$tagNMLINK = $tagNMHDR & ";byte Aligment[4];" & $tagLITEM
Else
	$tagNMLINK = $tagNMHDR & ";" & $tagLITEM
EndIf
; ===============================================================================================================================
