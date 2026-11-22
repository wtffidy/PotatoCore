# PotatoCore ComputerCraft Mana Network

Remote multi-pool Botania mana monitor for CC:Tweaked, Advanced Peripherals, and Ender Modems.

## Files

- `mana_tx.lua`: run on each computer that can see one or more Botania Mana Pool peripherals.
- `mana_rx.lua`: run on the remote computer connected to the monitor wall.

## Confirmed Project Infinity hardware layout

### Mana transmitter computer
- Mana Pool: `left`
- Ender Modem: `front`

### Remote monitor computer
- Monitor: `top`
- Ender Modem: `bottom`

If your hardware differs, edit the CONFIG block near the top of the relevant Lua file.

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
