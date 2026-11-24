-- ============================================================
-- POTATOCORE // BLOOD ALTAR DATA PROBE
-- Project Infinity 0.1 | Blood Magic 3.3.8-50
--
-- Requires an Advanced Peripherals Block Reader connected to
-- this computer through a wired modem network.
--
-- The Block Reader must face the Blood Altar.
-- This script is diagnostic only. It does not modify the altar.
-- ============================================================

local reader = peripheral.find("blockReader")
if not reader then
    error("No Block Reader found. Connect one through a wired modem.")
end

local function sortedKeys(values)
    local keys = {}

    for key in pairs(values) do
        keys[#keys + 1] = key
    end

    table.sort(keys, function(a, b)
        return tostring(a) < tostring(b)
    end)

    return keys
end

local function printTable(values, title)
    if type(values) ~= "table" then
        print(title .. ": " .. tostring(values))
        return
    end

    print("")
    print("=== " .. title .. " ===")

    for _, key in ipairs(sortedKeys(values)) do
        local value = values[key]

        if type(value) == "table" then
            print(tostring(key) .. " = <table>")
        else
            print(tostring(key) .. " = " .. tostring(value))
        end
    end
end

local function run()
    local blockName = reader.getBlockName()
    print("POTATOCORE // BLOOD ALTAR PROBE")
    print("BLOCK: " .. tostring(blockName))

    if not blockName then
        error("Block Reader sees no block. Put the Blood Altar directly in front of it.")
    end

    if blockName ~= "bloodmagic:altar" then
        print("WARNING: Expected bloodmagic:altar")
    end

    local data = reader.getBlockData()
    if type(data) ~= "table" then
        error("No tile-entity data returned. Check Block Reader direction and connection.")
    end

    printTable(data, "ROOT BLOCK DATA")

    local altarData = data.bloodAltar
    if type(altarData) == "table" then
        printTable(altarData, "BLOOD ALTAR DATA")
    else
        print("")
        print("No data.bloodAltar table found.")
        print("Full block data saved to blood_altar_data.txt")

        local handle = fs.open("blood_altar_data.txt", "w")
        if handle then
            handle.write(textutils.serialize(data))
            handle.close()
        end

        textutils.pagedPrint(textutils.serialize(data))
        return
    end

    local amount = altarData.Amount or altarData.amount
    print("")
    print("=== LIKELY DASHBOARD VALUES ===")
    print("Stored LP / Fluid Amount: " .. tostring(amount))
    print("Capacity: " .. tostring(altarData.capacity))
    print("Tier: " .. tostring(altarData.upgradeLevel))
    print("Progress: " .. tostring(altarData.progress))
    print("Active: " .. tostring(altarData.isActive))
    print("LP Required: " .. tostring(altarData.liquidRequired))
    print("Consumption / Tick: " .. tostring(altarData.consumptionRate))
    print("Drain Rate: " .. tostring(altarData.drainRate))
    print("Charging Rune Buffer: " .. tostring(altarData.totalCharge))
    print("Charging Rune Max: " .. tostring(altarData.maxCharge))

    local handle = fs.open("blood_altar_data.txt", "w")
    if handle then
        handle.write(textutils.serialize(data))
        handle.close()
        print("Full data saved: blood_altar_data.txt")
    end
end

local success, errorMessage = pcall(run)
if not success then
    printError(errorMessage)
end
