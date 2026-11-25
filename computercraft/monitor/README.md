# PotatoCore Monitor

Minimal Botania production display for the dedicated monitor computer.

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

## Display

Each of the seven machine cards shows only:

1. The item currently being crafted, when exposed by the Block Reader.
2. Stored mana / maximum mana.
3. Mana required for the current craft.

No computer IDs, network counters, peripheral status, uptime, recipe debug paths, or inventory diagnostics appear on the monitor.

- Mana values use full comma-separated numbers when the display is wide enough and compact values on narrower displays.
- Missing values display as `N/A`; no active/identified craft displays as `—`.
- The display uses a two-column, framed layout with the Botania/Mana Core color palette.
- Cached colored rendering avoids full-screen flashing.
- Raw receiver diagnostics are still written to `botania_received_data.txt` every ten seconds, separately from the display.
- Diagnostic serialization handles shared or repeated table references safely.

The receiver listens on `potatocore_botania_machines_v1`. It does not replace the Mana Core receiver in `computercraft/mana-network/mana_rx.lua`.

## Network

The monitor computer uses an Ender Modem on the bottom. Each machine computer uses an Ender Modem on the top. Ender Modems exchange Rednet messages; they do not share Block Reader peripherals across computers.
