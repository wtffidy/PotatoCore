import time
import threading
import keyboard
import pyautogui

commands = [
    "delete mana_tx.lua",
    "wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/mana-network/mana_tx.lua mana_tx.lua",
    "mana_tx.lua"
]

busy = False

def run_commands():
    global busy
    if busy:
        return

    busy = True
    try:
        time.sleep(0.2)

        for index, command in enumerate(commands):
            pyautogui.write(command, interval=0)
            pyautogui.press("enter")

            if index == 1:
                time.sleep(2)  # Download
            elif index == 0:
                time.sleep(0.2)
    finally:
        busy = False

keyboard.add_hotkey(
    "ctrl+t",
    lambda: threading.Thread(target=run_commands, daemon=True).start(),
    suppress=True
)

print("Mana Autotyper running!")
print("CTRL + T = Delete > Download > Run")
print("CTRL + C = Exit")

keyboard.wait()