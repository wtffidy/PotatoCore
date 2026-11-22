-- PotatoCore Basic Materials Exchange mana transmitter auto-start.
if not fs.exists("/mana_tx_exchange.lua") then
    printError("mana_tx_exchange.lua is missing. Download the Materials Exchange transmitter first.")
    return
end

shell.run("/mana_tx_exchange.lua")
