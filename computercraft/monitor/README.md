# PotatoCore Monitor

Central receiver and dashboard for the Botania production network.

## Hardware

- Ender Modem on the **bottom** side.
- Monitor attached locally or exposed through the computer's wired monitor network.
- Machine-side computers running the PotatoCore Block Reader transmitter.

## Install

    delete monitor.lua
    wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/monitor/monitor.lua monitor.lua
    delete startup.lua
    wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/monitor/startup.lua startup.lua
    monitor.lua

Or focus the dedicated monitor computer's CraftOS terminal and press **Ctrl+M** in FixAdvancedComputers.Py.

## Dashboard design

The Botania display follows the same visual system as the Mana Core dashboard:

- Larger adaptive text scale, preferring 0.8 and falling back to 0.7 / 0.5 when the monitor needs more room.
- Framed machine cards with cyan / purple borders and color-coded status.
- A clear system header, network status, machine count, and transmitter count.
- Two-column production module layout for all seven machines.
- Machine cards show status, process / recipe, mana, and required items or input/output telemetry.
- Compact card layout is used on shorter monitors.
- Cached colored rendering prevents full-screen flashing.
- Raw receiver diagnostics are written to `botania_received_data.txt` every ten seconds.
- Diagnostic serialization handles shared or repeated table references without crashing.

Missing telemetry is shown as **Not exposed** or **No recipe data**, never as zero.

The receiver listens on `potatocore_botania_machines_v1`. It does not replace the existing Mana Core receiver in `computercraft/mana-network/mana_rx.lua`.

## Network

The monitor computer uses an Ender Modem on the bottom. Each machine computer uses an Ender Modem on the top. Ender Modems exchange Rednet messages; they do not share Block Reader peripherals across computers.
