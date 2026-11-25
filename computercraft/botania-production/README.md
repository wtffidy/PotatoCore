# PotatoCore Botania Production Line

Standalone CC:Tweaked dashboard for a separate 6x6 monitor. It does not replace or modify the existing Mana Core receiver or its 3x3 pool array.

## Hardware

### Botania monitor computer

- Advanced Computer connected to the dedicated 6x6 monitor.
- Wired Modem on the **top** side.
- Set the monitor to the computer's local peripheral network or connect it to the same wired modem network.

### Seven machine readers

- One Advanced Peripherals Block Reader per machine.
- Place each Block Reader directly above its machine, facing down.
- Connect all seven readers to the monitor computer through one continuous wired modem network.

Machines monitored:

1. Industrial Agglomeration Factory
2. Alfheim Market
3. Mechanical Mana Pool
4. Mechanical Runic Altar
5. Mechanical Apothecary
6. Mechanical Daisy #1
7. Mechanical Daisy #2

The dashboard discovers Block Reader peripherals and identifies machines from their registry names. It reads block names, block entity data, and block states.

**Important:** Use wired modems and wired modem cable for the shared peripheral network. An Ender Modem can carry Rednet messages, but it does not expose remote peripherals to peripheral.getNames().

## Install

Run these commands on the Advanced Computer attached to the new Botania 6x6 monitor:

    delete botania.lua
    wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/botania-production/botania.lua botania.lua
    botania.lua

The FixAdvancedComputers.Py helper keeps the existing Mana TX hotkey (Ctrl+T) and adds Ctrl+B for this Botania dashboard installer.

## Dashboard

- Coloured Potatocore-style header and status indicators.
- Seven individual machine cards, including separate Daisy panels.
- Recipe / crafting fields, where exposed by block data.
- Mana storage and maximum, where exposed by block data.
- Mana requirement fields, where exposed by block data.
- Mana bars when both current and maximum values are available.
- Cached coloured monitor rows to prevent flashing.

Unknown recipe and mana values are displayed as unavailable rather than guessed.

## Diagnostics

The dashboard writes botania_data.txt with the raw block data and block states from every detected reader. The log refreshes every 10 seconds.

Send that file back for machine-specific field mapping. Some machines may not expose their active recipe or exact mana requirement through Block Reader data, so the diagnostic dump is needed before those fields can be decoded accurately.

## Notes

- Install botania.lua on the dedicated monitor computer only.
- The seven Block Readers do not need their own dashboard computers or copies of this program.
- The seven readers and monitor computer must be on the same wired modem peripheral network.
- The existing computercraft/mana-network/mana_rx.lua and mana_tx.lua files are unchanged.
