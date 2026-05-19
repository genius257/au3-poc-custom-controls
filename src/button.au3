#include <WinAPISysWin.au3>
#include <WinAPICom.au3>
#include <WindowsConstants.au3>
#include <WinAPIMem.au3>
#include <WinAPIHObj.au3>
#include <WinAPIGdi.au3>
#include <WinAPIRes.au3>
#include <GDIPlus.au3>
#include <WinAPISys.au3>

If Not IsDeclared("MA_ACTIVATE") Then Global Const $MA_ACTIVATE  = 1
If Not IsDeclared("ETO_OPAQUE") Then Global Const $ETO_OPAQUE = 2
If Not IsDeclared("PRF_CLIENT") Then Global Const $PRF_CLIENT = 0x00000004

Global Const $__g_GUICtrlButton_WM_ = $WM_USER + 1
Global Const $__g_GUICtrlButton_tagCREATESTRUCTW = "PTR lpCreateParams;HANDLE hInstance;HANDLE hMenu;HWND hwndParent;INT cy;INT cx;INT y;INT x;LONG style;PTR lpszName;PTR lpszClass;DWORD dwExStyle;"
Global Const $__g_GUICtrlButton_tagCtrl = "DWORD crForeGnd;DWORD crBackGnd;HANDLE hFont;HWND hwnd;BOOLEAN isHovered;BOOLEAN isDragging;"
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
            $tCtrl.crForeGnd = _WinAPI_GetSysColor($COLOR_WINDOWTEXT)
            $tCtrl.crBackGnd = _WinAPI_GetSysColor($COLOR_WINDOW)
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
    Local $ps
    Local $hOldFont
    Local $szText
    Local $rect

    Local $hWnd = $tCtrl.hwnd

    ; If $wParam = 0 Then
        ; Get a device context for this window
        $hdc = _WinAPI_BeginPaint($hWnd, $ps)
    ; Else
    ;     $hdc = $wParam
    ; EndIf

    _SendMessage(_WinAPI_GetParent($hWnd), $WM_ERASEBKGND, $hdc, 0)
    _SendMessage(_WinAPI_GetParent($hWnd), $WM_PRINTCLIENT, $hdc, $PRF_CLIENT)

    $hOldFont = _WinAPI_SelectObject($hdc, $tCtrl.hFont)
    Local $hGraphics = _GDIPlus_GraphicsCreateFromHDC($hdc)
    _GDIPlus_GraphicsSetSmoothingMode($hGraphics, $GDIP_SMOOTHINGMODE_ANTIALIAS)
    ;_GDIPlus_GraphicsSetPixelOffsetMode($hGraphics, $GDIP_PIXELOFFSETMODE_HALF)
    _GDIPlus_GraphicsSetTextRenderingHint($hGraphics, $GDIP_TEXTRENDERINGHINTCLEARTYPEGRIDFIT)
    Local $r = 8
    $rect = _WinAPI_GetClientRect($hWnd)
    Local $w = $rect.Right - 1, $h = $rect.Bottom - 1
    Local $hPath = _GDIPlus_PathCreate()
    _GDIPlus_PathAddArc($hPath, 0, 0, $r, $r, 180, 90)
    _GDIPlus_PathAddArc($hPath, $w - $r, 0, $r, $r, 270, 90)
    _GDIPlus_PathAddArc($hPath, $w - $r, $h - $r, $r, $r, 0, 90)
    _GDIPlus_PathAddArc($hPath, 0, $h - $r, $r, $r, 90, 90)
    _GDIPlus_PathCloseFigure($hPath)
    Local $hBrush = _GDIPlus_BrushCreateSolid($tCtrl.isHovered ? 0x13FFFFFF : 0x0AFFFFFF); 0x13... When hover
    Local $hPen = _GDIPlus_PenCreate(0x28FFFFFF)
    _GDIPlus_GraphicsFillPath($hGraphics, $hPath, $hBrush)
    _GDIPlus_GraphicsDrawPath($hGraphics, $hPath, $hPen)

    ;Local $hFont = _SendMessage($hWnd, $WM_GETFONT, 0, 0)
    ;If $hFont = 0 Then $hFont = _WinAPI_GetStockObject($DEFAULT_GUI_FONT)
    Local $gdiplusFont = DllCall($__g_hGDIPDll, "Int", "GdipCreateFontFromDC", "Handle", $hdc, "Ptr*", 0)[2]
    ;Local $gdiplusFont = DllCall($__g_hGDIPDll, "INT", "GdipCreateFontFromLogfontW", "HANDLE", $hdc, "HANDLE", $tCtrl.hFont, "PTR*", 0)[3]
    Local $hFormat = _GDIPlus_StringFormatCreate()
    _GDIPlus_StringFormatSetAlign($hFormat, 1)
    _GDIPlus_StringFormatSetLineAlign($hFormat, 1)

    _GDIPlus_BrushSetSolidColor($hBrush, $tCtrl.isHovered ? 0xFFFAFAFA : 0xFFE2E2E2)
    Local $tRect = _GDIPlus_RectFCreate(0, 0, $rect.right, $rect.bottom)
    _GDIPlus_GraphicsDrawStringEx($hGraphics, _WinAPI_GetWindowText($hWnd), $gdiplusFont, $trect, $hFormat, $hBrush)

    _GDIPlus_FontDispose($gdiplusFont)
    _GDIPlus_StringFormatDispose($hFormat)

    _GDIPlus_PenDispose($hPen)
    _GDIPlus_BrushDispose($hBrush)
    _GDIPlus_PathDispose($hPath)
    _GDIPlus_GraphicsDispose($hGraphics)

    ; Set the font we are going to use
    ; $hOldFont = _WinAPI_SelectObject($hdc, $tCtrl.hFont)

    ; Set the text colours
    _WinAPI_SetTextColor($hdc, $tCtrl.crForeGnd)
    ; _WinAPI_SetBkColor($hdc, $tCtrl.crBackGnd)
    _WinAPI_SetBkColor($hdc, -1)

    ; Find the text to draw
    $szText = _WinAPI_GetWindowText($hWnd)

    ; Work out where to draw
    $rect = _WinAPI_GetClientRect($hWnd)

    ; Find out how big the text will be
    Local $sz = _WinAPI_GetTextExtentPoint32($hdc, $szText)

    ; Center the text
    Local $x = ($rect.right - $sz.x) / 2
    Local $y = ($rect.bottom - $sz.y) / 2

    ; Draw the text
    ; __GUICtrlButton_ExtTextOut($hdc, $x, $y, $ETO_OPAQUE, $rect, $szText, 0)
    ; __GUICtrlButton_ExtTextOut($hdc, $x, $y, 0, $rect, $szText, 0)

    ; Restore the old font when we have finished
    _WinAPI_SelectObject($hdc, $hOldFont)

    ; Release the device context
    ; If $wParam = 0 Then
        _WinAPI_EndPaint($hWnd, $ps)
    ; EndIf

    Return 0
EndFunc

Func __GUICtrlButton_OnLButtonDown($tCtrl, $wParam, $lParam)
    Local $hWnd = $tCtrl.hwnd
    Local $rect = _WinAPI_GetWindowRect($hWnd)
    _WinAPI_ScreenToClient(_WinAPI_GetParent($hWnd), $rect)
    If $tCtrl.isDragging = 0 Then
        $tCtrl.isDragging = 1
        _WinAPI_SetCapture($hWnd)
        _WinAPI_SetWindowPos($hWnd, 0, $rect.left+1, $rect.top+1, 0, 0, BitOr($SWP_NOSIZE, $SWP_NOZORDER, $SWP_NOACTIVATE))
    EndIf
    Return 0
EndFunc

Func __GUICtrlButton_OnLButtonUp($tCtrl, $wParam, $lParam)
    If $tCtrl.isDragging = 1 Then
        $tCtrl.isDragging = 0

        Local $hWnd = $tCtrl.hwnd

        _WinAPI_ReleaseCapture()
        Local $rect = _WinAPI_GetWindowRect($hWnd)
        _WinAPI_ScreenToClient(_WinAPI_GetParent($hWnd), $rect)
        _WinAPI_SetWindowPos($hWnd, 0, $rect.left-1, $rect.top-1, 0, 0, BitOr($SWP_NOSIZE, $SWP_NOZORDER, $SWP_NOACTIVATE))
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
        Local $rect = _WinAPI_GetWindowRect($hWnd)
        _WinAPI_ScreenToClient(_WinAPI_GetParent($hWnd), $rect)
        _WinAPI_SetWindowPos($hWnd, 0, $rect.left-1, $rect.top-1, 0, 0, BitOr($SWP_NOSIZE, $SWP_NOZORDER, $SWP_NOACTIVATE))
    EndIf
    Return 0
EndFunc

Func __GUICtrlButton_OnMouseMove($tCtrl, $wParam, $lParam)
    If $tCtrl.isHovered = 0 Then
        Local $hWnd = $tCtrl.hwnd
        $tCtrl.isHovered = 1
        _WinAPI_TrackMouseEvent($hWnd, $TME_LEAVE)
        _WinAPI_InvalidateRect($hWnd, 0, True)
    EndIf
    return 0
EndFunc

Func _GUICtrlButton_Create($hWnd, $text, $iLeft, $iTop, $iWidth, $iHeight)
    If $__g_GUICtrlButton_hProc = 0 Then __GUICtrlButton_StartUp()

    Local $_previous = GUISwitch($hWnd)
    Local $iCtrlID = GUICtrlCreateDummy()
    GUISwitch($_previous)

    Local $iExStyle = 0; $WS_EX_CLIENTEDGE
    Local $iStyle = BitOR($WS_VISIBLE, $WS_CHILD)
    Local $hMenu = $iCtrlID
    Local $hInstance = $__g_GUICtrlButton_hInstance
    Local $pParam = 0

    Local $_hWnd = _WinAPI_CreateWindowEx($iExStyle, $__g_GUICtrlButton_sClass, $text, $iStyle, $iLeft, $iTop, $iWidth, $iHeight, $hWnd, $hMenu, $hInstance, $pParam)

    Return $_hWnd
EndFunc

Func __GUICtrlButton_ExtTextOut($hdc, $x, $y, $options, $lprect, $lpstring, $lpDx)
    $aRet = DllCall("Gdi32.dll", "BOOLEAN", "ExtTextOutW", "handle", $hdc, "INT", $x, "INT", $y, "UINT", $options, "struct*", $lprect, "WSTR", $lpString, "UINT", StringLen($lpString), "PTR", $lpDx)

    If @error Then Return SetError(@error, @extended, 0)

    Return $aRet[0]
EndFunc
