-- ============================================================
-- POTATOCORE // MULTI-POOL MANA TRANSMITTER
-- Project Infinity 0.1 | CC:Tweaked + Advanced Peripherals
--
-- Hardware on this computer:
--   FRONT = Ender Modem
--
-- Finds every Mana Pool peripheral visible to this computer:
--   - directly attached peripherals
--   - peripherals exposed through a connected wired network
--
-- Other computers can run this same program. Each computer's
-- packets are combined by the remote receiver using its ID.
-- ============================================================

local CONFIG = {
    modemSide = "front",
    protocol = "potatocore_mana_multi_v1",
    updateInterval = 0.5
}

local previousReadings = {}
local lastPoolCount = -1

local modemType = peripheral.getType(CONFIG.modemSide)
if modemType ~= "modem" then
    error("Ender Modem not found on " .. CONFIG.modemSide:upper() .. "!")
end

rednet.open(CONFIG.modemSide)

local function isManaPool(name)
    local types = { peripheral.getType(name) }

    for _, peripheralType in ipairs(types) do
        if peripheralType == "manaPool" then
            return true
        end
    end

    return false
end

local function readPool(name, now)
    local pool = peripheral.wrap(name)
    if not pool
        or type(pool.getMana) ~= "function"
        or type(pool.getMaxMana) ~= "function" then
        return nil
    end

    local success, mana, maximum = pcall(function()
        return pool.getMana(), pool.getMaxMana()
    end)

    if not success
        or type(mana) ~= "number"
        or type(maximum) ~= "number"
        or maximum <= 0 then
        return nil
    end

    local rate = 0
    local previous = previousReadings[name]

    if previous then
        local elapsed = now - previous.time
        if elapsed > 0 then
            rate = (mana - previous.mana) / elapsed
        end
    end

    previousReadings[name] = {
        mana = mana,
        time = now
    }

    return {
        name = name,
        mana = mana,
        maximum = maximum,
        rate = rate
    }
end

print("========================================")
print(" POTATOCORE // MANA TRANSMITTER")
print("========================================")
print("Computer ID : " .. os.getComputerID())
print("Ender Modem : " .. CONFIG.modemSide:upper())
print("Protocol    : " .. CONFIG.protocol)
print("Status      : ONLINE")
print("----------------------------------------")
print("Discovering accessible Mana Pools...")

while true do
    local now = os.clock()
    local pools = {}
    local currentNames = {}

    for _, name in ipairs(peripheral.getNames()) do
        if isManaPool(name) then
            currentNames[name] = true

            local reading = readPool(name, now)
            if reading then
                pools[#pools + 1] = reading
            end
        end
    end

    -- Forget detached peripherals so a reconnected pool starts
    -- with a clean rate sample instead of a stale reading.
    for name in pairs(previousReadings) do
        if not currentNames[name] then
            previousReadings[name] = nil
        end
    end

    table.sort(pools, function(a, b)
        return a.name < b.name
    end)

    local totalMana = 0
    local totalMaximum = 0
    local totalRate = 0

    for _, pool in ipairs(pools) do
        totalMana = totalMana + pool.mana
        totalMaximum = totalMaximum + pool.maximum
        totalRate = totalRate + pool.rate
    end

    local packet = {
        kind = "mana_multi",
        version = 1,
        computer = os.getComputerID(),
        pools = pools,
        count = #pools,
        totalMana = totalMana,
        totalMaximum = totalMaximum,
        totalRate = totalRate,
        timestamp = os.epoch("utc")
    }

    rednet.broadcast(packet, CONFIG.protocol)

    if #pools ~= lastPoolCount then
        print("Accessible Mana Pools: " .. #pools)
        lastPoolCount = #pools
    end

    sleep(CONFIG.updateInterval)
end
