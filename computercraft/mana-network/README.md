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

- `array`: the nine main pools. Existing transmitters remain in this group.
- `elven_portal`: the Elven Portal pool.
- `materials_exchange`: the Basic Materials Exchange pool.

Use the dedicated files below. No manual editing of Lua configuration is needed.

### Elven Portal computer

The computer must have its Ender Modem on `bottom` and be able to see the Elven Portal Mana Pool.

```text
delete mana_tx_elven.lua
wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/mana-network/mana_tx_elven.lua mana_tx_elven.lua
wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/mana-network/startup_elven.lua startup.lua
startup.lua
```

### Basic Materials Exchange computer

The computer must have its Ender Modem on `bottom` and be able to see the Basic Materials Exchange Mana Pool.

```text
delete mana_tx_exchange.lua
wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/mana-network/mana_tx_exchange.lua mana_tx_exchange.lua
wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/mana-network/startup_exchange.lua startup.lua
startup.lua
```

Each auxiliary computer installs its matching launcher as `startup.lua`, so it will automatically launch the correct transmitter after a computer or world restart. Do not install both auxiliary launchers on the same computer.

The receiver displays these groups in separate panels beneath the main 3x3 array. Additional pools can be placed in either auxiliary group by connecting them to that group's transmitter computer through its accessible peripheral network.


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

