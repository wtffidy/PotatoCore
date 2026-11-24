-- ============================================================
-- POTATOCORE // BLOOD ALTAR TRANSMITTER
-- Project Infinity 0.1 | Blood Magic + Advanced Peripherals
--
-- Altar PC:
--   Ender Modem: BOTTOM
--   Block Reader: above the altar, connected to this PC through
--                 the peripheral network / wired modem network.
--   Reader face: aimed at the Blood Altar.
--
-- Reads altar telemetry only. Does not modify the altar.
-- ============================================================

local CONFIG = {
    modemSide = "bottom",
    protocol = "potatocore_blood_altar_v1",
    updateInterval = 0.5,
    altarBlock = "bloodmagic:altar"
}

local modemType = peripheral.getType(CONFIG.modemSide)
if modemType ~= "modem" then
    error("Ender Modem not found on " .. CONFIG.modemSide:upper() .. "!")
end

local reader, readerName = peripheral.find("blockReader")
if not reader then
    print("Connected peripherals:")
    for _, name in ipairs(peripheral.getNames()) do
        print(" - " .. name .. " (" .. tostring(peripheral.getType(name)) .. ")")
    end
    error("Block Reader not found. Connect the reader to this PC with a wired modem network.")
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
        return nil, "Reader sees " .. tostring(blockName) .. ", expected " .. CONFIG.altarBlock
    end

    local blockData = reader.getBlockData()
    if type(blockData) ~= "table" then
        return nil, "Block Reader returned no block data"
    end

    local altar = blockData.bloodAltar
    if type(altar) ~= "table" then
        return nil, "bloodAltar data missing from block NBT"
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
print("Modem       : " .. CONFIG.modemSide:upper())
print("Block Reader: " .. tostring(readerName))
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
