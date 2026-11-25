# PotatoCore Monitor

Expandable receiver and dashboard for the dedicated Botania production monitor.

## Hardware

- Ender Modem on the **bottom** side.
- Monitor attached locally or exposed through the computer's wired monitor network.
- One or more machine-side computers running the PotatoCore machine transmitter.

## Install

    delete monitor.lua
    wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/monitor/monitor.lua monitor.lua
    delete startup.lua
    wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/monitor/startup.lua startup.lua
    monitor.lua

Or focus the dedicated monitor computer's CraftOS terminal and press **Ctrl+M** in FixAdvancedComputers.Py.

## Dashboard

- Uses a two-column layout so machine names and telemetry are easier to read on the 6x6 display.
- Shows all seven configured machines in compact six-line cards.
- Separates machine link status from recipe, mana, requirement, and item telemetry.
- Uses **OFFLINE** for missing readers and **NO DATA** when a reader is present but does not expose a data table.
- Displays unavailable values as **Not exposed** / **No recipe data**; missing telemetry is never represented as zero.
- Uses cached colored rendering to prevent flashing.
- Writes raw receiver data to `botania_received_data.txt` every ten seconds for troubleshooting.

The receiver listens on `potatocore_botania_machines_v1`. It does not replace the existing 3x3 Mana Core receiver in `computercraft/mana-network/mana_rx.lua`.

## Network

The monitor computer uses an Ender Modem on the bottom. Each machine computer uses an Ender Modem on the top. Ender Modems exchange Rednet messages; they do not share Block Reader peripherals across computers.
