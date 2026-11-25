-- PotatoCore Fluix Mana Monitor auto-start
if not fs.exists("/fluix_mana.lua") then
    printError("fluix_mana.lua is missing. Download the monitor first.")
    return
end

shell.run("/fluix_mana.lua")
