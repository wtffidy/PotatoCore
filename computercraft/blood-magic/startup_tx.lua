-- PotatoCore Blood Magic altar transmitter auto-start.
if not fs.exists("/blood_tx.lua") then
    printError("blood_tx.lua is missing. Download the Blood Altar transmitter first.")
    return
end

shell.run("/blood_tx.lua")
