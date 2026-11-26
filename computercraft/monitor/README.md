# PotatoCore Monitor

Botania production dashboard for the dedicated monitor computer.

## Hardware

- Ender Modem on the **bottom** side.
- Monitor attached locally or exposed through the computer's wired monitor network.
- Machine-side computers running the PotatoCore Block Reader transmitter.

## Install

```text
delete monitor.lua
wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/monitor/monitor.lua monitor.lua
delete startup.lua
wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/monitor/startup.lua startup.lua
monitor.lua
```

Or focus the dedicated monitor computer's CraftOS terminal and press **Ctrl+M** in FixAdvancedComputers.Py.

## Display

Each of the seven machine cards shows:

1. The item currently being crafted, when exposed by the Block Reader.
2. Stored mana / maximum mana.
3. Mana required for the current craft.
4. A live green capacity bar showing stored mana as a percentage of the reported maximum.

The bar is deliberately a **mana capacity** indicator, not a crafting-progress indicator. Missing capacity data produces a neutral grey bar rather than inventing a percentage.

- Two-column layout with a purple frame, cyan machine headings, yellow item names, and green mana indicators.
- Full comma-separated mana values on wide displays and compact values on narrower displays.
- Missing values display as `N/A`; an empty or unknown output displays as `NO ITEM`.
- Cached colored rendering avoids full-screen flashing.
- Machine transmitters broadcast fresh Block Reader data on `potatocore_botania_machines_v1`.
- Raw receiver diagnostics are written to `botania_received_data.txt`, separately from the display.

The receiver does not replace the Mana Core receiver in `computercraft/mana-network/mana_rx.lua`.
