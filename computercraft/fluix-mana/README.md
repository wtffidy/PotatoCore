# PotatoCore Fluix Mana Dashboard

Live telemetry display for a Botania Fluix Mana Pool in Project Infinity 0.1.

## Hardware

- CC:Tweaked computer directly connected to the Mana Pool peripheral.
- Monitor directly connected to the computer.
- Extend the monitor to the right as a normal CC:Tweaked monitor multiblock. The joined display is detected as one monitor.
- No Ender Modem, Rednet, or remote transmitter is required.

The computer must be able to see both the `manaPool` and `monitor` peripherals directly.

## Install

Run these commands on the dashboard computer:

```text
wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/fluix-mana/fluix_mana.lua fluix_mana.lua
wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/fluix-mana/startup.lua startup.lua
startup
```

## Dashboard telemetry

- Current mana and maximum pool capacity.
- Fill percentage and visual capacity bar.
- Net mana/sec, mana/minute, and mana/hour.
- Estimated time until full while mana is increasing.
- Estimated time until empty while mana is draining.
- Pool state: receiving, draining, standby, empty, or full.
- Pool mode: whether the pool can charge an item.
- Whether an item is sitting on the pool, plus its name when exposed by the peripheral.
- Rolling average smoothing to keep the rate readable.
- Peripheral calls are feature-detected, so optional stats are omitted when the installed Advanced Peripherals version does not expose them.

The rate is **net mana change**, not gross generation. If the pool consumes mana while receiving it, that consumption is subtracted from the measured rate. Time estimates are projections based on the smoothed recent rate, not guarantees.
