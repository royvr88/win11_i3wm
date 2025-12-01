import ctypes
import threading
import time
import os

import win32gui
from pystray import Icon
import pystray 
from pystray import MenuItem as item
from PIL import Image, ImageDraw, ImageFont


# --- Load DLL (relative path) ---
DLL_PATH = os.path.join(os.path.dirname(__file__), "VirtualDesktopAccessor.dll")
vda = ctypes.WinDLL(DLL_PATH)
vda.GetCurrentDesktopNumber.restype = ctypes.c_int


def on_exit(icon, item):
    icon.stop()


# --- Pre-generate icons for ~10 workspaces ---
def make_icon(num: int):
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    font = ImageFont.load_default()

    # i3-style square block
    draw.rectangle((1, 1, 15, 15), fill=(255, 255, 255, 255))

    text = str(num)
    bbox = draw.textbbox((0, 0), text, font=font)
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]
    x = (16 - w) // 2
    y = (16 - h) // 2

    draw.text((x, y), text, fill=(0, 0, 0, 255), font=font)
    return img

# Preload 1–10 workspace icons (adjust if you use more)
icons_cache = {i: make_icon(i) for i in range(1, 11)}

last_num = None


def updater(icon):
    global last_num

    while True:
        try:
            current = vda.GetCurrentDesktopNumber() + 1
        except:
            time.sleep(1.0)
            continue

        # Only update when changed
        if current != last_num:
            if current in icons_cache:
                icon.icon = icons_cache[current]
            else:
                # fallback: generate on-demand and cache it
                icons_cache[current] = make_icon(current)
                icon.icon = icons_cache[current]

            icon.title = f"Desktop {current}"
            last_num = current

        # ULTRA-LOW CPU: wait 1 second
        time.sleep(1.0)


def main():
    # Get the actual starting workspace
    try:
        current = vda.GetCurrentDesktopNumber() + 1
    except:
        current = 1

    # Create with correct initial icon + title
    icon = Icon(
        "DesktopIndicator",
        icons_cache.get(current, icons_cache[1]),
        f"Desktop {current}",
        menu=pystray.Menu(
            item('Exit', on_exit)
        )
    )

    thread = threading.Thread(target=updater, args=(icon,), daemon=True)
    thread.start()
    icon.run()


if __name__ == "__main__":
    main()
