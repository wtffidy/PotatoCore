# PotatoCore Fluix Mana Monitor

Standalone live throughput display for the Fluix Mana Pool in Project Infinity 0.1.

## Hardware

- CC:Tweaked computer directly connected to the Botania Mana Pool peripheral.
- Monitor directly connected to the computer.
- Extend the monitor to the right as a normal CC:Tweaked monitor multiblock. The joined monitor is detected as one display.
- No Ender Modem, Rednet, or remote transmitter is used.

The computer must be able to see both the `manaPool` and `monitor` peripherals directly. If the pool is not exposed as a peripheral, check the Advanced Peripherals integration and the physical connection.

## Install

Run these commands on the new computer:

```text
wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/fluix-mana/fluix_mana.lua fluix_mana.lua
wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/fluix-mana/startup.lua startup.lua
startup
```

The startup launcher runs the monitor automatically after a reboot.

## Display

- Net mana generation or drain per second.
- Estimated net throughput per minute and hour.
- Four-sample smoothing to keep the live number readable.
- Automatically detects the directly attached mana pool and monitor.

The displayed rate is the pool's net mana change. Mana being consumed at the same time is subtracted from the generation rate.
