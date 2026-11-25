import threading
import time

import keyboard
import pyautogui


# Ctrl+P: install the Mana Pool transmitter on a Mana Pool computer.
MANA_POOL_COMMANDS = [
    "delete mana_tx.lua",
    "wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/mana-network/mana_tx.lua mana_tx.lua",
    "delete startup.lua",
    "wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/mana-network/startup_tx.lua startup.lua",
    "mana_tx.lua",
]

# Ctrl+M: install the expandable receiver/dashboard on the dedicated monitor computer.
MONITOR_COMMANDS = [
    "delete monitor.lua",
    "wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/monitor/monitor.lua monitor.lua",
    "delete startup.lua",
    "wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/monitor/startup.lua startup.lua",
    "monitor.lua",
]

# Ctrl+B: install the Block Reader transmitter on each machine-side computer.
MACHINE_COMMANDS = [
    "delete machines.lua",
    "wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/machines/machines.lua machines.lua",
    "delete startup.lua",
    "wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/machines/startup.lua startup.lua",
    "machines.lua",
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

        print(f"[{label}] Install commands sent.")
    finally:
        run_lock.release()


def start_sequence(label, commands):
    threading.Thread(
        target=run_commands,
        args=(label, commands),
        daemon=True
    ).start()


keyboard.add_hotkey(
    "ctrl+p",
    lambda: start_sequence("CTRL+P | MANA POOLS", MANA_POOL_COMMANDS),
    suppress=True
)

keyboard.add_hotkey(
    "ctrl+m",
    lambda: start_sequence("CTRL+M | PRODUCTION MONITOR", MONITOR_COMMANDS),
    suppress=True
)

keyboard.add_hotkey(
    "ctrl+b",
    lambda: start_sequence("CTRL+B | MACHINES", MACHINE_COMMANDS),
    suppress=True
)

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
print("CTRL + C  |  EXIT")
print("======================================================")

keyboard.wait()
