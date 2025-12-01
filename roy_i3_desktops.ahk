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

    ; Get the current desktop UUID. Length should be 32 normally.
    id_length := 32
    session_id := getSessionId()
    if (session_id) {
        RegRead, curr_desktop_id, HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SessionInfo\%session_id%\VirtualDesktops, CurrentVirtualDesktop
        if (curr_desktop_id) {
            id_length := StrLen(curr_desktop_id)
        } else {
            OutputDebug, Error getting desktop ID; assuming ID length is %id_length%
        }
    }

    ; Get all desktop IDs
    RegRead, desktop_list, HKEY_CURRENT_USER, SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops, VirtualDesktopIDs
    if (desktop_list) {
        desktop_list_length := StrLen(desktop_list)
        desktop_count := Floor(desktop_list_length / id_length)
    } else {
        desktop_count := 1
    }

    ; Figure out which desktop we’re on
    i := 0
    while (curr_desktop_id and i < desktop_count) {
        start_pos := (i * id_length) + 1
        desktop_id_iter := SubStr(desktop_list, start_pos, id_length)
        OutputDebug, Iterator points at %desktop_id_iter% (index %i%).

        if (desktop_id_iter = curr_desktop_id) {
            curr_desktop := i + 1
            OutputDebug, Current desktop number is %curr_desktop% (ID %desktop_id_iter%).
            break
        }
        i++
    }

    ; Ensure we always have MAX_DESKTOP_COUNT desktops
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
    OutputDebug, Current Process Id: %process_id%

    DllCall("ProcessIdToSessionId", "UInt", process_id, "UInt*", session_id)
    if ErrorLevel {
        OutputDebug, Error getting session ID: %ErrorLevel%
        return
    }
    OutputDebug, Current Session ID: %session_id%
    return session_id
}

; ============================
; CORE SWITCH / MOVE LOGIC
; ============================
switchToDesktop(target_desktop)
{
    global curr_desktop, desktop_count, last_desktop
    mapDesktopsFromRegistry()  ; resync with reality (in case you switched via Win+Ctrl+Arrow)

    ; Don’t attempt to switch to an invalid desktop
    if (target_desktop > desktop_count || target_desktop < 1) {
        OutputDebug, [invalid] target: %target_desktop% current: %curr_desktop%
        return
    }

    last_desktop := curr_desktop

    ; Prevent intermediate windows from stealing the Win+Ctrl+Arrow combo
    WinActivate, ahk_class Shell_TrayWnd

    ; Go right until we reach the target
    while (curr_desktop < target_desktop) {
        Send {LWin down}{LCtrl down}{Right}{LCtrl up}{LWin up}
        curr_desktop++
        OutputDebug, [right] target: %target_desktop% current: %curr_desktop%
    }

    ; Go left until we reach the target
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
    n := n - 1 ; Desktops start at 0 in DLL/Windows, 1 in this script

    ; win_id_list contains a list of windows IDs ordered from top to bottom.
    WinGet win_id_list, List
    Loop %win_id_list% {
        window_id := win_id_list%A_Index%
        is_window_on_desktop := DllCall(is_window_on_curr_desktop, "UInt", window_id, "UInt", n)
        if (is_window_on_desktop == 1) {
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

    DllCall(move_window_to_desktop, "UInt", active_hwnd, "UInt", target_desktop - 1)
    ; Do NOT follow the window – you asked to stay on current desktop
    ; If you *do* want to follow it, replace the line above with:
    ; switchToDesktop(target_desktop)
}

; ============================
; HOTKEYS
; ============================
; Win+1..9 -> switch to desktop N
#1::switchToDesktop(1)
#2::switchToDesktop(2)
#3::switchToDesktop(3)
#4::switchToDesktop(4)
#5::switchToDesktop(5)
#6::switchToDesktop(6)
#7::switchToDesktop(7)
#8::switchToDesktop(8)
#9::switchToDesktop(9)

; Win+Shift+1..9 -> move current window to desktop N (stay on current desktop)
#+1::moveCurrentWindowToDesktop(1)
#+2::moveCurrentWindowToDesktop(2)
#+3::moveCurrentWindowToDesktop(3)
#+4::moveCurrentWindowToDesktop(4)
#+5::moveCurrentWindowToDesktop(5)
#+6::moveCurrentWindowToDesktop(6)
#+7::moveCurrentWindowToDesktop(7)
#+8::moveCurrentWindowToDesktop(8)
#+9::moveCurrentWindowToDesktop(9)




; =====================================
;  FIXED TILING FUNCTIONS (AHK v1)
;  - Win+Shift+H/J/K/L for splits
;  - Automatically handles maximized windows
; =====================================

Tile_PrepareWindow() {
    WinGet, mmx, MinMax, A
    if (mmx = 1)   ; window is maximized
        WinRestore, A
}

Tile_Left() {
    Tile_PrepareWindow()
    WinGet, h, ID, A
    SysGet, mon, MonitorWorkArea
    WinMove, ahk_id %h%, , monLeft, monTop, (monRight-monLeft)//2, (monBottom-monTop)
}

Tile_Right() {
    Tile_PrepareWindow()
    WinGet, h, ID, A
    SysGet, mon, MonitorWorkArea
    half := (monRight - monLeft) // 2
    WinMove, ahk_id %h%, , monLeft + half, monTop, half, (monBottom-monTop)
}

Tile_Top() {
    Tile_PrepareWindow()
    WinGet, h, ID, A
    SysGet, mon, MonitorWorkArea
    WinMove, ahk_id %h%, , monLeft, monTop, (monRight-monLeft), (monBottom-monTop)//2
}

Tile_Bottom() {
    Tile_PrepareWindow()
    WinGet, h, ID, A
    SysGet, mon, MonitorWorkArea
    half_h := (monBottom - monTop) // 2
    WinMove, ahk_id %h%, , monLeft, monTop + half_h, (monRight-monLeft), half_h
}

Tile_Full() {
    Tile_PrepareWindow()
    WinGet, h, ID, A
    SysGet, mon, MonitorWorkArea
    WinMove, ahk_id %h%, , monLeft, monTop, (monRight-monLeft), (monBottom-monTop)
}

; -------------------------
; Quadrants
; -------------------------
Tile_TopLeft() {
    Tile_PrepareWindow()
    WinGet, h, ID, A
    SysGet, mon, MonitorWorkArea
    w := (monRight-monLeft)//2
    hgt := (monBottom-monTop)//2
    WinMove, ahk_id %h%, , monLeft, monTop, w, hgt
}

Tile_TopRight() {
    Tile_PrepareWindow()
    WinGet, h, ID, A
    SysGet, mon, MonitorWorkArea
    w := (monRight-monLeft)//2
    hgt := (monBottom-monTop)//2
    WinMove, ahk_id %h%, , monLeft + w, monTop, w, hgt
}

Tile_BottomLeft() {
    Tile_PrepareWindow()
    WinGet, h, ID, A
    SysGet, mon, MonitorWorkArea
    w := (monRight-monLeft)//2
    hgt := (monBottom-monTop)//2
    WinMove, ahk_id %h%, , monLeft, monTop + hgt, w, hgt
}

Tile_BottomRight() {
    Tile_PrepareWindow()
    WinGet, h, ID, A
    SysGet, mon, MonitorWorkArea
    w := (monRight-monLeft)//2
    hgt := (monBottom-monTop)//2
    WinMove, ahk_id %h%, , monLeft + w, monTop + hgt, w, hgt
}




; ============================
;  TILING HOTKEYS (i3-like)
; ============================

#!h::Tile_Left()
#!l::Tile_Right()
#!k::Tile_Top()
#!j::Tile_Bottom()

; Fullscreen tile
#f::Tile_Full()


#!1::Tile_TopLeft()       ; Win+Ctrl+1
#!2::Tile_TopRight()      ; Win+Ctrl+2
#!3::Tile_BottomLeft()    ; Win+Ctrl+3
#!4::Tile_BottomRight()   ; Win+Ctrl+4
