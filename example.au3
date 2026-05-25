#include <GUIConstantsEx.au3>
#include "src/button.au3"

Opt("GUIOnEventMode", 1)
Opt("TrayIconHide", 1)

Global $hWnd = GUICreate("Controls Example", 700, 320, -1, -1, BitOR($WS_MINIMIZEBOX, $WS_CAPTION, $WS_POPUP, $WS_SYSMENU), $WS_EX_COMPOSITED)

GUISetBkColor(0x101010, $hWnd)

Global $hButton1 = _GUICtrlButton_Create($hWnd, "Linear", 10, 10, 100, 30)
_GUICtrlButton_Set_BackgroundColor($hButton1, 0x0AFFFFFF)
_GUICtrlButton_AddEventHandler($hButton1, $__g_GUICtrlButton_Event_Click, "MyFunction")
Global $hButton2 = _GUICtrlButton_Create($hWnd, "Ease-in-out", 120, 10, 100, 30)
_GUICtrlButton_Set_BackgroundColor($hButton2, 0x0AFFFFFF)
_GUICtrlButton_AddEventHandler($hButton2, $__g_GUICtrlButton_Event_Click, "MyFunction")
Global $hButton3 = _GUICtrlButton_Create($hWnd, "Bounce", 230, 10, 100, 30)
_GUICtrlButton_Set_BackgroundColor($hButton3, 0x0AFFFFFF)
_GUICtrlButton_AddEventHandler($hButton3, $__g_GUICtrlButton_Event_Click, "MyFunction")

Global $hBox = _GUICtrlButton_Create($hWnd, "", 10, 100, 100, 100)
_GUICtrlButton_Set_BackgroundColor($hBox, 0x0AFFFFFF)

Func MyFunction($hWnd)
    ConsoleWrite("Click"&@CRLF)

    Local $tEasing
    Switch $hWnd
        Case $hButton1
            $tEasing = $__g_GUICtrlButton_Bezier_Linear
        Case $hButton2
            $tEasing = $__g_GUICtrlButton_Bezier_easeInOut
        Case $hButton3
            $tEasing = _GUICtrlButton_Create_CubicBezierEasing(0.175, 0.885, 0.32, 1.275)
    EndSwitch

    _WinAPI_SetWindowPos($hBox, 0, 10, 100, 0, 0, BitOr($SWP_NOSIZE, $SWP_NOZORDER, $SWP_NOACTIVATE))
    Local $tBox = __GUICtrlButton_GetInstance($hBox)
    __GUICtrlButton_AddTransition($tBox, $__g_GUICtrlButton_Transition_Type_Rect, 1, 500, 1000, 0, $tEasing)
EndFunc

GUISetState(@SW_SHOW, $hWnd)

GUISetOnEvent($GUI_EVENT_CLOSE, "OnClose", $hWnd)

While 1
    Sleep(10)
Wend

Func OnClose()
    GUIDelete($hWnd)
    Exit
EndFunc
