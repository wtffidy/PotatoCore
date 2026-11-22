-- PotatoCore Mana Network: transmitter auto-start
-- Place this file in the computer root as startup.lua.
if not fs.exists("/mana_tx.lua") then
    printError("mana_tx.lua is missing. Download the transmitter first.")
    return
end

shell.run("/mana_tx.lua")
