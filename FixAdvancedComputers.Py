import threading
import time

import keyboard
import pyautogui


# Ctrl+T: install/run mana transmitter on the Mana Pool computer.
MANA_TX_COMMANDS = [
    "delete mana_tx.lua",
    "wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/mana-network/mana_tx.lua mana_tx.lua",
    "mana_tx.lua",
]

# Ctrl+B: install/run the Botania dashboard on the dedicated 6x6 monitor computer.
# Its Lua program auto-detects the wired modem side (monitor PC bottom, machine PCs top).
BOTANIA_MONITOR_COMMANDS = [
    "delete botania.lua",
    "wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/botania-production/botania.lua botania.lua",
    "delete startup.lua",
    "wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/botania-production/startup.lua startup.lua",
    "botania.lua",
]

run_lock = threading.Lock()


def run_commands(label, commands):
    if not run_lock.acquire(blocking=False):
        print(f"[{label}] Another install sequence is already running.")
        return

    try:
        print(f"[{label}] Sending commands to the focused Minecraft computer...")
        time.sleep(0.2)

        for command in commands:
            pyautogui.write(command, interval=0)
            pyautogui.press("enter")

            if command.startswith("wget "):
                time.sleep(2.5)  # Allow the download to finish.
            elif command.startswith("delete "):
                time.sleep(0.2)

        print(f"[{label}] Commands sent.")
    finally:
        run_lock.release()


def start_sequence(label, commands):
    threading.Thread(
        target=run_commands,
        args=(label, commands),
        daemon=True
    ).start()


keyboard.add_hotkey(
    "ctrl+t",
    lambda: start_sequence("CTRL+T | MANA TX", MANA_TX_COMMANDS),
    suppress=True
)

keyboard.add_hotkey(
    "ctrl+b",
    lambda: start_sequence("CTRL+B | BOTANIA 6x6 MONITOR", BOTANIA_MONITOR_COMMANDS),
    suppress=True
)

print("==================================================")
print(" POTATOCORE // ADVANCED COMPUTER INSTALLER")
print("==================================================")
print("CTRL + T  |  MANA TX")
print("           Install / update the Mana Pool transmitter")
print("")
print("CTRL + B  |  BOTANIA PRODUCTION MONITOR")
print("           Install / update the dedicated 6x6 dashboard")
print("           Run with the Minecraft terminal focused")
print("")
print("NOTE: Ctrl+B is for the Botania monitor computer.")
print("      Its modem is auto-detected; monitor PC bottom,")
print("      machine-side PCs top.")
print("")
print("CTRL + C  |  EXIT")
print("==================================================")

keyboard.wait()
