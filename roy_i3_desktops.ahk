#SingleInstance Force
#NoEnv
#UseHook On
SendMode Input
SetWorkingDir %A_ScriptDir%

; ====================================================
; Load DLL
; ====================================================
vda := DllCall("LoadLibrary", "Str", A_ScriptDir "\VirtualDesktopAccessor.dll", "Ptr")
if (!vda) {
    MsgBox, 16, ERROR, Failed to load VirtualDesktopAccessor.dll
    ExitApp
}

; Core exports
global fnMove := DllCall("GetProcAddress", "Ptr", vda, "AStr", "MoveWindowToDesktopNumber", "Ptr")
global fnGo   := DllCall("GetProcAddress", "Ptr", vda, "AStr", "GoToDesktopNumber", "Ptr")

; TRY TO FIND A VALID “get current desktop” EXPORT
global fnGetCurrent := 0

for k, name in ["GetCurrentDesktopNumber", "GetDesktopNumber", "GetCurrentDesktop"] {
    p := DllCall("GetProcAddress", "Ptr", vda, "AStr", name, "Ptr")
    if (p) {
        fnGetCurrent := p
        break
    }
}

if (!fnGetCurrent) {
    MsgBox, 48, WARNING, No GetCurrentDesktop function in DLL.`nScript will still work, but cannot detect current desktop.
}

; ====================================================
; Core functions
; ====================================================

GetCurrentDesktop() {
    global fnGetCurrent
    if (!fnGetCurrent)
        return 1
    return DllCall(fnGetCurrent, "Int")
}

GetDesktopCount() {
    ; Known working DLL export
    return DllCall("VirtualDesktopAccessor\GetDesktopCount", "Int")
}

switchToDesktop(n) {
    if (n < 1)
        return
    count := GetDesktopCount()
    if (n > count)
        return

    DllCall("VirtualDesktopAccessor\GoToDesktopNumber", "Int", n - 1)
}

moveCurrentWindowToDesktop(n) {
    count := GetDesktopCount()
    if (n < 1 || n > count)
        return

    WinGet, hwnd, ID, A
    hwnd := hwnd + 0
    DllCall("VirtualDesktopAccessor\MoveWindowToDesktopNumber", "Ptr", hwnd, "Int", n - 1)
}

; ====================================================
; WORKSPACE HOTKEYS — ALWAYS CORRECT
; ====================================================

#1::switchToDesktop(1)
#2::switchToDesktop(2)
#3::switchToDesktop(3)
#4::switchToDesktop(4)
#5::switchToDesktop(5)
#6::switchToDesktop(6)
#7::switchToDesktop(7)
#8::switchToDesktop(8)
#9::switchToDesktop(9)

#+1::moveCurrentWindowToDesktop(1)
#+2::moveCurrentWindowToDesktop(2)
#+3::moveCurrentWindowToDesktop(3)
#+4::moveCurrentWindowToDesktop(4)
#+5::moveCurrentWindowToDesktop(5)
#+6::moveCurrentWindowToDesktop(6)
#+7::moveCurrentWindowToDesktop(7)
#+8::moveCurrentWindowToDesktop(8)
#+9::moveCurrentWindowToDesktop(9)

; ====================================================
; BASIC LAUNCHERS (i3-like)
; ====================================================

#n::Run, brave
#Enter::Run, cmd
#t::Run, notepad
#d::Run, flow_launcher.lnk
#+r::Reload
#+q::WinClose, A

; ====================================================
; FancyWM-safe fullscreen
; ====================================================
#f::
    WinGet, curMax, MinMax, A
    if (curMax = 1) {
        WinRestore, A
        WinGetPos, X,Y,W,H, A
        WinMove, A,, X,Y, W-1, H-1
        Sleep 30
        WinMove, A,, X,Y, W,H
        return
    }
    SysGet, m, MonitorWorkArea
    WinRestore, A
    WinMove, A,, mLeft, mTop, mRight-mLeft, mBottom-mTop
    WinMaximize, A
return





#Requires AutoHotkey v1

; -------- HELPER: Get window rectangle --------
GetWinRect(hwnd, ByRef x, ByRef y, ByRef w, ByRef h) {
    VarSetCapacity(rect, 16, 0)
    DllCall("GetWindowRect", "Ptr", hwnd, "Ptr", &rect)
    x := NumGet(rect, 0, "Int")
    y := NumGet(rect, 4, "Int")
    w := NumGet(rect, 8, "Int") - x
    h := NumGet(rect, 12, "Int") - y
}

; -------- HELPER: Get all visible windows --------
GetVisibleWindows() {
    WinGet, idList, List
    windows := []
    Loop % idList {
        hwnd := idList%A_Index%
        WinGet, style, Style, ahk_id %hwnd%
        WinGet, exStyle, ExStyle, ahk_id %hwnd%
        if (style & 0x10000000) && !(exStyle & 0x80)  ; WS_VISIBLE, not toolwindow
            windows.Push(hwnd)
    }
    return windows
}

; -------- CORE: Focus window in direction --------
FocusDirection(direction) {
    WinGet, active, ID, A
    if (!active) {
        return
    }

    GetWinRect(active, ax, ay, aw, ah)
    acx := ax + aw/2
    acy := ay + ah/2

    windows := GetVisibleWindows()
    best := ""
    bestDist := 99999

    for index, hwnd in windows {
        if (hwnd = active)
            continue

        GetWinRect(hwnd, x, y, w, h)
        cx := x + w/2
        cy := y + h/2

        dx := cx - acx
        dy := cy - acy

        if (direction = "left"  && dx < 0 && Abs(dy) < Abs(dx) * 1.5) {
            dist := Abs(dx)
        }
        else if (direction = "right" && dx > 0 && Abs(dy) < Abs(dx) * 1.5) {
            dist := Abs(dx)
        }
        else if (direction = "up"    && dy < 0 && Abs(dx) < Abs(dy) * 1.5) {
            dist := Abs(dy)
        }
        else if (direction = "down"  && dy > 0 && Abs(dx) < Abs(dy) * 1.5) {
            dist := Abs(dy)
        }
        else {
            continue
        }

        if (dist < bestDist) {
            bestDist := dist
            best := hwnd
        }
    }

    if (best) {
        WinActivate, ahk_id %best%
    }
}




; -------- HOTKEYS --------
#Left::FocusDirection("left")
#Right::FocusDirection("right")
#Up::FocusDirection("up")
#Down::FocusDirection("down")

