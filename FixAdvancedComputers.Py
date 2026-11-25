import ctypes
import threading
import time

try:
    import pyautogui
except ImportError as exc:
    missing = exc.name or "keyboard / pyautogui"
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

VK_CONTROL = 0x11
VK_SHIFT = 0x10


def is_key_down(virtual_key):
    """Read key state without suppressing or modifying the user's input."""
    return bool(ctypes.windll.user32.GetAsyncKeyState(virtual_key) & 0x8000)


def hotkey_is_pressed(virtual_key, require_shift=False):
    if not is_key_down(VK_CONTROL) or not is_key_down(virtual_key):
        return False

    return not require_shift or is_key_down(VK_SHIFT)


def poll_hotkeys():
    """Poll shortcuts only while Minecraft is focused. No keyboard hooks are installed."""
    hotkeys = {
        "CTRL+P": (ord("P"), False, lambda: start_sequence("CTRL+P | MANA POOLS", MANA_POOL_COMMANDS)),
        "CTRL+M": (ord("M"), False, lambda: start_sequence("CTRL+M | PRODUCTION MONITOR", MONITOR_COMMANDS)),
        "CTRL+B": (ord("B"), False, lambda: start_sequence("CTRL+B | MACHINES", MACHINE_COMMANDS)),
        "CTRL+SHIFT+X": (ord("X"), True, cancel_sequence)
    }
    previous_states = {name: False for name in hotkeys}

    print("[INPUT] Shortcuts are passive and only active while Minecraft is focused.")

    while True:
        focused = is_minecraft_window_focused()
        current_states = {}

        for name, (virtual_key, require_shift, callback) in hotkeys.items():
            pressed = focused and hotkey_is_pressed(virtual_key, require_shift)
            current_states[name] = pressed

            if pressed and not previous_states[name]:
                callback()

        previous_states = current_states
        time.sleep(0.025)

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
