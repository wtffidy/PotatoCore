-- PotatoCore Botania Production Line: monitor auto-start
-- Installed as /startup.lua on the dedicated Botania monitor computer.

if not fs.exists("/botania.lua") then
    printError("botania.lua is missing. Run the PotatoCore installer first.")
    return
end

shell.run("/botania.lua")
