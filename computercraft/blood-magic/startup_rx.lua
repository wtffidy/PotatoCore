-- PotatoCore Blood Magic altar monitor auto-start.
if not fs.exists("/blood_rx.lua") then
    printError("blood_rx.lua is missing. Download the Blood Altar receiver first.")
    return
end

shell.run("/blood_rx.lua")
