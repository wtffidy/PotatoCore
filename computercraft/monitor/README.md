# PotatoCore Monitor

This is the expandable receiver and dashboard program for the dedicated Botania 6x6 monitor.

## Hardware

- Ender Modem on the **bottom** side.
- Monitor attached locally or exposed through the computer's local wired monitor network.
- Receives machine telemetry from all machine-side computers.

## Install

    delete monitor.lua
    wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/monitor/monitor.lua monitor.lua
    delete startup.lua
    wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/monitor/startup.lua startup.lua
    monitor.lua

Or focus the dedicated monitor computer's CraftOS terminal and press **Ctrl+M** in FixAdvancedComputers.Py.

## Expandable screen architecture

monitor.lua is the central receiver and display entry point. Future PotatoCore screens should be added here as additional panels / views while keeping device-side transmitters separate.

Current view:
- Seven Botania machine cards.
- Machine online / offline status.
- Crafting / recipe fields where exposed.
- Mana and mana-required fields where exposed.
- Inputs / outputs where exposed.
- Cached colored monitor rendering to prevent flashing.
- Raw receiver data saved to botania_received_data.txt every ten seconds.

The program listens on protocol potatocore_botania_machines_v1. It does not replace the existing 3x3 Mana Core receiver in computercraft/mana-network/mana_rx.lua.

## Network distinction

The monitor computer uses an Ender Modem on the bottom. Each machine computer uses an Ender Modem on the top. Ender Modems exchange Rednet messages; they do not share Block Reader peripherals across computers.
