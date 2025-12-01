#SingleInstance Force  ; Reload if launched again
#NoEnv
#KeyHistory 0
#UseHook On            ; Make sure we intercept Win+number before the shell
SetWorkingDir %A_ScriptDir%
SendMode Input

; Globals
MAX_DESKTOP_COUNT := 9
desktop_count := 3
curr_desktop := 1
last_desktop := 1

; DLL
virtual_desktop_accessor := DllCall("LoadLibrary", "Str", A_ScriptDir . "\VirtualDesktopAccessor.dll", "Ptr")
if (!virtual_desktop_accessor) {
    MsgBox, 16, Error, Failed to load VirtualDesktopAccessor.dll from %A_ScriptDir%.
    ExitApp
}

global is_window_on_curr_desktop := DllCall("GetProcAddress", "Ptr", virtual_desktop_accessor, "AStr", "IsWindowOnDesktopNumber", "Ptr")
global move_window_to_desktop    := DllCall("GetProcAddress", "Ptr", virtual_desktop_accessor, "AStr", "MoveWindowToDesktopNumber", "Ptr")

; Main
SetKeyDelay, 75
mapDesktopsFromRegistry()
OutputDebug, [loading] desktops: %desktop_count% current: %curr_desktop%
return

; ============================
; DESKTOP DISCOVERY & SYNC
; ============================
mapDesktopsFromRegistry() 
{
    global curr_desktop, desktop_count, MAX_DESKTOP_COUNT

    id_length := 32
    session_id := getSessionId()
    if (session_id) {
        RegRead, curr_desktop_id
            , HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SessionInfo\%session_id%\VirtualDesktops
            , CurrentVirtualDesktop
        if (curr_desktop_id) {
            id_length := StrLen(curr_desktop_id)
        } else {
            OutputDebug, Error getting desktop ID; assuming ID length is %id_length%
        }
    }

    RegRead, desktop_list
        , HKEY_CURRENT_USER
        , SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops
        , VirtualDesktopIDs

    if (desktop_list) {
        desktop_list_length := StrLen(desktop_list)
        desktop_count := Floor(desktop_list_length / id_length)
    } else {
        desktop_count := 1
    }

    i := 0
    while (curr_desktop_id and i < desktop_count) {
        start_pos := (i * id_length) + 1
        desktop_id_iter := SubStr(desktop_list, start_pos, id_length)
        if (desktop_id_iter = curr_desktop_id) {
            curr_desktop := i + 1
            OutputDebug, Current desktop number is %curr_desktop% (ID %desktop_id_iter%).
            break
        }
        i++
    }

    while (desktop_count < MAX_DESKTOP_COUNT) {
        Send, #^d
        desktop_count++
        OutputDebug, [create] desktops: %desktop_count% current: %curr_desktop%
    }
}

getSessionId()
{
    process_id := DllCall("GetCurrentProcessId", "UInt")
    if ErrorLevel {
        OutputDebug, Error getting current process ID: %ErrorLevel%
        return
    }

    DllCall("ProcessIdToSessionId", "UInt", process_id, "UInt*", session_id)
    if ErrorLevel {
        OutputDebug, Error getting current session ID: %ErrorLevel%
        return
    }
    return session_id
}


; ============================
; CORE SWITCH / MOVE LOGIC
; ============================
switchToDesktop(target_desktop)
{
    global curr_desktop, desktop_count, last_desktop
    mapDesktopsFromRegistry()

    if (target_desktop > desktop_count || target_desktop < 1) {
        OutputDebug, [invalid] target: %target_desktop% current: %curr_desktop%
        return
    }

    last_desktop := curr_desktop

    WinActivate, ahk_class Shell_TrayWnd

    while (curr_desktop < target_desktop) {
        Send {LWin down}{LCtrl down}{Right}{LCtrl up}{LWin up}
        curr_desktop++
        OutputDebug, [right] target: %target_desktop% current: %curr_desktop%
    }

    while (curr_desktop > target_desktop) {
        Send {LWin down}{LCtrl down}{Left}{LCtrl up}{LWin up}
        curr_desktop--
        OutputDebug, [left] target: %target_desktop% current: %curr_desktop%
    }

    Sleep, 50
    focusTheForemostWindow(target_desktop)
}

focusTheForemostWindow(target_desktop) {
    foremost_window_id := getForemostWindowId(target_desktop)
    if isWindowNonMinimized(foremost_window_id) {
        WinActivate, ahk_id %foremost_window_id%
    }
}

isWindowNonMinimized(window_id) {
    WinGet MMX, MinMax, ahk_id %window_id%
    return MMX != -1
}

getForemostWindowId(n)
{
    n := n - 1

    WinGet win_id_list, List
    Loop %win_id_list% {
        window_id := win_id_list%A_Index%
        is_window_on_desktop := DllCall(is_window_on_curr_desktop, "UInt", window_id, "UInt", n)
        if (is_window_on_desktop = 1) {
            return window_id
        }
    }
    return 0
}

moveCurrentWindowToDesktop(target_desktop) {
    global desktop_count

    if (target_desktop < 1 || target_desktop > desktop_count)
        return

    WinGet, active_hwnd, ID, A
    if (!active_hwnd)
        return

    active_hwnd := active_hwnd + 0   ; ensure numeric handle

    DllCall(move_window_to_desktop, "UInt", active_hwnd, "UInt", target_desktop - 1)

    ; We stay on this desktop → retile remaining windows here
    Sleep, 150
    ReTileAll()
}




UpdateCurrentDesktop() {
    mapDesktopsFromRegistry()
}

#1::(UpdateCurrentDesktop(), switchToDesktop(1))
#2::(UpdateCurrentDesktop(), switchToDesktop(2))
#3::(UpdateCurrentDesktop(), switchToDesktop(3))
#4::(UpdateCurrentDesktop(), switchToDesktop(4))
#5::(UpdateCurrentDesktop(), switchToDesktop(5))
#6::(UpdateCurrentDesktop(), switchToDesktop(6))
#7::(UpdateCurrentDesktop(), switchToDesktop(7))
#8::(UpdateCurrentDesktop(), switchToDesktop(8))
#9::(UpdateCurrentDesktop(), switchToDesktop(9))


; ============================
; HOTKEYS: DESKTOPS
; ============================

#+1::moveCurrentWindowToDesktop(1)
#+2::moveCurrentWindowToDesktop(2)
#+3::moveCurrentWindowToDesktop(3)
#+4::moveCurrentWindowToDesktop(4)
#+5::moveCurrentWindowToDesktop(5)
#+6::moveCurrentWindowToDesktop(6)
#+7::moveCurrentWindowToDesktop(7)
#+8::moveCurrentWindowToDesktop(8)
#+9::moveCurrentWindowToDesktop(9)

#<!d::ReTileAll()     ; Win + ADlt + D tile-all

;==========================================================
; BASIC TILING
;==========================================================
Tile_Left() {
    Tile_Prepare()
    GetWorkArea(L,T,R,B)
    W := (R-L)//2
    WinMove, A,, L, T, W, B-T
}

Tile_Right() {
    Tile_Prepare()
    GetWorkArea(L,T,R,B)
    W := (R-L)//2
    WinMove, A,, L+W, T, W, B-T
}

Tile_Top() {
    Tile_Prepare()
    GetWorkArea(L,T,R,B)
    H := (B-T)//2
    WinMove, A,, L, T, R-L, H
}

Tile_Bottom() {
    Tile_Prepare()
    GetWorkArea(L,T,R,B)
    H := (B-T)//2
    WinMove, A,, L, T+H, R-L, H
}

Tile_Full() {
    Tile_Prepare()
    GetWorkArea(L,T,R,B)
    WinMove, A,, L, T, R-L, B-T
}


;==========================================================
; QUADRANTS
;==========================================================
Tile_TopLeft() {
    Tile_Prepare()
    GetWorkArea(L,T,R,B)
    W := (R-L)//2
    H := (B-T)//2
    WinMove, A,, L, T, W, H
}

Tile_TopRight() {
    Tile_Prepare()
    GetWorkArea(L,T,R,B)
    W := (R-L)//2
    H := (B-T)//2
    WinMove, A,, L+W, T, W, H
}

Tile_BottomLeft() {
    Tile_Prepare()
    GetWorkArea(L,T,R,B)
    W := (R-L)//2
    H := (B-T)//2
    WinMove, A,, L, T+H, W, H
}

Tile_BottomRight() {
    Tile_Prepare()
    GetWorkArea(L,T,R,B)
    W := (R-L)//2
    H := (B-T)//2
    WinMove, A,, L+W, T+H, W, H
}


; ============================
;  TILING HOTKEYS (i3-ish)
; ============================
#!h::Tile_Left()
#!l::Tile_Right()
#!k::Tile_Top()
#!j::Tile_Bottom()

#f::Tile_Full()

#!1::Tile_TopLeft()
#!2::Tile_TopRight()
#!3::Tile_BottomLeft()
#!4::Tile_BottomRight()



;==========================================================
; HOVER-TO-FOCUS (focus follows mouse)
;==========================================================
#InstallMouseHook
SetTimer, WatchMouse, 50
return

WatchMouse:
    MouseGetPos,,, id
    if (!id)
        return

    WinGetClass, cls, ahk_id %id%
    if (cls = "Shell_TrayWnd" or cls = "WorkerW" or cls = "Progman")
        return

    if (id != last) {
        last := id
        WinActivate, ahk_id %id%
    }
return



;==========================================================
; TILING HELPERS
;==========================================================
GetWorkArea(ByRef L, ByRef T, ByRef R, ByRef B) {
    SysGet, mon, MonitorWorkArea
    L := monLeft
    T := monTop
    R := monRight
    B := monBottom
}

Tile_Prepare() {
    WinGet, mmx, MinMax, A
    if (mmx = 1)
        WinRestore, A
}



;==========================================================
; CLOSE AND RELAYOUT
;==========================================================
CloseWindowAndRelayout() {
    WinGet, hwnd, ID, A
    if (!hwnd)
        return
    WinClose, ahk_id %hwnd%
    Sleep, 150
    ReTileAll()
}
ReTileAll() {
    global curr_desktop

    WinGet, idlist, List
    arr := []

    Loop %idlist% {
        id := idlist%A_Index%

        ; Only windows on current desktop
        if !IsOnCurrentDesktop(id)
            continue

        ; Ignore taskbar / desktop / shell
        WinGetClass, cls, ahk_id %id%
        if (cls = "Shell_TrayWnd" or cls = "WorkerW" or cls = "Progman")
            continue

        ; Ignore minimized
        WinGet, mmx, MinMax, ahk_id %id%
        if (mmx = -1)
            continue

        arr.Push(id)
    }

    count := arr.Length()
    if (count = 0)
        return

    GetWorkArea(L,T,R,B)
    width := (R-L) // count

    Loop %count% {
        idx := A_Index
        id := arr[idx]
        x := L + (idx-1)*width
        WinMove, ahk_id %id%,, x, T, width, B-T
    }
}


IsOnCurrentDesktop(hwnd) {
    global curr_desktop
    ; curr_desktop is 1-based, DLL expects 0-based index
    return DllCall(is_window_on_curr_desktop, "UInt", hwnd, "UInt", curr_desktop-1)
}

; SUPER+SHIFT+Q -> close window and relayout
#+q::CloseWindowAndRelayout()


