# PotatoCore Blood Magic Altar Monitor

Remote Blood Magic altar telemetry for CC:Tweaked and Advanced Peripherals.

## Hardware

### Altar transmitter computer
- Ender Modem attached to `bottom`.
- Advanced Peripherals Block Reader connected to the computer using a wired modem network.
- The Block Reader must face the Blood Altar.
- The Block Reader peripheral must be visible to the computer.

### Remote monitor computer
- Monitor or monitor network attached to `top`.
- Ender Modem attached to `bottom`.

The transmitter reads the Blood Altar's `bloodAltar` block-entity data. It does not modify the altar.

## Install transmitter

Run these on the computer connected to the Block Reader:

```text
delete blood_tx.lua
wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/blood-magic/blood_tx.lua blood_tx.lua
wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/blood-magic/startup_tx.lua startup.lua
startup.lua
```

The startup file automatically launches the transmitter after that computer reboots.

## Install receiver

Run these on the computer connected to the monitor and Ender Modem:

```text
delete blood_rx.lua
wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/blood-magic/blood_rx.lua blood_rx.lua
wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/blood-magic/startup_rx.lua startup.lua
blood_rx.lua
```

Run `startup_rx.lua` only if you want to install it under a different startup filename. To auto-start at boot, download it to `startup.lua` instead:

```text
wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/blood-magic/startup_rx.lua startup.lua
```

## Data displayed

- Stored Life Essence amount and altar capacity.
- Altar tier.
- Active / idle state.
- Input item and stack count.
- Current crafting progress against the recipe's LP requirement.
- Consumption and drain rates.
- Charging Rune buffer and buffer capacity.
- Transmitter online status.

The receiver uses a separate Rednet protocol: `potatocore_blood_altar_v1`. It can run independently of the Botania mana monitor.

## Diagnostic probe

To inspect the altar's raw Block Reader data:

```text
wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/blood-magic/blood_probe.lua blood_probe.lua
blood_probe.lua
```

The probe writes the full data to `blood_altar_data.txt`.
