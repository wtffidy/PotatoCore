-- PotatoCore Mana Network: receiver auto-start
-- Place this file in the computer root as startup.lua.
if not fs.exists("/mana_rx.lua") then
    printError("mana_rx.lua is missing. Download the receiver first.")
    return
end

shell.run("/mana_rx.lua")
