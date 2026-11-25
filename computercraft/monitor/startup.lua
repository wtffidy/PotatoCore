-- PotatoCore Production Monitor: auto-start
-- Installed as /startup.lua on the dedicated monitor computer.

if not fs.exists("/monitor.lua") then
    printError("monitor.lua is missing. Run the PotatoCore monitor installer first.")
    return
end

shell.run("/monitor.lua")
