#include <GUIConstantsEx.au3>
#include "src/button.au3"

Opt("GUIOnEventMode", 1)
Opt("TrayIconHide", 1)

Global $hWnd = GUICreate("Controls Example", 700, 320, -1, -1, BitOR($WS_MINIMIZEBOX, $WS_CAPTION, $WS_POPUP, $WS_SYSMENU), $WS_EX_COMPOSITED)

GUISetBkColor(0x101010, $hWnd)

$hButton = _GUICtrlButton_Create($hWnd, "Foo", 10, 10, 100, 30)
_GUICtrlButton_Set_BackgroundColor($hButton, 0x0AFFFFFF)
$hButton = _GUICtrlButton_Create($hWnd, "Bar", 120, 10, 100, 30)
_GUICtrlButton_Set_BackgroundColor($hButton, 0x0AFFFFFF)
$hButton = _GUICtrlButton_Create($hWnd, "Baz", 230, 10, 100, 30)
_GUICtrlButton_Set_BackgroundColor($hButton, 0x0AFFFFFF)

GUISetState(@SW_SHOW, $hWnd)

GUISetOnEvent($GUI_EVENT_CLOSE, "OnClose", $hWnd)

While 1
    Sleep(10)
Wend

Func OnClose()
    GUIDelete($hWnd)
    Exit
EndFunc
