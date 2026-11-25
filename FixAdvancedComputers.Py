import threading
import time

import keyboard
import pyautogui


MANA_COMMANDS = [
    "delete mana_tx.lua",
    "wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/mana-network/mana_tx.lua mana_tx.lua",
    "mana_tx.lua",
]

BOTANIA_COMMANDS = [
    "delete botania.lua",
    "wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/botania-production/botania.lua botania.lua",
    "botania.lua",
]

run_lock = threading.Lock()


def run_commands(label, commands):
    if not run_lock.acquire(blocking=False):
        return

    try:
        time.sleep(0.2)

        for index, command in enumerate(commands):
            pyautogui.write(command, interval=0)
            pyautogui.press("enter")

            if index == 1:
                time.sleep(2.5)  # Allow wget to finish.
            elif index == 0:
                time.sleep(0.2)

        print(f"{label} commands sent.")
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
    lambda: start_sequence("Mana TX", MANA_COMMANDS),
    suppress=True
)

keyboard.add_hotkey(
    "ctrl+b",
    lambda: start_sequence("Botania Production Line", BOTANIA_COMMANDS),
    suppress=True
)

print("PotatoCore Advanced Computer Helper running!")
print("CTRL + T = Delete > Download > Run mana_tx.lua")
print("CTRL + B = Delete > Download > Run botania.lua")
print("CTRL + C = Exit")

keyboard.wait()
