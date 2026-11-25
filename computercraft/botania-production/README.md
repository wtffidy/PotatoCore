# Botania Production Line (superseded)

The original botania.lua combined Block Reader scanning and monitor rendering on one computer. That architecture was incorrect for the Ender Modem layout and has been replaced by three separate roles:

1. Mana Pools: computercraft/mana-network/mana_tx.lua (Ctrl+P)
2. Monitor: computercraft/monitor/monitor.lua (Ctrl+M)
3. Machines: computercraft/machines/machines.lua (Ctrl+B)

Use the new role-specific directories and READMEs. Do not install the legacy botania.lua or startup.lua from this directory.
