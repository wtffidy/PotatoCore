-- ============================================================
-- POTATOCORE // BLOOD ALTAR TRANSMITTER
-- Project Infinity 0.1 | Blood Magic 3.3.8-50
--
-- Hardware:
--   Computer directly below the Blood Altar.
--   Ender Modem attached to the computer's BOTTOM.
--   Block Reader faces the altar and is connected to the computer
--   through a wired modem network.
--
-- The reader is auto-discovered. The modem defaults to BOTTOM.
-- ============================================================

local CONFIG = {
    modemSide = "bottom",
    protocol = "potatocore_blood_altar_v1",
    updateInterval = 0.5,
    readerGracePeriod = 15,
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

local function findModem()
    if peripheral.isPresent(CONFIG.modemSide) and hasType(CONFIG.modemSide, "modem") then
        return CONFIG.modemSide
    end

    for _, name in ipairs(peripheral.getNames()) do
        if hasType(name, "modem") then
            return name
        end
    end

    return nil
end

local function findBlockReader()
    for _, name in ipairs(peripheral.getNames()) do
        if hasType(name, "blockReader") or hasType(name, "block_reader") then
            local reader = peripheral.wrap(name)
            if reader and type(reader.getBlockName) == "function"
                and type(reader.getBlockData) == "function" then
                return reader, name
            end
        end
    end

    return nil, nil
end

local modemSide = findModem()
if not modemSide then
    error("No Ender Modem found. Expected BOTTOM. Peripherals: " .. table.concat(peripheral.getNames(), ", "))
end

local reader, readerName = findBlockReader()
if not reader then
    error("No Block Reader found. Connect the reader facing the altar through a wired modem network.")
end

rednet.open(modemSide)

local function readInputItem(blockData)
    local items = blockData.Items or blockData.items
    if type(items) ~= "table" then
        return "Empty", 0
    end

    for _, stack in pairs(items) do
        if type(stack) == "table" and tonumber(stack.Slot or stack.slot) == 0 then
            local itemId = tostring(stack.id or stack.Id or stack.name or stack.Name or "Unknown")
            return itemId, tonumber(stack.Count or stack.count) or 1
        end
    end

    return "Empty", 0
end

local function readAltar()
    local blockName = reader.getBlockName()
    if blockName ~= CONFIG.altarBlock then
        return nil, "Block Reader '" .. readerName .. "' sees " .. tostring(blockName)
            .. "; expected " .. CONFIG.altarBlock .. ". Check reader direction."
    end

    local blockData = reader.getBlockData()
    if type(blockData) ~= "table" then
        return nil, "Block Reader returned no altar tile data."
    end

    local altar = blockData.bloodAltar
    if type(altar) ~= "table" then
        return nil, "bloodAltar data missing. Run blood_probe.lua to inspect the reader."
    end

    local item, itemCount = readInputItem(blockData)
    local storedLP = tonumber(altar.Amount or altar.amount) or 0
    local capacity = tonumber(altar.capacity) or 0
    local progress = tonumber(altar.progress) or 0
    local required = tonumber(altar.liquidRequired) or 0

    return {
        block = blockName,
        storedLP = storedLP,
        capacity = capacity,
        tier = tostring(altar.upgradeLevel or "UNKNOWN"),
        progress = progress,
        active = altar.isActive == true or tonumber(altar.isActive) == 1,
        liquidRequired = required,
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

local function broadcast(message)
    rednet.broadcast(message, CONFIG.protocol)
end

local lastGoodAltar
local lastGoodAt
local lastError
local offlineBroadcast = false

print("========================================")
print(" POTATOCORE // BLOOD ALTAR LINK")
print("========================================")
print("Computer    : " .. os.getComputerID())
print("Modem       : " .. modemSide)
print("Block Reader: " .. readerName)
print("Protocol    : " .. CONFIG.protocol)
print("Status      : ONLINE")
print("----------------------------------------")

while true do
    local ok, altar, readError = pcall(readAltar)

    if ok and altar then
        altar.readingDelayed = false
        lastGoodAltar = altar
        lastGoodAt = os.epoch("utc")
        offlineBroadcast = false
        broadcast({
            kind = "blood_altar",
            version = 2,
            computer = os.getComputerID(),
            altar = altar
        })

        if lastError then
            print("Block Reader link restored.")
            lastError = nil
        end
    else
        local message = ok and tostring(readError) or tostring(altar)
        local now = os.epoch("utc")
        local staleSeconds = lastGoodAt and math.floor((now - lastGoodAt) / 1000) or nil

        if message ~= lastError then
            printError(message)
            lastError = message
        end

        if lastGoodAltar and staleSeconds and staleSeconds <= CONFIG.readerGracePeriod then
            local stale = {}
            for key, value in pairs(lastGoodAltar) do
                stale[key] = value
            end
            stale.readingDelayed = true
            stale.readerError = message
            stale.readingDelayedSeconds = staleSeconds
            broadcast({
                kind = "blood_altar",
                version = 2,
                computer = os.getComputerID(),
                altar = stale
            })
        elseif not offlineBroadcast then
            broadcast({
                kind = "blood_altar_offline",
                version = 2,
                computer = os.getComputerID(),
                error = message,
                timestamp = now
            })
            offlineBroadcast = true
        end
    end

    sleep(CONFIG.updateInterval)
end
