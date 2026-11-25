# PotatoCore Machines

This is the machine-side Block Reader transmitter for the Botania production line.

## Hardware per machine computer

- Ender Modem on the **top** side.
- One Block Reader visible to the computer.
- The Block Reader is placed above the target machine and faces **down**.
- The machine computer does not need a monitor.

Install this same script on each of the seven machine-side computers.

## Install

    delete machines.lua
    wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/machines/machines.lua machines.lua
    delete startup.lua
    wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/machines/startup.lua startup.lua
    machines.lua

Or focus the machine computer's CraftOS terminal and press **Ctrl+B** in FixAdvancedComputers.Py.

## Behavior

- Opens the Ender Modem on the top side.
- Finds local peripherals of type blockReader / block_reader.
- Reads block name, block data, and block states when available.
- Broadcasts the readings every two seconds on protocol potatocore_botania_machines_v1.
- Does not search for or require a monitor.
- startup.lua launches machines.lua after reboot.

The dedicated monitor computer receives these packets and builds the seven machine cards.
