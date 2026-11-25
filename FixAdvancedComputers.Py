import ctypes
from ctypes import wintypes
import threading
import time

try:
    import pyautogui
except ImportError as exc:
    missing = exc.name or "pyautogui"
    raise SystemExit(
        f"Missing dependency: {missing}\n"
        "Install with: py -m pip install pyautogui"
    ) from exc


RAW_BASE_URL = "https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft"

# Ctrl+P: install the Mana Pool transmitter on a Mana Pool computer.
MANA_POOL_COMMANDS = [
    "delete mana_tx.lua",
    f"wget {RAW_BASE_URL}/mana-network/mana_tx.lua mana_tx.lua",
    "delete startup.lua",
    f"wget {RAW_BASE_URL}/mana-network/startup_tx.lua startup.lua",
    "mana_tx.lua",
]

# Ctrl+M: install the expandable receiver/dashboard on the dedicated monitor computer.
MONITOR_COMMANDS = [
    "delete monitor.lua",
    f"wget {RAW_BASE_URL}/monitor/monitor.lua monitor.lua",
    "delete startup.lua",
    f"wget {RAW_BASE_URL}/monitor/startup.lua startup.lua",
    "monitor.lua",
]

# Ctrl+B: install the Block Reader transmitter on each machine-side computer.
MACHINE_COMMANDS = [
    "delete machines.lua",
    f"wget {RAW_BASE_URL}/machines/machines.lua machines.lua",
    "delete startup.lua",
    f"wget {RAW_BASE_URL}/machines/startup.lua startup.lua",
    "machines.lua",
]

TARGET_WINDOW_HINTS = ("minecraft", "project infinity")
COMMAND_INTERVAL = 0.015
DELETE_DELAY = 0.35
DOWNLOAD_DELAY = 3.0
START_DELAY = 0.8

run_lock = threading.Lock()
stop_event = threading.Event()

pyautogui.FAILSAFE = True
pyautogui.PAUSE = 0.05


def get_active_window_title():
    """Return the current Windows foreground title without touching keyboard input."""
    user32 = ctypes.windll.user32
    window_handle = user32.GetForegroundWindow()
    title_length = user32.GetWindowTextLengthW(window_handle)
    title_buffer = ctypes.create_unicode_buffer(title_length + 1)
    user32.GetWindowTextW(window_handle, title_buffer, len(title_buffer))
    return title_buffer.value


def is_minecraft_window_focused():
    """Only listen for installer shortcuts while Project Infinity is focused."""
    try:
        title = get_active_window_title()
    except Exception:
        return False

    return bool(title) and any(hint in title.casefold() for hint in TARGET_WINDOW_HINTS)


def active_window_is_minecraft():
    """Prevent installer keystrokes from going into an unrelated window."""
    try:
        title = get_active_window_title()
    except Exception as exc:
        print(f"[FOCUS] Could not determine the active window: {exc}")
        return False

    if not title:
        print("[FOCUS] No active window detected. Focus Minecraft and retry.")
        return False

    if not any(hint in title.casefold() for hint in TARGET_WINDOW_HINTS):
        print(f"[FOCUS] Refusing to type into: {title}")
        print("[FOCUS] Focus the Minecraft CraftOS terminal and retry.")
        return False

    return True


def command_delay(command):
    if command.startswith("wget "):
        return DOWNLOAD_DELAY
    if command.startswith("delete "):
        return DELETE_DELAY
    return START_DELAY


def run_commands(label, commands):
    if not run_lock.acquire(blocking=False):
        print(f"[{label}] Another install sequence is already running.")
        return

    stop_event.clear()

    try:
        if not active_window_is_minecraft():
            return

        print(f"[{label}] Sending commands to the focused Minecraft computer...")
        time.sleep(0.2)

        for index, command in enumerate(commands, start=1):
            if stop_event.is_set():
                print(f"[{label}] Cancelled before command {index}.")
                return

            if not active_window_is_minecraft():
                print(f"[{label}] Stopped because Minecraft lost focus.")
                return

            print(f"[{label}] {index}/{len(commands)}  {command}")
            pyautogui.write(command, interval=COMMAND_INTERVAL)
            pyautogui.press("enter")

            if stop_event.wait(command_delay(command)):
                print(f"[{label}] Cancelled after command {index}.")
                return

        print(f"[{label}] Commands sent. Check CraftOS for wget or Lua errors.")
    except pyautogui.FailSafeException:
        print(f"[{label}] Stopped by the PyAutoGUI fail-safe.")
    except Exception as exc:
        print(f"[{label}] Installer error: {type(exc).__name__}: {exc}")
    finally:
        run_lock.release()


def start_sequence(label, commands):
    threading.Thread(
        target=run_commands,
        args=(label, commands),
        name=f"PotatoCore-{label}",
        daemon=True
    ).start()


def cancel_sequence():
    if run_lock.locked():
        stop_event.set()
        print("[STOP] Cancellation requested. The current command will finish first.")
    else:
        print("[STOP] No installer sequence is running.")

MOD_CONTROL = 0x0002
MOD_SHIFT = 0x0004
MOD_NOREPEAT = 0x4000
WM_HOTKEY = 0x0312
PM_REMOVE = 0x0001


def poll_hotkeys():
    """Register only the installer shortcuts while Project Infinity is focused."""
    user32 = ctypes.windll.user32
    hotkeys = {
        1: (MOD_CONTROL, ord("P"), "CTRL+P", lambda: start_sequence("CTRL+P | MANA POOLS", MANA_POOL_COMMANDS)),
        2: (MOD_CONTROL, ord("M"), "CTRL+M", lambda: start_sequence("CTRL+M | PRODUCTION MONITOR", MONITOR_COMMANDS)),
        3: (MOD_CONTROL, ord("B"), "CTRL+B", lambda: start_sequence("CTRL+B | MACHINES", MACHINE_COMMANDS)),
        4: (MOD_CONTROL | MOD_SHIFT, ord("X"), "CTRL+SHIFT+X", cancel_sequence)
    }
    callbacks = {hotkey_id: details[3] for hotkey_id, details in hotkeys.items()}
    registered_ids = set()
    failed_ids = set()
    message = wintypes.MSG()

    print("[INPUT] Installer shortcuts are registered only while Project Infinity is focused.")

    try:
        while True:
            focused = is_minecraft_window_focused()

            if focused:
                for hotkey_id, (modifiers, virtual_key, label, _) in hotkeys.items():
                    if hotkey_id in registered_ids or hotkey_id in failed_ids:
                        continue

                    registered = user32.RegisterHotKey(
                        None,
                        hotkey_id,
                        modifiers | MOD_NOREPEAT,
                        virtual_key
                    )

                    if registered:
                        registered_ids.add(hotkey_id)
                    else:
                        failed_ids.add(hotkey_id)
                        print(f"[INPUT] Could not register {label}; it may already be in use.")
            else:
                for hotkey_id in tuple(registered_ids):
                    user32.UnregisterHotKey(None, hotkey_id)
                    registered_ids.remove(hotkey_id)

                failed_ids.clear()

            while user32.PeekMessageW(ctypes.byref(message), None, 0, 0, PM_REMOVE):
                if message.message != WM_HOTKEY:
                    continue

                callback = callbacks.get(int(message.wParam))
                if callback and is_minecraft_window_focused():
                    callback()

            time.sleep(0.05)
    finally:
        for hotkey_id in registered_ids:
            user32.UnregisterHotKey(None, hotkey_id)

print("======================================================")
print(" POTATOCORE // ADVANCED COMPUTER INSTALLER")
print("======================================================")
print("CTRL + P  |  MANA POOLS")
print("           Install / update Mana Pool transmitter")
print("           Use on each Mana Pool transmitter computer")
print("")
print("CTRL + M  |  MONITOR")
print("           Install / update expandable monitor receiver")
print("           Use on the dedicated 6x6 monitor computer")
print("")
print("CTRL + B  |  MACHINES")
print("           Install / update Block Reader transmitter")
print("           Use on each machine-side computer")
print("")
print("IMPORTANT: Focus the correct Minecraft computer terminal")
print("           before pressing its install hotkey.")
print("           If a Lua program is running, press CTRL+C first.")
print("           Keep Minecraft focused until commands finish.")
print("CTRL + SHIFT + X | CANCEL current sequence")
print("CTRL + C         | EXIT from this console")
print("======================================================")

try:
    poll_hotkeys()
except KeyboardInterrupt:
    print("\n[EXIT] PotatoCore installer stopped.")
