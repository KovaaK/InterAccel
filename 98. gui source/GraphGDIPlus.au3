;#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6

; #INDEX# ===============================================================================
; Title .........: GraphGDIPlus
; AutoIt Version: 3.3.0.0+
; Language:       English
; Description ...: A Graph control to draw line graphs, using GDI+, also double-buffered.
; Notes .........:
; =======================================================================================



; #VARIABLES/INCLUDES# ==================================================================
#include-once
#include <GDIplus.au3>

Global $aGraphGDIPlusaGraphArrayINTERNAL[1]
; =======================================================================================



; #FUNCTION# ============================================================================
; Name...........: _GraphGDIPlus_Create
; Description ...: Creates graph area, and prepares array of specified data
; Syntax.........: _GraphGDIPlus_Create($hWnd,$iLeft,$iTop,$iWidth,$iHeight,$hColorBorder = 0xFF000000,$hColorFill = 0xFFFFFFFF)
; Parameters ....:  $hWnd - Handle to GUI
;                   $iLeft - left most position in GUI
;                   $iTop - top most position in GUI
;                   $iWidth - width of graph in pixels
;                   $iHeight - height of graph in pixels
;                   $hColorBorder - Color of graph border (ARGB)
;                   $hColorFill - Color of background (ARGB)
; Return values .: Returns array containing variables for subsequent functions...
;                    Returned Graph array is:
;                    [1] graphic control handle
;                    [2] left
;                    [3] top
;                    [4] width
;                    [5] height
;                    [6] x low
;                    [7] x high
;                    [8] y low
;                    [9] y high
;                    [10] x ticks handles
;                    [11] x labels handles
;                    [12] y ticks handles
;                    [13] y labels handles
;                    [14] Border Color
;                    [15] Fill Color
;                    [16] Bitmap Handle
;                    [17] Backbuffer Handle
;                    [18] Last used x pos
;                    [19] Last used y pos
;                    [20] Pen (main) Handle
;                    [21] Brush (fill) Handle
;                    [22] Pen (border) Handle
;                    [23] Pen (grid) Handle
; =======================================================================================
Func _GraphGDIPlus_Create($hWnd, $iLeft, $iTop, $iWidth, $iHeight, $hColorBorder = 0xFF000000, $hColorFill = 0xFFFFFFFF, $iSmooth = 2)
    Local $graphics, $bitmap, $backbuffer, $brush, $bpen, $gpen, $pen
    Local $ahTicksLabelsX[1]
    Local $ahTicksLabelsY[1]
    Local $ahTicksX[1]
    Local $ahTicksY[1]
    Local $aGraphArray[1]

    ;----- Set GUI transparency to SOLID (prevents GDI+ glitches) -----
    ;WinSetTrans($hWnd, "", 255) - causes problems when more than 2 graphs used
    ;----- GDI+ Initiate -----
    _GDIPlus_Startup()
    $graphics = _GDIPlus_GraphicsCreateFromHWND($hWnd) ;graphics area
    $bitmap = _GDIPlus_BitmapCreateFromGraphics($iWidth + 1, $iHeight + 1, $graphics);buffer bitmap
    $backbuffer = _GDIPlus_ImageGetGraphicsContext($bitmap) ;buffer area
    _GDIPlus_GraphicsSetSmoothingMode($backbuffer, $iSmooth)

    ;----- Set background Color -----
    $brush = _GDIPlus_BrushCreateSolid($hColorFill)
    _GDIPlus_GraphicsFillRect($backbuffer, 0, 0, $iWidth, $iHeight, $brush)
    ;----- Set border Pen + color -----
    $bpen = _GDIPlus_PenCreate($hColorBorder)
    _GDIPlus_PenSetEndCap($bpen, $GDIP_LINECAPROUND)
    ;----- Set Grid Pen + color -----
    $gpen = _GDIPlus_PenCreate(0xFFf0f0f0)
    _GDIPlus_PenSetEndCap($gpen, $GDIP_LINECAPROUND)
    ;----- set Drawing Pen + Color -----
    $pen = _GDIPlus_PenCreate() ;drawing pen initially black, user to set
    _GDIPlus_PenSetEndCap($pen, $GDIP_LINECAPROUND)
    _GDIPlus_GraphicsDrawRect($backbuffer, 0, 0, $iWidth, $iHeight, $pen)
    ;----- draw -----
    _GDIPlus_GraphicsDrawImageRect($graphics, $bitmap, $iLeft, $iTop, $iWidth + 1, $iHeight + 1)
    ;----- register redraw -----
    GUIRegisterMsg(0x0006, "_GraphGDIPlus_ReDraw") ;0x0006 = win activate
    GUIRegisterMsg(0x0003, "_GraphGDIPlus_ReDraw") ;0x0003 = win move
    ;----- prep + load array -----
    Dim $aGraphArray[24] = ["", $graphics, $iLeft, $iTop, $iWidth, $iHeight, 0, 1, 0, 1, _
            $ahTicksX, $ahTicksLabelsX, $ahTicksY, $ahTicksLabelsY, $hColorBorder, $hColorFill, _
            $bitmap, $backbuffer, 0, 0, $pen, $brush, $bpen, $gpen]
    ;----- prep re-draw array for all graphs created -----
    ReDim $aGraphGDIPlusaGraphArrayINTERNAL[UBound($aGraphGDIPlusaGraphArrayINTERNAL) + 1]
    $aGraphGDIPlusaGraphArrayINTERNAL[UBound($aGraphGDIPlusaGraphArrayINTERNAL) - 1] = $aGraphArray

    Return $aGraphArray
EndFunc   ;==>_GraphGDIPlus_Create
Func _GraphGDIPlus_ReDraw($hWnd)
    ;----- Allows redraw of the GDI+ Image upon window min/maximize -----
    Local $i
    _WinAPI_RedrawWindow($hWnd, 0, 0, 0x0100)
    For $i = 1 To UBound($aGraphGDIPlusaGraphArrayINTERNAL) - 1
        If $aGraphGDIPlusaGraphArrayINTERNAL[$i] = 0 Then ContinueLoop
        _GraphGDIPlus_Refresh($aGraphGDIPlusaGraphArrayINTERNAL[$i])
    Next
EndFunc   ;==>_GraphGDIPlus_ReDraw



; #FUNCTION# ============================================================================
; Name...........: _GraphGDIPlus_Delete
; Description ...: Deletes previously created graph and related ticks/labels
; Syntax.........: _GraphGDIPlus_Delete($hWnd,ByRef $aGraphArray)
; Parameters ....:  $hWnd - GUI handle
;                   $aGraphArray - the array returned from _GraphGDIPlus_Create
;                   $iKeepGDIPlus - if not zero, function will not _GDIPlus_Shutdown()
; =======================================================================================
Func _GraphGDIPlus_Delete($hWnd, ByRef $aGraphArray, $iKeepGDIPlus = 0)
    If IsArray($aGraphArray) = 0 Then Return
    Local $ahTicksX, $ahTicksLabelsX, $ahTicksY, $ahTicksLabelsY, $i, $aTemp
    ;----- delete x ticks/labels -----
    $ahTicksX = $aGraphArray[10]
    $ahTicksLabelsX = $aGraphArray[11]
    For $i = 1 To (UBound($ahTicksX) - 1)
        GUICtrlDelete($ahTicksX[$i])
    Next
    For $i = 1 To (UBound($ahTicksLabelsX) - 1)
        GUICtrlDelete($ahTicksLabelsX[$i])
    Next
    ;----- delete y ticks/labels -----
    $ahTicksY = $aGraphArray[12]
    $ahTicksLabelsY = $aGraphArray[13]
    For $i = 1 To (UBound($ahTicksY) - 1)
        GUICtrlDelete($ahTicksY[$i])
    Next
    For $i = 1 To (UBound($ahTicksLabelsY) - 1)
        GUICtrlDelete($ahTicksLabelsY[$i])
    Next
    ;----- delete graphic control -----
    _GDIPlus_GraphicsDispose($aGraphArray[17])
    _GDIPlus_BitmapDispose($aGraphArray[16])
    _GDIPlus_GraphicsDispose($aGraphArray[1])
    _GDIPlus_BrushDispose($aGraphArray[21])
    _GDIPlus_PenDispose($aGraphArray[20])
    _GDIPlus_PenDispose($aGraphArray[22])
    _GDIPlus_PenDispose($aGraphArray[23])
    If $iKeepGDIPlus = 0 Then _GDIPlus_Shutdown()
    _WinAPI_InvalidateRect($hWnd)
    ;----- remove form global redraw array -----
    For $i = 1 To UBound($aGraphGDIPlusaGraphArrayINTERNAL) - 1
        $aTemp = $aGraphGDIPlusaGraphArrayINTERNAL[$i]
        If IsArray($aTemp) = 0 Then ContinueLoop
        If $aTemp[1] = $aGraphArray[1] Then $aGraphGDIPlusaGraphArrayINTERNAL[$i] = 0
    Next
    ;----- close array -----
    $aGraphArray = 0
EndFunc   ;==>_GraphGDIPlus_Delete



; #FUNCTION# ============================================================================
; Name...........: _GraphGDIPlus_Clear
; Description ...: Clears graph content
; Syntax.........: _GraphGDIPlus_Clear(ByRef $aGraphArray)
; Parameters ....: $aGraphArray - the array returned from _GraphGDIPlus_Create
; =======================================================================================
Func _GraphGDIPlus_Clear(ByRef $aGraphArray)
    If IsArray($aGraphArray) = 0 Then Return
    ;----- Set background Color -----
    _GDIPlus_GraphicsFillRect($aGraphArray[17], 0, 0, $aGraphArray[4], $aGraphArray[5], $aGraphArray[21])
    ;----- set border + Color -----
    _GraphGDIPlus_RedrawRect($aGraphArray)
EndFunc   ;==>_GraphGDIPlus_Clear



; #FUNCTION# =============================================================================
; Name...........: _GraphGDIPlus_Refresh
; Description ...: refreshes the graphic
; Syntax.........: _GraphGDIPlus_Refresh(ByRef $aGraphArray)
; Parameters ....:   $aGraphArray - the array returned from _GraphGDIPlus_Create
; ========================================================================================
Func _GraphGDIPlus_Refresh(ByRef $aGraphArray)
    If IsArray($aGraphArray) = 0 Then Return
    ;----- draw -----
    _GDIPlus_GraphicsDrawImageRect($aGraphArray[1], $aGraphArray[16], $aGraphArray[2], _
            $aGraphArray[3], $aGraphArray[4] + 1, $aGraphArray[5] + 1)
EndFunc   ;==>_GraphGDIPlus_Refresh



; #FUNCTION# ============================================================================
; Name...........: _GraphGDIPlus_Set_RangeX
; Description ...: Allows user to set the range of the X axis and set ticks and rounding levels
; Syntax.........: _GraphGDIPlus_Set_RangeX(ByRef $aGraphArray,$iLow,$iHigh,$iXTicks = 1,$bLabels = 1,$iRound = 0)
; Parameters ....:   $aGraphArray - the array returned from _GraphGDIPlus_Create
;                    $iLow - the lowest value for the X axis (can be negative)
;                    $iHigh - the highest value for the X axis
;                    $iXTicks - [optional] number of ticks to show below axis, if = 0 then no ticks created
;                    $bLabels - [optional] 1=show labels, any other number=do not show labels
;                    $iRound - [optional] rounding level of label values
; =======================================================================================
Func _GraphGDIPlus_Set_RangeX(ByRef $aGraphArray, $iLow, $iHigh, $iXTicks = 1, $bLabels = 1, $iRound = 0)
    If IsArray($aGraphArray) = 0 Then Return
    Local $ahTicksX, $ahTicksLabelsX, $i
    ;----- load user vars to array -----
    $aGraphArray[6] = $iLow
    $aGraphArray[7] = $iHigh
    ;----- prepare nested array -----
    $ahTicksX = $aGraphArray[10]
    $ahTicksLabelsX = $aGraphArray[11]
    ;----- delete any existing ticks -----
    For $i = 1 To (UBound($ahTicksX) - 1)
        GUICtrlDelete($ahTicksX[$i])
    Next
    Dim $ahTicksX[1]
    ;----- create new ticks -----
    For $i = 1 To $iXTicks + 1
        ReDim $ahTicksX[$i + 1]
        $ahTicksX[$i] = GUICtrlCreateLabel("", (($i - 1) * ($aGraphArray[4] / $iXTicks)) + $aGraphArray[2], _
                $aGraphArray[3] + $aGraphArray[5], 1, 5)
        GUICtrlSetBkColor(-1, 0x000000)
        GUICtrlSetState(-1, 128)
    Next
    ;----- delete any existing labels -----
    For $i = 1 To (UBound($ahTicksLabelsX) - 1)
        GUICtrlDelete($ahTicksLabelsX[$i])
    Next
    Dim $ahTicksLabelsX[1]
    ;----- create new labels -----
    For $i = 1 To $iXTicks + 1
        ReDim $ahTicksLabelsX[$i + 1]
        $ahTicksLabelsX[$i] = GUICtrlCreateLabel("", _
                ($aGraphArray[2] + (($aGraphArray[4] / $iXTicks) * ($i - 1))) - (($aGraphArray[4] / $iXTicks) / 2), _
                $aGraphArray[3] + $aGraphArray[5] + 10, $aGraphArray[4] / $iXTicks, 13, 1)
        GUICtrlSetBkColor(-1, -2)
    Next
    ;----- if labels are required, then fill -----
    If $bLabels = 1 Then
        For $i = 1 To (UBound($ahTicksLabelsX) - 1)
            GUICtrlSetData($ahTicksLabelsX[$i], _
                    StringFormat("%." & $iRound & "f", _GraphGDIPlus_Reference_Pixel("p", (($i - 1) * ($aGraphArray[4] / $iXTicks)), _
                    $aGraphArray[6], $aGraphArray[7], $aGraphArray[4])))
        Next
    EndIf
    ;----- load created arrays back into array -----
    $aGraphArray[10] = $ahTicksX
    $aGraphArray[11] = $ahTicksLabelsX
EndFunc   ;==>_GraphGDIPlus_Set_RangeX



; #FUNCTION# ============================================================================
; Name...........: _GraphGDIPlus_Set_RangeY
; Description ...: Allows user to set the range of the Y axis and set ticks and rounding levels
; Syntax.........: _GraphGDIPlus_SetRange_Y(ByRef $aGraphArray,$iLow,$iHigh,$iYTicks = 1,$bLabels = 1,$iRound = 0)
; Parameters ....:    $aGraphArray - the array returned from _GraphGDIPlus_Create
;                    $iLow - the lowest value for the Y axis (can be negative)
;                    $iHigh - the highest value for the Y axis
;                    $iYTicks - [optional] number of ticks to show next to axis, if = 0 then no ticks created
;                    $bLabels - [optional] 1=show labels, any other number=do not show labels
;                    $iRound - [optional] rounding level of label values
; =======================================================================================
Func _GraphGDIPlus_Set_RangeY(ByRef $aGraphArray, $iLow, $iHigh, $iYTicks = 1, $bLabels = 1, $iRound = 0)
    If IsArray($aGraphArray) = 0 Then Return
    Local $ahTicksY, $ahTicksLabelsY, $i
    ;----- load user vars to array -----
    $aGraphArray[8] = $iLow
    $aGraphArray[9] = $iHigh
    ;----- prepare nested array -----
    $ahTicksY = $aGraphArray[12]
    $ahTicksLabelsY = $aGraphArray[13]
    ;----- delete any existing ticks -----
    For $i = 1 To (UBound($ahTicksY) - 1)
        GUICtrlDelete($ahTicksY[$i])
    Next
    Dim $ahTicksY[1]
    ;----- create new ticks -----
    For $i = 1 To $iYTicks + 1
        ReDim $ahTicksY[$i + 1]
        $ahTicksY[$i] = GUICtrlCreateLabel("", $aGraphArray[2] - 5, _
                ($aGraphArray[3] + $aGraphArray[5]) - (($aGraphArray[5] / $iYTicks) * ($i - 1)), 5, 1)
        GUICtrlSetBkColor(-1, 0x000000)
        GUICtrlSetState(-1, 128)
    Next
    ;----- delete any existing labels -----
    For $i = 1 To (UBound($ahTicksLabelsY) - 1)
        GUICtrlDelete($ahTicksLabelsY[$i])
    Next
    Dim $ahTicksLabelsY[1]
    ;----- create new labels -----
    For $i = 1 To $iYTicks + 1
        ReDim $ahTicksLabelsY[$i + 1]
        $ahTicksLabelsY[$i] = GUICtrlCreateLabel("", $aGraphArray[2] - 40, _
                ($aGraphArray[3] + $aGraphArray[5]) - (($aGraphArray[5] / $iYTicks) * ($i - 1)) - 6, 30, 13, 2)
        GUICtrlSetBkColor(-1, -2)
    Next
    ;----- if labels are required, then fill -----
    If $bLabels = 1 Then
        For $i = 1 To (UBound($ahTicksLabelsY) - 1)
            GUICtrlSetData($ahTicksLabelsY[$i], StringFormat("%." & $iRound & "f", _GraphGDIPlus_Reference_Pixel("p", _
                    (($i - 1) * ($aGraphArray[5] / $iYTicks)), $aGraphArray[8], $aGraphArray[9], $aGraphArray[5])))
        Next
    EndIf
    ;----- load created arrays back into array -----
    $aGraphArray[12] = $ahTicksY
    $aGraphArray[13] = $ahTicksLabelsY
EndFunc   ;==>_GraphGDIPlus_Set_RangeY



; #FUNCTION# =============================================================================
; Name...........: _GraphGDIPlus_Plot_Start
; Description ...: Move starting point of plot
; Syntax.........: _GraphGDIPlus_Plot_Start(ByRef $aGraphArray,$iX,$iY)
; Parameters ....:   $aGraphArray - the array returned from _GraphGDIPlus_Create
;                    $iX - x value to start at
;                    $iY - y value to start at
; ========================================================================================
Func _GraphGDIPlus_Plot_Start(ByRef $aGraphArray, $iX, $iY)
    If IsArray($aGraphArray) = 0 Then Return
    ;----- MOVE pen to start point -----
    $aGraphArray[18] = _GraphGDIPlus_Reference_Pixel("x", $iX, $aGraphArray[6], $aGraphArray[7], $aGraphArray[4])
    $aGraphArray[19] = _GraphGDIPlus_Reference_Pixel("y", $iY, $aGraphArray[8], $aGraphArray[9], $aGraphArray[5])
EndFunc   ;==>_GraphGDIPlus_Plot_Start



; #FUNCTION# =============================================================================
; Name...........: _GraphGDIPlus_Plot_Line
; Description ...: draws straight line to x,y from previous point / starting point
; Syntax.........: _GraphGDIPlus_Plot_Line(ByRef $aGraphArray,$iX,$iY)
; Parameters ....:   $aGraphArray - the array returned from _GraphGDIPlus_Create
;                    $iX - x value to draw to
;                    $iY - y value to draw to
; ========================================================================================
Func _GraphGDIPlus_Plot_Line(ByRef $aGraphArray, $iX, $iY)
    If IsArray($aGraphArray) = 0 Then Return
    ;----- Draw line from previous point to new point -----
    $iX = _GraphGDIPlus_Reference_Pixel("x", $iX, $aGraphArray[6], $aGraphArray[7], $aGraphArray[4])
    $iY = _GraphGDIPlus_Reference_Pixel("y", $iY, $aGraphArray[8], $aGraphArray[9], $aGraphArray[5])
    _GDIPlus_GraphicsDrawLine($aGraphArray[17], $aGraphArray[18], $aGraphArray[19], $iX, $iY, $aGraphArray[20])
    _GraphGDIPlus_RedrawRect($aGraphArray)
    ;----- save current as last coords -----
    $aGraphArray[18] = $iX
    $aGraphArray[19] = $iY
EndFunc   ;==>_GraphGDIPlus_Plot_Line



; #FUNCTION# =============================================================================
; Name...........: _GraphGDIPlus_Plot_Point
; Description ...: draws point at coords
; Syntax.........: _GraphGDIPlus_Plot_Point(ByRef $aGraphArray,$iX,$iY)
; Parameters ....:   $aGraphArray - the array returned from _GraphGDIPlus_Create
;                    $iX - x value to draw at
;                    $iY - y value to draw at
; ========================================================================================
Func _GraphGDIPlus_Plot_Point(ByRef $aGraphArray, $iX, $iY)
    If IsArray($aGraphArray) = 0 Then Return
    ;----- Draw point from previous point to new point -----
    $iX = _GraphGDIPlus_Reference_Pixel("x", $iX, $aGraphArray[6], $aGraphArray[7], $aGraphArray[4])
    $iY = _GraphGDIPlus_Reference_Pixel("y", $iY, $aGraphArray[8], $aGraphArray[9], $aGraphArray[5])
    _GDIPlus_GraphicsDrawRect($aGraphArray[17], $iX-1, $iY-1, 2, 2, $aGraphArray[20])
    _GraphGDIPlus_RedrawRect($aGraphArray)
    ;----- save current as last coords -----
    $aGraphArray[18] = $iX
    $aGraphArray[19] = $iY
EndFunc   ;==>_GraphGDIPlus_Plot_Point



; #FUNCTION# =============================================================================
; Name...........: _GraphGDIPlus_Plot_Dot
; Description ...: draws single pixel dot at coords
; Syntax.........: _GraphGDIPlus_Plot_Dot(ByRef $aGraphArray,$iX,$iY)
; Parameters ....:   $aGraphArray - the array returned from _GraphGDIPlus_Create
;                    $iX - x value to draw at
;                    $iY - y value to draw at
; ========================================================================================
Func _GraphGDIPlus_Plot_Dot(ByRef $aGraphArray, $iX, $iY)
    If IsArray($aGraphArray) = 0 Then Return
    ;----- Draw point from previous point to new point -----
    $iX = _GraphGDIPlus_Reference_Pixel("x", $iX, $aGraphArray[6], $aGraphArray[7], $aGraphArray[4])
    $iY = _GraphGDIPlus_Reference_Pixel("y", $iY, $aGraphArray[8], $aGraphArray[9], $aGraphArray[5])
    _GDIPlus_GraphicsDrawRect($aGraphArray[17], $iX, $iY, 1, 1, $aGraphArray[20]) ;draws 2x2 dot ?HOW to get 1x1 pixel?????
    _GraphGDIPlus_RedrawRect($aGraphArray)
    ;----- save current as last coords -----
    $aGraphArray[18] = $iX
    $aGraphArray[19] = $iY
EndFunc   ;==>_GraphGDIPlus_Plot_Dot



; #FUNCTION# =============================================================================
; Name...........: _GraphGDIPlus_Set_PenColor
; Description ...: sets the Color for the next drawing
; Syntax.........: _GraphGDIPlus_Set_PenColor(ByRef $aGraphArray,$hColor,$hBkGrdColor = $GUI_GR_NOBKColor)
; Parameters ....:   $aGraphArray - the array returned from _GraphGDIPlus_Create
;                    $hColor - the Color of the next item (ARGB)
; ========================================================================================
Func _GraphGDIPlus_Set_PenColor(ByRef $aGraphArray, $hColor)
    If IsArray($aGraphArray) = 0 Then Return
    ;----- apply pen Color -----
    _GDIPlus_PenSetColor($aGraphArray[20], $hColor)
EndFunc   ;==>_GraphGDIPlus_Set_PenColor



; #FUNCTION# =============================================================================
; Name...........: _GraphGDIPlus_Set_PenSize
; Description ...: sets the pen for the next drawing
; Syntax.........: _GraphGDIPlus_Set_PenSize(ByRef $aGraphArray,$iSize = 1)
; Parameters ....:   $aGraphArray - the array returned from _GraphGDIPlus_Create
;                    $iSize - size of pen line
; ========================================================================================
Func _GraphGDIPlus_Set_PenSize(ByRef $aGraphArray, $iSize = 1)
    If IsArray($aGraphArray) = 0 Then Return
    ;----- apply pen size -----
    _GDIPlus_PenSetWidth($aGraphArray[20], $iSize)
EndFunc   ;==>_GraphGDIPlus_Set_PenSize



; #FUNCTION# =============================================================================
; Name...........: _GraphGDIPlus_Set_PenDash
; Description ...: sets the pen dash style for the next drawing
; Syntax.........: GraphGDIPlus_Set_PenDash(ByRef $aGraphArray,$iDash = 0)
; Parameters ....:   $aGraphArray - the array returned from _GraphGDIPlus_Create
;                    $iDash - style of dash, where:
;                                       0 = solid line
;                                       1 = simple dashed line
;                                       2 = simple dotted line
;                                       3 = dash dot line
;                                       4 = dash dot dot line
; ========================================================================================
Func _GraphGDIPlus_Set_PenDash(ByRef $aGraphArray, $iDash = 0)
    If IsArray($aGraphArray) = 0 Then Return
    Local $Style
    Switch $iDash
        Case 0 ;solid line _____
            $Style = $GDIP_DASHSTYLESOLID
        Case 1 ;simple dash -----
            $Style = $GDIP_DASHSTYLEDASH
        Case 2 ;simple dotted .....
            $Style = $GDIP_DASHSTYLEDOT
        Case 3 ;dash dot -.-.-
            $Style = $GDIP_DASHSTYLEDASHDOT
        Case 4 ;dash dot dot -..-..-..
            $Style = $GDIP_DASHSTYLEDASHDOTDOT
    EndSwitch
    ;----- apply pen dash -----
    _GDIPlus_PenSetDashStyle($aGraphArray[20], $Style)
EndFunc   ;==>_GraphGDIPlus_Set_PenDash



; #FUNCTION# =============================================================================
; Name...........: _GraphGDIPlus_Set_GridX
; Description ...: Adds X gridlines.
; Syntax.........: _GraphGDIPlus_Set_GridX(ByRef $aGraphArray, $Ticks=1, $hColor=0xf0f0f0)
; Parameters ....:  $aGraphArray - the array returned from _GraphGDIPlus_Create
;                   $Ticks - sets line at every nth unit assigned to axis
;                   $hColor - [optional] RGB value, defining Color of grid. Default is a light gray
;                   $hColorY0 - [optional] RGB value, defining Color of Y=0 line, Default black
; =======================================================================================
Func _GraphGDIPlus_Set_GridX(ByRef $aGraphArray, $Ticks = 1, $hColor = 0xFFf0f0f0, $hColorY0 = 0xFF000000)
    If IsArray($aGraphArray) = 0 Then Return
    ;----- Set gpen to user color -----
    _GDIPlus_PenSetColor($aGraphArray[23], $hColor)
    ;----- draw grid lines -----
    Select
        Case $Ticks > 0
            For $i = $aGraphArray[6] To $aGraphArray[7] Step $Ticks
                If $i = Number($aGraphArray[6]) Or $i = Number($aGraphArray[7]) Then ContinueLoop
                _GDIPlus_GraphicsDrawLine($aGraphArray[17], _
                        _GraphGDIPlus_Reference_Pixel("x", $i, $aGraphArray[6], $aGraphArray[7], $aGraphArray[4]), _
                        1, _
                        _GraphGDIPlus_Reference_Pixel("x", $i, $aGraphArray[6], $aGraphArray[7], $aGraphArray[4]), _
                        $aGraphArray[5] - 1, _
                        $aGraphArray[23])
            Next
    EndSelect
    ;----- draw y=0 -----
    _GDIPlus_PenSetColor($aGraphArray[23], $hColorY0)
    _GDIPlus_GraphicsDrawLine($aGraphArray[17], _
            _GraphGDIPlus_Reference_Pixel("x", 0, $aGraphArray[6], $aGraphArray[7], $aGraphArray[4]), _
            1, _
            _GraphGDIPlus_Reference_Pixel("x", 0, $aGraphArray[6], $aGraphArray[7], $aGraphArray[4]), _
            $aGraphArray[5] - 1, _
            $aGraphArray[23])
    _GDIPlus_GraphicsDrawLine($aGraphArray[17], _
            1, _
            _GraphGDIPlus_Reference_Pixel("y", 0, $aGraphArray[8], $aGraphArray[9], $aGraphArray[5]), _
            $aGraphArray[4] - 1, _
            _GraphGDIPlus_Reference_Pixel("y", 0, $aGraphArray[8], $aGraphArray[9], $aGraphArray[5]), _
            $aGraphArray[23])

    _GraphGDIPlus_RedrawRect($aGraphArray)
    ;----- re-set to user specs -----
    _GDIPlus_PenSetColor($aGraphArray[23], $hColor) ;set Color back to user def
EndFunc   ;==>_GraphGDIPlus_Set_GridX



; #FUNCTION# =============================================================================
; Name...........: _GraphGDIPlus_Set_GridY
; Description ...: Adds Y gridlines.
; Syntax.........: _GraphGDIPlus_Set_GridY(ByRef $aGraphArray, $Ticks=1, $hColor=0xf0f0f0)
; Parameters ....:  $aGraphArray - the array returned from _GraphGDIPlus_Create
;                   $Ticks - sets line at every nth unit assigned to axis
;                   $hColor - [optional] RGB value, defining Color of grid. Default is a light gray
;                   $hColorX0 - [optional] RGB value, defining Color of X=0 line, Default black
; =======================================================================================
Func _GraphGDIPlus_Set_GridY(ByRef $aGraphArray, $Ticks = 1, $hColor = 0xFFf0f0f0, $hColorX0 = 0xFF000000)
    If IsArray($aGraphArray) = 0 Then Return
    ;----- Set gpen to user color -----
    _GDIPlus_PenSetColor($aGraphArray[23], $hColor)
    ;----- draw grid lines -----
    Select
        Case $Ticks > 0
            For $i = $aGraphArray[8] To $aGraphArray[9] Step $Ticks
                If $i = Number($aGraphArray[8]) Or $i = Number($aGraphArray[9]) Then ContinueLoop
                _GDIPlus_GraphicsDrawLine($aGraphArray[17], _
                        1, _
                        _GraphGDIPlus_Reference_Pixel("y", $i, $aGraphArray[8], $aGraphArray[9], $aGraphArray[5]), _
                        $aGraphArray[4] - 1, _
                        _GraphGDIPlus_Reference_Pixel("y", $i, $aGraphArray[8], $aGraphArray[9], $aGraphArray[5]), _
                        $aGraphArray[23])
            Next
    EndSelect
    ;----- draw abcissa/ordinate -----
    _GDIPlus_PenSetColor($aGraphArray[23], $hColorX0)
    _GDIPlus_GraphicsDrawLine($aGraphArray[17], _
            _GraphGDIPlus_Reference_Pixel("x", 0, $aGraphArray[6], $aGraphArray[7], $aGraphArray[4]), _
            1, _
            _GraphGDIPlus_Reference_Pixel("x", 0, $aGraphArray[6], $aGraphArray[7], $aGraphArray[4]), _
            $aGraphArray[5] - 1, _
            $aGraphArray[23])
    _GDIPlus_GraphicsDrawLine($aGraphArray[17], _
            1, _
            _GraphGDIPlus_Reference_Pixel("y", 0, $aGraphArray[8], $aGraphArray[9], $aGraphArray[5]), _
            $aGraphArray[4] - 1, _
            _GraphGDIPlus_Reference_Pixel("y", 0, $aGraphArray[8], $aGraphArray[9], $aGraphArray[5]), _
            $aGraphArray[23])

    _GraphGDIPlus_RedrawRect($aGraphArray)
    ;----- re-set to user specs -----
    _GDIPlus_PenSetColor($aGraphArray[23], $hColor) ;set Color back to user def
EndFunc   ;==>_GraphGDIPlus_Set_GridY



; #FUNCTION# =============================================================================
; Name...........: _GraphGDIPlus_RedrawRect
; Description ...: INTERNAL FUNCTION - Re-draws the border
; Syntax.........: _GraphGDIPlus_RedrawRect(ByRef $aGraphArray)
; Parameters ....:     $aGraphArray - the array returned from _GraphGDIPlus_Create
; Notes..........: This prevents drawing over the border of the graph area
; =========================================================================================
Func _GraphGDIPlus_RedrawRect(ByRef $aGraphArray)
    If IsArray($aGraphArray) = 0 Then Return
    ;----- draw border -----
    _GDIPlus_GraphicsDrawRect($aGraphArray[17], 0, 0, $aGraphArray[4], $aGraphArray[5], $aGraphArray[22]) ;draw border
EndFunc   ;==>_GraphGDIPlus_RedrawRect



; #FUNCTION# =============================================================================
; Name...........: _GraphGDIPlus_Reference_Pixel
; Description ...: INTERNAL FUNCTION - performs pixel reference calculations
; Syntax.........: _GraphGDIPlus_Reference_Pixel($iType,$iValue,$iLow,$iHigh,$iTotalPixels)
; Parameters ....:     $iType - "x"=x axis pix, "y" = y axis pix, "p"=value from pixels
;                    $iValue - pixels reference or value
;                    $iLow - lower limit of axis
;                    $iHigh - upper limit of axis
;                    $iTotalPixels - total number of pixels in range (either width or height)
; =========================================================================================
Func _GraphGDIPlus_Reference_Pixel($iType, $iValue, $iLow, $iHigh, $iTotalPixels)
    ;----- perform pixel reference calculations -----
    Switch $iType
        Case "x"
            Return (($iTotalPixels / ($iHigh - $iLow)) * (($iHigh - $iLow) * (($iValue - $iLow) / ($iHigh - $iLow))))
        Case "y"
            Return ($iTotalPixels - (($iTotalPixels / ($iHigh - $iLow)) * (($iHigh - $iLow) * (($iValue - $iLow) / ($iHigh - $iLow)))))
        Case "p"
            Return ($iValue / ($iTotalPixels / ($iHigh - $iLow))) + $iLow
    EndSwitch
EndFunc   ;==>_GraphGDIPlus_Reference_Pixel