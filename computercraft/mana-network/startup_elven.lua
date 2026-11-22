-- PotatoCore Elven Portal mana transmitter auto-start.
if not fs.exists("/mana_tx_elven.lua") then
    printError("mana_tx_elven.lua is missing. Download the Elven Portal transmitter first.")
    return
end

shell.run("/mana_tx_elven.lua")
