# PotatoCore Monitor

Central receiver and Botania production dashboard, styled to match the Mana Core display.

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

## Dashboard

- Reactor-style title, system health, module count, and transmitter count.
- Larger adaptive text scale: prefers 0.8, then falls back to 0.7 / 0.5 when the connected monitor needs more room.
- Two-column, framed production cards using the Mana Core's cyan / blue / purple visual language.
- Card height adapts to the available monitor space, showing more telemetry on larger displays.
- Machine status, process / recipe, mana storage meter (when exposed), mana amount, required amount, and input/output details.
- Missing telemetry is shown as **Not exposed** or **No recipe data**, never as zero.
- Cached colored rendering avoids full-screen flashing.
- Raw receiver diagnostics are written to `botania_received_data.txt` every ten seconds.
- Diagnostic serialization handles shared or repeated table references safely.

The receiver listens on `potatocore_botania_machines_v1`. It does not replace the existing Mana Core receiver in `computercraft/mana-network/mana_rx.lua`.

## Network

The monitor computer uses an Ender Modem on the bottom. Each machine computer uses an Ender Modem on the top. Ender Modems exchange Rednet messages; they do not share Block Reader peripherals across computers.
