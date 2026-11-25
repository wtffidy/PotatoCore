# PotatoCore Botania Production Line

Standalone CC:Tweaked dashboard for a separate 6x6 monitor. It does not replace or modify the existing Mana Core receiver or its 3x3 pool array.

## Hardware

- One Advanced Computer connected to the dedicated 6x6 monitor.
- Seven Advanced Peripherals Block Readers.
- Place one reader directly above each machine, facing down toward the machine.
- Connect the monitor computer and all seven readers to the same wired modem network.

Machines monitored:

1. Industrial Agglomeration Factory
2. Alfheim Market
3. Mechanical Mana Pool
4. Mechanical Runic Altar
5. Mechanical Apothecary
6. Mechanical Daisy #1
7. Mechanical Daisy #2

The dashboard discovers Block Reader peripherals and identifies machines from their registry names. It reads block names, block entity data, and block states.

## Install

Run these commands on the Advanced Computer attached to the new Botania 6x6 monitor:

delete botania.lua
wget https://raw.githubusercontent.com/wtffidy/PotatoCore/main/computercraft/botania-production/botania.lua botania.lua
botania.lua

The FixAdvancedComputers.Py helper keeps the existing Mana TX hotkey (Ctrl+T) and adds Ctrl+B for this Botania dashboard installer.

## Diagnostics

The dashboard writes botania_data.txt with the raw block data and block states from each detected machine. The log refreshes every 10 seconds.

Some machines may not expose their active recipe or exact mana requirement through Block Reader data. Those fields are shown as Not exposed rather than guessed. Use the diagnostic file to map the actual fields exposed by this Project Infinity build before adding machine-specific parsing.

## Notes

- The Botania dashboard is installed on the dedicated monitor computer only. Do not install it on each machine.
- The seven Block Readers must be visible to that computer over one wired modem network.
- The existing mana-network receiver and transmitter files are unchanged.
