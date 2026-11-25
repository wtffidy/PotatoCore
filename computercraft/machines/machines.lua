-- ============================================================
-- POTATOCORE // BOTANIA MACHINE TRANSMITTER
-- Installed on each machine-side Advanced Computer.
--
-- Hardware:
--   TOP = Ender Modem
--   Block Reader = locally attached, facing DOWN at its machine
--
-- Sends Block Reader data to the dedicated monitor computer.
-- This program does NOT require a monitor.
-- ============================================================

local CONFIG = {
    modemSide = "top",
    protocol = "potatocore_botania_machines_v1",
    updateInterval = 2
}

local modemType = peripheral.getType(CONFIG.modemSide)
if modemType ~= "modem" then
    error("Ender Modem not found on " .. CONFIG.modemSide:upper() .. "!")
end

rednet.open(CONFIG.modemSide)

local function safeCall(object, method)
    if not object or type(object[method]) ~= "function" then
        return nil
    end

    local ok, result = pcall(object[method])
    if ok then
        return result
    end

    return nil
end

local function isBlockReader(name)
    local peripheralType = peripheral.getType(name)
    return peripheralType == "blockReader" or peripheralType == "block_reader"
end

local function scanReaders()
    local readers = {}

    for _, name in ipairs(peripheral.getNames()) do
        if isBlockReader(name) then
            local reader = peripheral.wrap(name)

            if reader then
                local blockName = safeCall(reader, "getBlockName")
                local blockData = safeCall(reader, "getBlockData")
                local blockStates = safeCall(reader, "getBlockStates")

                readers[#readers + 1] = {
                    reader = name,
                    block = blockName,
                    data = blockData,
                    states = blockStates
                }
            end
        end
    end

    table.sort(readers, function(a, b)
        return a.reader < b.reader
    end)

    return readers
end

print("========================================")
print(" POTATOCORE // MACHINE TRANSMITTER")
print("========================================")
print("Computer ID : " .. os.getComputerID())
print("Ender Modem : " .. CONFIG.modemSide:upper())
print("Protocol    : " .. CONFIG.protocol)
print("Status      : ONLINE")
print("----------------------------------------")
print("Scanning local Block Readers...")

local lastReaderCount = -1

while true do
    local readers = scanReaders()

    local packet = {
        kind = "botania_machines",
        version = 1,
        computer = os.getComputerID(),
        readers = readers,
        count = #readers,
        timestamp = os.epoch("utc")
    }

    local success, err = pcall(rednet.broadcast, packet, CONFIG.protocol)

    if not success then
        print("Broadcast error: " .. tostring(err))
    end

    if #readers ~= lastReaderCount then
        print("Local Block Readers: " .. #readers)

        for _, reader in ipairs(readers) do
            print(" - " .. reader.reader .. ": " .. tostring(reader.block))
        end

        lastReaderCount = #readers
    end

    sleep(CONFIG.updateInterval)
end
