# PotatoCore ComputerCraft Mana Network

Remote multi-pool Botania mana monitor for CC:Tweaked, Advanced Peripherals, and Ender Modems.

## Files

- `mana_tx.lua`: run on each computer that can see one or more Botania Mana Pool peripherals.
- `mana_rx.lua`: run on the remote computer connected to the monitor wall.

## Confirmed Project Infinity hardware layout

### Mana transmitter computer
- Mana Pool: `top`
- Ender Modem: `bottom`

### Remote monitor computer
- Monitor: `top`
- Ender Modem: `bottom`

The transmitter scans all locally accessible peripherals, so it does not need a configured pool side. The Ender Modem side is configured as `bottom` for the under-pool computer layout. If your hardware differs, edit the CONFIG block near the top of the relevant Lua file.

## Install from the CraftOS shell

HTTP must be enabled for CC:Tweaked. Run these commands on the relevant computers:

### Mana transmitter computer

```text
wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/mana-network/mana_tx.lua mana_tx.lua
```

### Remote monitor computer

```text
wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/mana-network/mana_rx.lua mana_rx.lua
```

## Start

Start the receiver first, on the remote monitor computer:

```text
mana_rx
```

Then start the transmitter on the computer beside the Mana Pool:

```text
mana_tx
```

## Separate auxiliary pool groups

The receiver keeps the main 3x3 array separate from two optional auxiliary groups:

- `array`: the default group for the nine main pools.
- `elven_portal`: a dedicated Elven Portal mana pool (or group of pools).
- `materials_exchange`: a dedicated Basic Materials Exchange mana pool (or group of pools).

To add an auxiliary pool, place a transmitter computer where it can see that pool, download the updated `mana_tx.lua`, and edit its CONFIG group.

For the Elven Portal transmitter, set:

```lua
group = "elven_portal"
```

For the Basic Materials Exchange transmitter, set:

```lua
group = "materials_exchange"
```

Leave the nine existing transmitters set to `group = "array"`. The receiver treats older packets without a group field as `array`, so the existing nine computers do not need to be changed just to keep working.

For automatic startup on an auxiliary transmitter, install `startup_tx.lua` as its `startup.lua` after configuring `mana_tx.lua`.

## Multiple pools and transmitters

Each transmitter discovers all `manaPool` peripherals visible to its own peripheral network. This includes directly attached peripherals and pools exposed through a connected wired modem network.

To monitor pools in another area, place another computer where those pools are accessible, attach an Ender Modem, download the same `mana_tx.lua`, adjust `modemSide` if needed, and run it.

All transmitters broadcast using the shared Rednet protocol `potatocore_mana_multi_v1`. The receiver combines readings from distinct ComputerCraft IDs and removes a transmitter after six seconds without a packet.

Ender Modems carry the computer-to-computer messages. They do not directly expose a remote Mana Pool peripheral to another computer.

## Troubleshooting

- `Ender Modem not found`: correct the `modemSide` in the CONFIG block.
- `WAITING FOR MANA TRANSMITTERS`: make sure `mana_tx` is running, both Ender Modems are opened, and the two computers can exchange Rednet messages.
- No pools reported: check that Advanced Peripherals exposes the Botania pool as the `manaPool` peripheral type and that it is visible to the transmitter computer.
- `wget` unavailable or blocked: enable the CC:Tweaked HTTP API in the world/server config and allow access to `raw.githubusercontent.com`.

## Updating

Re-run the matching `wget` command with the same destination filename. If your CC:Tweaked version does not overwrite existing files, delete the old file first:

```text
delete mana_tx.lua
```

or

```text
delete mana_rx.lua
```

Then run the download command again.

### Replacing an existing copy

CC:Tweaked's `wget` will not overwrite an existing filename. Since you already have test versions, delete each old file before downloading its replacement:

**Mana Pool computer:**
```text
delete mana_tx.lua
wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/mana-network/mana_tx.lua mana_tx.lua
```

**Remote monitor computer:**
```text
delete mana_rx.lua
wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/mana-network/mana_rx.lua mana_rx.lua
```

