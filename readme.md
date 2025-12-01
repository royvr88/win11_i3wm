# i3-Style Workflow on Windows 11  
Using **FancyWM + AutoHotkey** + Windows “Hover-to-Focus” Hack

This setup recreates ~80% of i3wm workflow on Windows 11 with:

- **FancyWM** for automatic tiling, splits, stacking, and moving windows like i3
- **AutoHotkey** for i3-style workspace switching (`Super+1..9`), moving windows (`Super+Shift+1..9`), launching apps, and a safe fullscreen mode
- **Ease of Access** → *Activate window on hover* (a hack to mimic sloppy focus)
- **Flow Launcher** for dmenu-like starting apps

This README explains the full stack and provides a hotkey reference.

---

# 1. FancyWM Configuration

FancyWM handles all tiling behavior.  
Your full configuration (`settings.json`) is:

```
{  
  "ActivationHotkey": "Alt_Win",
  "ActivateOnCapsLock": false,
  "ShowStartupWindow": false,
  "NotifyVirtualDesktopServiceIncompatibility": true,
  "AllocateNewPanelSpace": true,
  "AutoCollapsePanels": true,
  "AutoSplitCount": 2,
  "DelayReposition": true,
  "AnimateWindowMovement": true,
  "ModifierMoveWindow": true,
  "ModifierMoveWindowAutoFocus": true,
  "WindowPadding": 4,
  "PanelHeight": 18,
  "PanelFontSize": 12,
  "ShowFocus": false,
  "ShowFocusDuringAction": true,
  "OverrideAccentColor": false,
  "CustomAccentColor": "#0064FFFF",
  "Keybindings": { ... }
}
```

**Important setting:**  
`ActivationHotkey = Alt+Win` → this is your “i3 Mod key” for FancyWM commands.

FancyWM handles:

- splits (H, V, S)
- focus movement (arrows)
- resizing panes (OEM keys)
- floating toggle
- send/move windows to workspaces
- layout management
- stacking and tabbing

---

# 2. AutoHotkey (AHK) Layer

AHK handles everything FancyWM cannot:

- Real i3-style **workspace switching** (`Super+1..9`)
- **Move window to workspace** (`Super+Shift+1..9`)
- **Launch apps** (`Super+Enter`, `Super+n`, etc.)
- **Fake fullscreen** (`Super+f`) that does *not* break FancyWM layout
- **Close window** (`Super+Shift+q`)
- Reload AHK (`Super+Shift+r`)

AHK also uses `VirtualDesktopAccessor.dll` for direct workspace control without the buggy Windows hotkeys.

---

# 3. Hover-to-Focus (Sloppy Focus)

FancyWM cannot manage focus-follows-mouse.  
AHK cannot do it reliably either due to Windows input restrictions.

So we use the Windows Accessibility hack:

Enable it via:

```
Control Panel →
  Ease of Access →
    Ease of Access Center →
      Make the mouse easier to use →
        ☑ Activate a window by hovering over it
```

**Downside:**  
Windows relocates the mouse during Alt-Tab and when closing windows.  
Annoying, but still the most workable option.

---

# 4. Combined Hotkey Table

## **AHK Hotkeys (i3-style)**

| Action | Hotkey | Notes |
|-------|--------|-------|
| Switch to workspace 1–9 | **Super + 1..9** | Direct jump using VDA |
| Move window to workspace | **Super + Shift + 1..9** | Does NOT switch workspace |
| Open Brave | **Super + n** | |
| Open CMD | **Super + Enter** | classic i3 feel |
| Open Windows Terminal | **Super + r** | |
| Open Notepad | **Super + t** | |
| Open Flow Launcher | **Super + d** | |
| Reload AHK | **Super + Shift + r** | |
| Close window | **Super + Shift + q** | |
| FancyWM-safe fullscreen | **Super + f** | Should not break tiling layout |

---

## **FancyWM Hotkeys (Mod = Alt+Win)**

| Action | Hotkey | Notes |
|--------|--------|-------|
| Toggle FancyWM | **Mod + F11** | |
| Refresh workspace | **Mod + R** | |
| Cancel action | **Mod + Esc** | |
| Focus left/up/right/down | **Mod + ←↑→↓** | |
| Split horizontal | **Mod + H** | |
| Split vertical | **Mod + V** | |
| Create stack panel | **Mod + S** | |
| Toggle floating | **Mod + F** | |
| Move window (tile reposition) | **Mod + Ctrl + Arrows** | |
| Swap windows | **Mod + Shift + Arrows** | |
| Resize pane width | **Mod + [ / ]** | (OEM4 / OEM6) |
| Resize pane height | **Mod + ; / '** | (OEM; / OEM7) |
| Workspace prev | **Mod + Q** | |
| Workspace 1–9 | **Mod + 1..9** | Optional; you override with AHK |
| Move window to workspace | **Mod + Shift + 1..9** | |
| Multi-monitor switching | **Mod + E / F-keys** | |

---

# 5. Recommended Workflow

You now have:

- **FancyWM** controlling the layout *after* a window is created  
- **AHK** controlling the *logic* (workspaces, launchers, fullscreen)  
- **Windows hover-focus** giving you sloppy focus

### Result:
A shockingly close approximation of i3wm on Windows 11.

---

# 6. Known Limitations

| Issue | Cause | Status |
|------|-------|--------|
| Mouse jumps during Alt-Tab | Windows accessibility bug | Cannot fix |
| Some maximized apps fight FancyWM | WinUI restrictions | Use “fake fullscreen” |
| Explorer sometimes steals focus | Normal Windows behavior | Rare |

---

# 7. Future Improvements

Optional upgrades:

- Add key-sequence bindings like i3 (chording mode)
- Add swallow-window behavior (AHK scriptable)

---

# 8. Credits

- FancyWM: https://github.com/FancyWM/fancywm  
- VirtualDesktopAccessor.dll  
- AutoHotkey v1.1  
- Flow Launcher

