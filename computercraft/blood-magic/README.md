# PotatoCore Blood Magic Altar Monitor

Remote Blood Magic altar telemetry for CC:Tweaked and Advanced Peripherals.

## Hardware layout

### Altar transmitter computer
- Ender Modem attached to the computer's **bottom**.
- Block Reader positioned above the Blood Altar and connected to the altar computer through the wired peripheral network.
- The Block Reader must face the Blood Altar.
- The transmitter discovers the Block Reader by peripheral type, so it does not depend on a fixed side.

### Remote monitor computer
- 5-wide x 4-tall monitor connected to the computer's **back**.
- Ender Modem attached to the computer's **left**.

The transmitter reads the Blood Altar's `bloodAltar` block-entity data. It does not modify the altar.

## Install transmitter

Run these on the altar computer:

```text
delete blood_tx.lua
wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/blood-magic/blood_tx.lua blood_tx.lua
wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/blood-magic/startup_tx.lua startup.lua
startup.lua
```

## Install receiver

Run these on the monitor computer:

```text
delete blood_rx.lua
wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/blood-magic/blood_rx.lua blood_rx.lua
wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/blood-magic/startup_rx.lua startup.lua
startup.lua
```

The receiver requests text scale 1.5 when the attached monitor exposes the `setTextScale` method. If it does not, it keeps the monitor's current scale and continues instead of crashing.

The startup file automatically launches the corresponding script after reboot. These commands replace the computer's existing `startup.lua`.

## Data displayed

- Stored Life Essence amount and altar capacity.
- Altar tier and active / idle state.
- Input item and stack count.
- Current recipe progress and progress decay warning.
- Consumption and drain rates.
- Charging Rune buffer and buffer capacity.
- Transmitter online status.

The receiver uses the Rednet protocol `potatocore_blood_altar_v1` and runs independently of the Botania mana monitor.

## Diagnostic probe

To inspect the raw Block Reader data:

```text
wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/blood-magic/blood_probe.lua blood_probe.lua
blood_probe.lua
```

The probe writes the full data to `blood_altar_data.txt`.
