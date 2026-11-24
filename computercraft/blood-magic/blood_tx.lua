-- ============================================================
-- POTATOCORE // BLOOD ALTAR TRANSMITTER
-- Project Infinity 0.1 | Blood Magic + Advanced Peripherals
--
-- Altar computer hardware:
--   Block Reader: TOP
--   Ender Modem: BOTTOM
--
-- The Block Reader must face the Blood Altar.
-- This script only reads altar data and broadcasts it.
-- ============================================================

local CONFIG = {
    readerSide = "top",
    modemSide = "bottom",
    protocol = "potatocore_blood_altar_v1",
    updateInterval = 0.5,
    altarBlock = "bloodmagic:altar"
}

local function hasType(name, expected)
    local types = { peripheral.getType(name) }
    for _, peripheralType in ipairs(types) do
        if peripheralType == expected then
            return true
        end
    end
    return false
end

local function listPeripherals()
    local result = {}
    for _, name in ipairs(peripheral.getNames()) do
        local types = { peripheral.getType(name) }
        result[#result + 1] = name .. " [" .. table.concat(types, ", ") .. "]"
    end
    return #result > 0 and table.concat(result, ", ") or "none"
end

if not hasType(CONFIG.modemSide, "modem") then
    error("No modem on BOTTOM. Detected: " .. listPeripherals())
end

-- Prefer the directly attached top-side reader, then search wired peripherals.
local readerName
if peripheral.isPresent(CONFIG.readerSide) and hasType(CONFIG.readerSide, "blockReader") then
    readerName = CONFIG.readerSide
elseif peripheral.isPresent(CONFIG.readerSide) and hasType(CONFIG.readerSide, "block_reader") then
    readerName = CONFIG.readerSide
else
    for _, name in ipairs(peripheral.getNames()) do
        if hasType(name, "blockReader") or hasType(name, "block_reader") then
            readerName = name
            break
        end
    end
end

if not readerName then
    error("Block Reader not detected. Expected it on TOP or on the wired network. Detected: " .. listPeripherals())
end

local reader = peripheral.wrap(readerName)
if not reader then
    error("Could not wrap Block Reader '" .. readerName .. "'. Detected: " .. listPeripherals())
end

if type(reader.getBlockName) ~= "function" or type(reader.getBlockData) ~= "function" then
    error("Peripheral '" .. readerName .. "' is missing getBlockName/getBlockData. Detected: " .. listPeripherals())
end

rednet.open(CONFIG.modemSide)

local function readInputItem(blockData)
    local items = blockData.Items or blockData.items
    if type(items) ~= "table" then
        return "Empty", 0
    end

    for _, stack in ipairs(items) do
        if type(stack) == "table" and tonumber(stack.Slot or stack.slot) == 0 then
            local itemId = tostring(stack.id or stack.Id or stack.name or "Unknown")
            return itemId, tonumber(stack.Count or stack.count) or 1
        end
    end

    return "Empty", 0
end

local function readAltar()
    local blockName = reader.getBlockName()
    if blockName ~= CONFIG.altarBlock then
        return nil, "Block Reader '" .. readerName .. "' sees " .. tostring(blockName)
            .. "; expected " .. CONFIG.altarBlock .. ". Check which way the reader faces."
    end

    local blockData = reader.getBlockData()
    if type(blockData) ~= "table" then
        return nil, "Block Reader returned no tile data for " .. CONFIG.altarBlock
    end

    local altar = blockData.bloodAltar
    if type(altar) ~= "table" then
        return nil, "bloodAltar data missing. Run blood_probe.lua to inspect the reader data."
    end

    local item, itemCount = readInputItem(blockData)

    return {
        block = blockName,
        storedLP = tonumber(altar.Amount or altar.amount) or 0,
        capacity = tonumber(altar.capacity) or 0,
        tier = tostring(altar.upgradeLevel or "UNKNOWN"),
        progress = tonumber(altar.progress) or 0,
        active = altar.isActive == true or tonumber(altar.isActive) == 1,
        liquidRequired = tonumber(altar.liquidRequired) or 0,
        consumptionRate = tonumber(altar.consumptionRate) or 0,
        drainRate = tonumber(altar.drainRate) or 0,
        bufferCapacity = tonumber(altar.bufferCapacity) or 0,
        totalCharge = tonumber(altar.totalCharge) or 0,
        maxCharge = tonumber(altar.maxCharge) or 0,
        inputItem = item,
        inputCount = itemCount,
        timestamp = os.epoch("utc")
    }
end

print("========================================")
print(" POTATOCORE // BLOOD ALTAR TRANSMITTER")
print("========================================")
print("Computer ID : " .. os.getComputerID())
print("Block Reader: " .. readerName)
print("Ender Modem : " .. CONFIG.modemSide:upper())
print("Protocol    : " .. CONFIG.protocol)
print("----------------------------------------")

local lastError

while true do
    local success, altar, readError = pcall(readAltar)

    if success and altar then
        rednet.broadcast({
            kind = "blood_altar",
            version = 1,
            computer = os.getComputerID(),
            altar = altar
        }, CONFIG.protocol)

        if lastError then
            print("Altar link restored.")
            lastError = nil
        end
    else
        local message = success and tostring(readError) or tostring(altar)
        if message ~= lastError then
            printError(message)
            lastError = message
        end

        rednet.broadcast({
            kind = "blood_altar_offline",
            version = 1,
            computer = os.getComputerID(),
            error = message,
            timestamp = os.epoch("utc")
        }, CONFIG.protocol)
    end

    sleep(CONFIG.updateInterval)
end
