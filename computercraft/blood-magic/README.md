# PotatoCore Blood Magic Altar Monitor

Live Blood Magic altar telemetry for Project Infinity 0.1, using Advanced Peripherals Block Reader and CC:Tweaked Ender Modems.

## Hardware

### Altar computer
- Computer sits directly **under the Blood Altar**.
- Ender Modem is attached to the computer's **BOTTOM**.
- Block Reader must face the Blood Altar and be connected to the computer through a wired modem network.
- The transmitter automatically discovers the Block Reader, including the `blockReader` and `block_reader` peripheral names.
- The Ender Modem defaults to BOTTOM and is auto-discovered if moved.

The Block Reader cannot be attached to the same top face occupied by the altar. It must be connected through the wired peripheral network, with its reading face pointed at the altar.

### Remote monitor computer
- Monitor is expected on the **BACK**, but the script auto-discovers it if moved.
- Ender Modem is expected on the **LEFT**, but the script auto-discovers it if moved.
- Monitor text scale is set to 1.5 only when the monitor exposes `setTextScale`. Otherwise, its existing scale is preserved. This avoids the previous nil-method crash.

## Install transmitter

Run on the altar computer:

```text
delete blood_tx.lua
wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/blood-magic/blood_tx.lua blood_tx.lua
wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/blood-magic/startup_tx.lua startup.lua
startup.lua
```

## Install monitor

Run on the monitor computer:

```text
delete blood_rx.lua
wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/blood-magic/blood_rx.lua blood_rx.lua
wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/blood-magic/startup_rx.lua startup.lua
startup.lua
```

The startup launchers automatically run the correct program after reboot.

## Dashboard

- Stored Life Essence and altar capacity, with a red capacity bar.
- Altar tier and active / crafting / standby state.
- Current input item and stack count.
- Recipe LP progress, with a cyan progress bar.
- Progress-decay warning when progress drops during the same active recipe.
- LP consumption and drain rates.
- Charging Rune buffer and maximum buffer.
- Reader retry / connection status.

The dashboard uses cached blit rendering to avoid flashing. It does not clear and repaint the whole monitor every update.

## Network

The transmitter broadcasts on `potatocore_blood_altar_v1` every 0.5 seconds. The receiver times out stale readings after 6 seconds. The transmitter holds the last valid sample for up to 15 seconds during temporary Block Reader dropouts.

The Block Reader reads the altar's block-entity data only; it does not modify the altar.

## Diagnostic probe

If the transmitter reports missing altar data:

```text
wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/blood-magic/blood_probe.lua blood_probe.lua
blood_probe.lua
```

The probe writes the full Block Reader response to `blood_altar_data.txt`.
