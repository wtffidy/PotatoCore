-- PotatoCore Machine Transmitter: auto-start
-- Installed as /startup.lua on each machine-side computer.

if not fs.exists("/machines.lua") then
    printError("machines.lua is missing. Run the PotatoCore machine installer first.")
    return
end

shell.run("/machines.lua")
