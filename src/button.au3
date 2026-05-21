#include <WinAPISysWin.au3>
#include <WinAPICom.au3>
#include <WindowsConstants.au3>
#include <WinAPIMem.au3>
#include <WinAPIHObj.au3>
#include <WinAPIGdi.au3>
#include <WinAPIRes.au3>
#include <GDIPlus.au3>
#include <WinAPISys.au3>
#include <Timers.au3>

If Not IsDeclared("MA_ACTIVATE") Then Global Const $MA_ACTIVATE  = 1
If Not IsDeclared("ETO_OPAQUE") Then Global Const $ETO_OPAQUE = 2
If Not IsDeclared("PRF_CLIENT") Then Global Const $PRF_CLIENT = 0x00000004

Global Enum $__g_GUICtrlButton_Transition_Type_ARGB
Global Enum $__g_GUICtrlButton_Event_Click
Global Const $__g_GUICtrlButton_WM_ = $WM_USER + 1
Global Const $__g_GUICtrlButton_tagCREATESTRUCTW = "PTR lpCreateParams;HANDLE hInstance;HANDLE hMenu;HWND hwndParent;INT cy;INT cx;INT y;INT x;LONG style;PTR lpszName;PTR lpszClass;DWORD dwExStyle;"
Global Const $__g_GUICtrlButton_tagCtrl = "DWORD dwTextColor;DWORD dwBackgroundColor;HANDLE hFont;HWND hwnd;BOOLEAN isHovered;BOOLEAN isDragging;ptr pTransitions;int iTransitionCount;ptr pEvents;int iEventCount;"
Global Const $__g_GUICtrlButton_tagTransition = "int type;dword dwStartValue; dword dwEndValue;uint64 startTime;int duration;int delay;int targetIndex;"
Global Const $__g_GUICtrlButton_tagEvent = "int iEventID;ptr pFunc;"
Global Const $__g_GUICtrlButton_sClass = _WinAPI_CreateGUID()
Global $__g_GUICtrlButton_hInstance = 0
Global $__g_GUICtrlButton_hCursor = 0
Global $__g_GUICtrlButton_hProc = 0

Func __GUICtrlButton_StartUp()
    _GDIPlus_Startup()

    ; Get module handle for the current process
    $__g_GUICtrlButton_hInstance = _WinAPI_GetModuleHandle(0)

    ; Create a class cursor
    $__g_GUICtrlButton_hCursor = _WinAPI_LoadCursor(0, 32512) ; IDC_ARROW

    ; Create a class icons (large and small)
    ;Local $tIcons = DllStructCreate('ptr;ptr')
    ;_WinAPI_ExtractIconEx(@SystemDir & '\shell32.dll', 130, DllStructGetPtr($tIcons, 1), DllStructGetPtr($tIcons, 2), 1)
    ;Local $hIcon = DllStructGetData($tIcons, 1)
    ;Local $hIconSm = DllStructGetData($tIcons, 2)

    ; Create DLL callback function (window procedure)
    $__g_GUICtrlButton_hProc = DllCallbackRegister('__GUICtrlButton_WndProc', 'lresult', 'hwnd;uint;wparam;lparam')

    ; Create and fill $tagWNDCLASSEX structure
    Local $tWNDCLASSEX = DllStructCreate($tagWNDCLASSEX)
    $tWNDCLASSEX.Size = DllStructGetSize($tWNDCLASSEX)
    $tWNDCLASSEX.Style = 0
    $tWNDCLASSEX.hWndProc = DllCallbackGetPtr($__g_GUICtrlButton_hProc)
    $tWNDCLASSEX.ClsExtra = 0
    $tWNDCLASSEX.WndExtra = DllStructGetSize(DllStructCreate("PTR", 1))
    $tWNDCLASSEX.hInstance = $__g_GUICtrlButton_hInstance
    $tWNDCLASSEX.hIcon = 0; $hIcon
    $tWNDCLASSEX.hCursor = $__g_GUICtrlButton_hCursor
    $tWNDCLASSEX.hBackground = _WinAPI_CreateSolidBrush(_WinAPI_GetSysColor($COLOR_BTNFACE))
    $tWNDCLASSEX.MenuName = 0
    $tWNDCLASSEX.ClassName = _WinAPI_CreateString($__g_GUICtrlButton_sClass)
    $tWNDCLASSEX.hIconSm = 0; $hIconSm

    _WinAPI_RegisterClassEx($tWNDCLASSEX)

    OnAutoItExitRegister("__GUICtrlButton_ShutDown")
EndFunc

Func __GUICtrlButton_ShutDown()
    _WinAPI_UnregisterClass($__g_GUICtrlButton_sClass, $__g_GUICtrlButton_hInstance)
    _WinAPI_DestroyCursor($__g_GUICtrlButton_hCursor)
    ; _WinAPI_DestroyIcon($hIcon)
    ; _WinAPI_DestroyIcon($hIconSm)
    ; DllCallbackFree($__g_GUICtrlButton_hProc)

    _GDIPlus_Shutdown()
EndFunc

Func __GUICtrlButton_GetInstance($hWnd)
    Return DllStructCreate($__g_GUICtrlButton_tagCtrl, _WinAPI_GetWindowLong($hWnd, 0))
EndFunc

Func __GUICtrlButton_SetInstance($hWnd, $hInstance)
    If IsDllStruct($hInstance) Then $hInstance = DllStructGetPtr($hInstance)
    _WinAPI_SetWindowLong($hWnd, 0, $hInstance)
EndFunc

Func __GUICtrlButton_WndProc($hWnd, $iMsg, $wParam, $lParam)
    Switch $iMsg
        Case $WM_NCCREATE
            ; Allocate a new Ctrl structure for this window.
            Local $pCtrl = _WinAPI_CreateBuffer(DllStructGetSize(DllStructCreate($__g_GUICtrlButton_tagCtrl, 1)), 0, False)

            ; Failed to allocate, stop window creation.
            If @error <> 0 Then Return False

            Local $tCtrl = DllStructCreate($__g_GUICtrlButton_tagCtrl, $pCtrl)

            ; Initialize the CustCtrl structure.
            $tCtrl.hWnd = $hWnd
            $tCtrl.dwTextColor = _WinAPI_GetSysColor($COLOR_WINDOWTEXT)
            $tCtrl.dwBackgroundColor = _WinAPI_GetSysColor($COLOR_WINDOW)
            $tCtrl.hFont = _WinAPI_GetStockObject($DEFAULT_GUI_FONT)

            ; Assign the window text specified in the call to CreateWindow.
            _WinAPI_SetWindowText($hWnd, _WinAPI_GetString(DllStructGetData(DllStructCreate($__g_GUICtrlButton_tagCREATESTRUCTW, $lParam), "lpszName")))

            ; Attach custom structure to this window.
            __GUICtrlButton_SetInstance($hWnd, $pCtrl)

            ; Continue with window creation.
            Return True

        ; Clean up when the window is destroyed.
        Case $WM_NCDESTROY
            Local $tCtrl = __GUICtrlButton_GetInstance($hWnd)
            If $tCtrl.pTransitions <> 0 Then _WinAPI_FreeMemory($tCtrl.pTransitions)
            If $tCtrl.pEvents <> 0 Then _WinAPI_FreeMemory($tCtrl.pEvents) ; Free event memory
            _WinAPI_FreeMemory(DllStructGetPtr($tCtrl))
        Case $WM_PAINT
            Local $tCtrl = __GUICtrlButton_GetInstance($hWnd)
            Return __GUICtrlButton_OnPaint($tCtrl, $wParam, $lParam)
        Case $WM_ERASEBKGND
            Return 1
        Case $WM_LBUTTONDOWN
            Local $tCtrl = __GUICtrlButton_GetInstance($hWnd)
            Return __GUICtrlButton_OnLButtonDown($tCtrl, $wParam, $lParam)
        Case $WM_LBUTTONUP
            Local $tCtrl = __GUICtrlButton_GetInstance($hWnd)
            Return __GUICtrlButton_OnLButtonUp($tCtrl, $wParam, $lParam)
        Case $WM_MOUSEACTIVATE
            _WinAPI_SetFocus($hWnd)
            Return $MA_ACTIVATE
        Case $WM_SETFONT
            Local $tCtrl = __GUICtrlButton_GetInstance($hWnd)
            Return __GUICtrlButton_OnSetFont($tCtrl, $wParam, $lParam)
        Case $WM_MOUSELEAVE
            Local $tCtrl = __GUICtrlButton_GetInstance($hWnd)
            if $tCtrl.isHovered = 1 Then __GUICtrlButton_AddTransition($tCtrl, $__g_GUICtrlButton_Transition_Type_ARGB, 2, 0x0AFFFFFF, 150)
            $tCtrl.isHovered = 0
            _WinAPI_InvalidateRect($hWnd, 0, True)
            return 0
        Case $WM_MOUSEMOVE
            Local $tCtrl = __GUICtrlButton_GetInstance($hWnd)
            Return __GUICtrlButton_OnMouseMove($tCtrl, $wParam, $lParam)
        Case $WM_CAPTURECHANGED
            Local $tCtrl = __GUICtrlButton_GetInstance($hWnd)
            Return __GUICtrlButton_OnCaptureChanged($tCtrl, $wParam, $lParam)
    EndSwitch

    Return _WinAPI_DefWindowProcW($hWnd, $iMsg, $wParam, $lParam)
EndFunc

Func __GUICtrlButton_OnPaint($tCtrl, $wParam, $lParam)
    Local $hdc
    Local $tPaint
    Local $hOldFont
    Local $szText
    Local $tRect

    Local $hWnd = $tCtrl.hwnd

    ; If $wParam = 0 Then
        ; Get a device context for this window
        $hdc = _WinAPI_BeginPaint($hWnd, $tPaint)
    ; Else
    ;     $hdc = $wParam
    ; EndIf

    ; Set the font we are going to use
    $hOldFont = _WinAPI_SelectObject($hdc, $tCtrl.hFont)

    $tRect = _WinAPI_GetClientRect($hWnd)
    Local $hGraphics = _GDIPlus_GraphicsCreateFromHDC($hdc)
    Local $hBitmap = _GDIPlus_BitmapCreateFromGraphics($tRect.Right - $tRect.Left, $tRect.Bottom - $tRect.Top, $hGraphics)
    Local $hGraphics2 = _GDIPlus_ImageGetGraphicsContext($hBitmap)
    _GDIPlus_GraphicsClear($hGraphics2, 0x00000000)
    _GDIPlus_GraphicsSetSmoothingMode($hGraphics, $GDIP_SMOOTHINGMODE_ANTIALIAS)
    _GDIPlus_GraphicsSetSmoothingMode($hGraphics2, $GDIP_SMOOTHINGMODE_ANTIALIAS)
    ;_GDIPlus_GraphicsSetPixelOffsetMode($hGraphics, $GDIP_PIXELOFFSETMODE_HALF)
    _GDIPlus_GraphicsSetTextRenderingHint($hGraphics, $GDIP_TEXTRENDERINGHINTCLEARTYPEGRIDFIT)
    _GDIPlus_GraphicsSetTextRenderingHint($hGraphics2, $GDIP_TEXTRENDERINGHINTCLEARTYPEGRIDFIT)
    Local $iRadius = 4
    Local $iDiameter = $iRadius * 2
    Local $iWidth = $tRect.Right - 1, $iHeight = $tRect.Bottom - 1
    Local $hPath = _GDIPlus_PathCreate()
    _GDIPlus_PathAddArc($hPath, 0, 0, $iDiameter, $iDiameter, 180, 90)
    _GDIPlus_PathAddArc($hPath, $iWidth - $iDiameter, 0, $iDiameter, $iDiameter, 270, 90)
    _GDIPlus_PathAddArc($hPath, $iWidth - $iDiameter, $iHeight - $iDiameter, $iDiameter, $iDiameter, 0, 90)
    _GDIPlus_PathAddArc($hPath, 0, $iHeight - $iDiameter, $iDiameter, $iDiameter, 90, 90)
    _GDIPlus_PathCloseFigure($hPath)
    Local $hBrush = _GDIPlus_BrushCreateSolid($tCtrl.dwBackgroundColor)
    Local $hPen = _GDIPlus_PenCreate(0x28FFFFFF)
    _GDIPlus_GraphicsFillPath($hGraphics2, $hPath, $hBrush)
    _GDIPlus_GraphicsDrawPath($hGraphics2, $hPath, $hPen)

    ;Local $hFont = _SendMessage($hWnd, $WM_GETFONT, 0, 0)
    ;If $hFont = 0 Then $hFont = _WinAPI_GetStockObject($DEFAULT_GUI_FONT)
    Local $gdiplusFont = DllCall($__g_hGDIPDll, "Int", "GdipCreateFontFromDC", "Handle", $hdc, "Ptr*", 0)[2]
    ;Local $gdiplusFont = DllCall($__g_hGDIPDll, "INT", "GdipCreateFontFromLogfontW", "HANDLE", $hdc, "HANDLE", $tCtrl.hFont, "PTR*", 0)[3]
    Local $hFormat = _GDIPlus_StringFormatCreate()
    _GDIPlus_StringFormatSetAlign($hFormat, 1)
    _GDIPlus_StringFormatSetLineAlign($hFormat, 1)

    _GDIPlus_BrushSetSolidColor($hBrush, $tCtrl.isHovered ? 0xFFFAFAFA : 0xFFE2E2E2)
    Local $tRectF = _GDIPlus_RectFCreate(0, 0, $tRect.right, $tRect.bottom)
    _GDIPlus_GraphicsDrawStringEx($hGraphics2, _WinAPI_GetWindowText($hWnd), $gdiplusFont, $tRectF, $hFormat, $hBrush)

    _GDIPlus_GraphicsDrawImageRect($hGraphics, $hBitmap, 0, 0, $tRect.Right - $tRect.Left, $tRect.Bottom - $tRect.Top)

    _GDIPlus_FontDispose($gdiplusFont)
    _GDIPlus_StringFormatDispose($hFormat)

    _GDIPlus_PenDispose($hPen)
    _GDIPlus_BrushDispose($hBrush)
    _GDIPlus_PathDispose($hPath)
    _GDIPlus_GraphicsDispose($hGraphics2)
    _GDIPlus_ImageDispose($hBitmap)
    _GDIPlus_GraphicsDispose($hGraphics)

    ; Set the text colours
    _WinAPI_SetTextColor($hdc, $tCtrl.dwTextColor)
    _WinAPI_SetBkColor($hdc, -1)

    ; Find the text to draw
    $szText = _WinAPI_GetWindowText($hWnd)

    ; Work out where to draw
    $tRect = _WinAPI_GetClientRect($hWnd)

    ; Find out how big the text will be
    Local $sz = _WinAPI_GetTextExtentPoint32($hdc, $szText)

    ; Center the text
    Local $x = ($tRect.right - $sz.x) / 2
    Local $y = ($tRect.bottom - $sz.y) / 2

    ; Draw the text
    ; __GUICtrlButton_ExtTextOut($hdc, $x, $y, $ETO_OPAQUE, $tRect, $szText, 0)
    ; __GUICtrlButton_ExtTextOut($hdc, $x, $y, 0, $tRect, $szText, 0)

    ; Restore the old font when we have finished
    _WinAPI_SelectObject($hdc, $hOldFont)

    ; Release the device context
    ; If $wParam = 0 Then
        _WinAPI_EndPaint($hWnd, $tPaint)
    ; EndIf

    Return 0
EndFunc

Func __GUICtrlButton_OnLButtonDown($tCtrl, $wParam, $lParam)
    Local $hWnd = $tCtrl.hwnd
    Local $tRect = _WinAPI_GetWindowRect($hWnd)
    _WinAPI_ScreenToClient(_WinAPI_GetParent($hWnd), $tRect)
    If $tCtrl.isDragging = 0 Then
        $tCtrl.isDragging = 1
        _WinAPI_SetCapture($hWnd)
        _WinAPI_SetWindowPos($hWnd, 0, $tRect.left+1, $tRect.top+1, 0, 0, BitOr($SWP_NOSIZE, $SWP_NOZORDER, $SWP_NOACTIVATE))
    EndIf
    Return 0
EndFunc

Func __GUICtrlButton_OnLButtonUp($tCtrl, $wParam, $lParam)
    If $tCtrl.isDragging = 1 Then
        $tCtrl.isDragging = 0

        Local $hWnd = $tCtrl.hwnd

        _WinAPI_ReleaseCapture()
        Local $tRect = _WinAPI_GetWindowRect($hWnd)
        _WinAPI_ScreenToClient(_WinAPI_GetParent($hWnd), $tRect)
        _WinAPI_SetWindowPos($hWnd, 0, $tRect.left-1, $tRect.top-1, 0, 0, BitOr($SWP_NOSIZE, $SWP_NOZORDER, $SWP_NOACTIVATE))

        Local $tRect = _WinAPI_GetClientRect($hWnd)
        Local $tPoint = _WinAPI_GetCursorPos()
        _WinAPI_ScreenToClient($hWnd, $tPoint)
        If _WinAPI_PtInRect($tRect, $tPoint) Then;FIXME: this won't work as expected with rounded cornors
            __GUICtrlButton_DispatchEvent($tCtrl, $__g_GUICtrlButton_Event_Click)
        EndIf
    EndIf

    Return 0
EndFunc

Func __GUICtrlButton_OnSetFont($tCtrl, $wParam, $lParam)
    ; Change the font
    $tCtrl.hFont = $wParam

    Return 0
EndFunc

Func __GUICtrlButton_OnCaptureChanged($tCtrl, $wParam, $lParam)
    ;TODO: somewhat duplicate of OnLMouseUp, move to it's own function
    If $tCtrl.isDragging = 1 Then
        Local $hWnd = $tCtrl.hwnd
        $tCtrl.isDragging = 0
        Local $tRect = _WinAPI_GetWindowRect($hWnd)
        _WinAPI_ScreenToClient(_WinAPI_GetParent($hWnd), $tRect)
        _WinAPI_SetWindowPos($hWnd, 0, $tRect.left-1, $tRect.top-1, 0, 0, BitOr($SWP_NOSIZE, $SWP_NOZORDER, $SWP_NOACTIVATE))
    EndIf
    Return 0
EndFunc

Func __GUICtrlButton_OnMouseMove($tCtrl, $wParam, $lParam)
    If $tCtrl.isHovered = 0 Then
        Local $hWnd = $tCtrl.hwnd
        $tCtrl.isHovered = 1
        __GUICtrlButton_AddTransition($tCtrl, $__g_GUICtrlButton_Transition_Type_ARGB, 2, 0x13FFFFFF, 150)
        _WinAPI_TrackMouseEvent($hWnd, $TME_LEAVE)
        _WinAPI_InvalidateRect($hWnd, 0, True)
    EndIf
    return 0
EndFunc

Func _GUICtrlButton_Create($hWnd, $text, $iLeft, $iTop, $iWidth, $iHeight)
    If $__g_GUICtrlButton_hProc = 0 Then __GUICtrlButton_StartUp()

    Local $iCtrlID = 0
    If _WinAPI_GetClassName($hWnd) == "AutoIt v3 GUI" Then
        Local $hPreviousWnd = GUISwitch($hWnd)
        $iCtrlID = GUICtrlCreateDummy()
        GUISwitch($hPreviousWnd)
    EndIf

    Local $iExStyle = $WS_EX_TRANSPARENT; $WS_EX_CLIENTEDGE
    Local $iStyle = BitOR($WS_VISIBLE, $WS_CHILD)
    Local $hMenu = $iCtrlID
    Local $hInstance = $__g_GUICtrlButton_hInstance
    Local $pParam = 0

    Local $_hWnd = _WinAPI_CreateWindowEx($iExStyle, $__g_GUICtrlButton_sClass, $text, $iStyle, $iLeft, $iTop, $iWidth, $iHeight, $hWnd, $hMenu, $hInstance, $pParam)

    Return SetExtended($iCtrlID, $_hWnd)
EndFunc

Func _GUICtrlButton_Set_BackgroundColor($hWnd, $iARGB)
    $tCtrl = __GUICtrlButton_GetInstance($hWnd)
    $tCtrl.dwBackgroundColor = $iARGB
    _WinAPI_InvalidateRect($hWnd, 0, True)
EndFunc

Func __GUICtrlButton_ExtTextOut($hdc, $x, $y, $options, $lprect, $lpstring, $lpDx)
    $aRet = DllCall("Gdi32.dll", "BOOLEAN", "ExtTextOutW", "handle", $hdc, "INT", $x, "INT", $y, "UINT", $options, "struct*", $lprect, "WSTR", $lpString, "UINT", StringLen($lpString), "PTR", $lpDx)

    If @error Then Return SetError(@error, @extended, 0)

    Return $aRet[0]
EndFunc

Func __GUICtrlButton_AddTransition($tCtrl, $iType, $iIndex, $iEndVal, $iDuration, $iDelay = 0)
    Local $iSize = DllStructGetSize(DllStructCreate($__g_GUICtrlButton_tagTransition, 1))

    ; --- FIX: Check for existing transition on the same targetIndex ---
    For $i = 0 To $tCtrl.iTransitionCount - 1
        Local $pCheck = $tCtrl.pTransitions + ($i * $iSize)
        Local $tCheck = DllStructCreate($__g_GUICtrlButton_tagTransition, $pCheck)
        If $tCheck.targetIndex = $iIndex Then
            ; Update the existing transition instead of adding a new one
            $tCheck.type = $iType
            $tCheck.dwStartValue = DllStructGetData($tCtrl, $iIndex)
            $tCheck.dwEndValue = $iEndVal
            $tCheck.startTime = _WinAPI_GetTickCount64()
            $tCheck.duration = $iDuration
            $tCheck.delay = $iDelay
            Return ; Exit function, don't add a new one
        EndIf
    Next
    ; -----------------------------------------------------------------

    $tCtrl.iTransitionCount += 1
    $tCtrl.pTransitions = _WinAPI_CreateBuffer($tCtrl.iTransitionCount * $iSize, $tCtrl.pTransitions)

    Local $tTransition = DllStructCreate($__g_GUICtrlButton_tagTransition, $tCtrl.pTransitions + (($tCtrl.iTransitionCount - 1) * $iSize))
    $tTransition.type = $iType
    $tTransition.targetIndex = $iIndex
    $tTransition.dwStartValue = DllStructGetData($tCtrl, $iIndex)
    $tTransition.dwEndValue = $iEndVal
    $tTransition.startTime = _WinAPI_GetTickCount64()
    $tTransition.duration = $iDuration
    $tTransition.delay = $iDelay

    If $tCtrl.iTransitionCount = 1 Then _Timer_SetTimer($tCtrl.hwnd, 16, "__GUICtrlButton_ProcessTransitions") ;_WinAPI_SetTimer($tCtrl.hwnd, )
EndFunc

Func __GUICtrlButton_ProcessTransitions($hWnd, $iMsg, $iIDTimer, $iTime)
    Local $tCtrl = __GUICtrlButton_GetInstance($hWnd)
    If $tCtrl.iTransitionCount = 0 Then
        _Timer_KillTimer($hWnd, $iIDTimer)
        Return
    EndIf

    Local $iSize = DllStructGetSize(DllStructCreate($__g_GUICtrlButton_tagTransition, 1))
    Local $iNow = _WinAPI_GetTickCount64()

    Local $bReRender = False
    Local $i = 0
    While $i < $tCtrl.iTransitionCount
        Local $pCurrent = $tCtrl.pTransitions + (($i) * $iSize)
        Local $tTrans = DllStructCreate($__g_GUICtrlButton_tagTransition, $pCurrent)
        Local $fRatio = ($iNow - $tTrans.StartTime) / $tTrans.Duration
        If $fRatio > 1.0 Then $fRatio = 1.0
        
        Local $iNewVal
        Switch $tTrans.type
            Case $__g_GUICtrlButton_Transition_Type_ARGB
                $iNewVal = __GUICtrlButton_GetLerp($tTrans.dwStartValue, $tTrans.dwEndValue, $fRatio)
            Case Else
                ConsoleWriteError("Unexpected transition type: " & $tTrans.type & @CRLF)
                $i += 1
                ContinueLoop
        EndSwitch
        If $iNewVal <> DllStructGetData($tCtrl, $tTrans.targetIndex) Then
            $bReRender = True
            DllStructSetData($tCtrl, $tTrans.targetIndex, $iNewVal)
        EndIf
        
        If $fRatio >= 1.0 Then
            ; Remove transition by shifting memory or decrementing count for simplicity here:
            $tCtrl.iTransitionCount -= 1

            Local $iRemaining = $tCtrl.iTransitionCount - $i
            If $iRemaining > 0 Then
                ; Shift memory left
                _WinAPI_MoveMemory($pCurrent, $pCurrent + $iSize, $iRemaining * $iSize)
                ; Do not increment $i, as the next item is now at the current position
            Else
                ; No more items, or it was the last item
                If $tCtrl.iTransitionCount == 0 Then
                    _WinAPI_FreeMemory($tCtrl.pTransitions)
                    $tCtrl.pTransitions = 0
                EndIf
                $i += 1
            EndIf
        Else
            $i += 1
        EndIf
    WEnd

    If $bReRender Then _WinAPI_InvalidateRect($hWnd, 0, True)
EndFunc

Func __GUICtrlButton_GetLerp($iStart, $iEnd, $fRatio)
    Local $aIn = _UnpackARGB($iStart), $aOut = _UnpackARGB($iEnd), $aRes[4]
    For $i = 0 To 3
        $aRes[$i] = $aIn[$i] + ($aOut[$i] - $aIn[$i]) * $fRatio
    Next
    Return _PackARGB($aRes[0], $aRes[1], $aRes[2], $aRes[3])
EndFunc

Func _UnpackARGB($iColor)
    Local $a[4] = [BitAND(BitShift($iColor, 24), 0xFF), BitAND(BitShift($iColor, 16), 0xFF), _
                   BitAND(BitShift($iColor, 8), 0xFF), BitAND($iColor, 0xFF)]
    Return $a
EndFunc

Func _PackARGB($a, $r, $g, $b)
    Return BitOR(BitShift($a, -24), BitShift($r, -16), BitShift($g, -8), $b)
EndFunc

Func _GUICtrlButton_AddEventHandler($hWnd, $iEventID, $pFunc)
    Local $tCtrl = __GUICtrlButton_GetInstance($hWnd)
    Local $iSize = DllStructGetSize(DllStructCreate($__g_GUICtrlButton_tagEvent, 1))
    
    ; Increment count and reallocate buffer
    $tCtrl.iEventCount += 1
    $tCtrl.pEvents = _WinAPI_CreateBuffer($tCtrl.iEventCount * $iSize, $tCtrl.pEvents)
    
    ; Calculate offset and write new event
    Local $pNewEvent = $tCtrl.pEvents + (($tCtrl.iEventCount - 1) * $iSize)
    Local $tEvent = DllStructCreate($__g_GUICtrlButton_tagEvent, $pNewEvent)
    
    $tEvent.iEventID = $iEventID
    ; Handle both function names (strings) and actual pointers
    $tEvent.pFunc = IsString($pFunc) ? DllCallbackGetPtr(DllCallbackRegister($pFunc, "none", "hwnd")) : $pFunc
EndFunc

Func __GUICtrlButton_DispatchEvent($tCtrl, $iEventID)
    If $tCtrl.iEventCount = 0 Then Return
    
    Local $iSize = DllStructGetSize(DllStructCreate($__g_GUICtrlButton_tagEvent, 1))
    For $i = 0 To $tCtrl.iEventCount - 1
        Local $tEvent = DllStructCreate($__g_GUICtrlButton_tagEvent, $tCtrl.pEvents + ($i * $iSize))
        If $tEvent.iEventID = $iEventID Then
            ; Execute via DllCall (standard for pointers) or Call()
            DllCallAddress("none", $tEvent.pFunc, "hwnd", $tCtrl.hwnd)
        EndIf
    Next
EndFunc

Func _WinAPI_GetCursorPos()
    Local $tPoint = DllStructCreate($tagPOINT)
	Local $nResult = DllCall("user32.dll", "int", "GetCursorPos", "struct*", $tPoint)
	Return SetExtended($nResult[0], $tPoint)
EndFunc
