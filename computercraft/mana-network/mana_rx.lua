-- ============================================================
-- POTATOCORE // MANA NETWORK DASHBOARD
-- Clean, low-flicker dashboard for a 3x3 mana pool array.
--
-- Monitor computer hardware:
--   BOTTOM = Ender Modem
--   TOP    = Monitor / monitor network
--
-- Receives multi-pool telemetry from mana_tx.lua transmitters.
-- ============================================================

local CONFIG = {
    modemSide = "bottom",
    monitorSide = "top",
    protocol = "potatocore_mana_multi_v1",
    transmitterTimeout = 6,
    textScale = 0.7,
    receiveInterval = 0.5
}

local modemType = peripheral.getType(CONFIG.modemSide)
if modemType ~= "modem" then
    error("Ender Modem not found on " .. CONFIG.modemSide:upper() .. "!")
end

local monitor = peripheral.wrap(CONFIG.monitorSide)
if not monitor then
    error("Monitor not found on " .. CONFIG.monitorSide:upper() .. "!")
end

rednet.open(CONFIG.modemSide)

monitor.setTextScale(CONFIG.textScale)

local width, height = monitor.getSize()

-- Fall back slightly if the connected monitor is too small at 0.7.
if width < 54 or height < 24 then
    CONFIG.textScale = 0.5
    monitor.setTextScale(CONFIG.textScale)
    width, height = monitor.getSize()
end

local C = {
    background = colors.black,
    white = colors.white,
    muted = colors.gray,
    border = colors.blue,
    cyan = colors.cyan,
    green = colors.lime,
    red = colors.red,
    orange = colors.orange,
    blue = colors.lightBlue
}

local sources = {}
local renderedRows = {}

monitor.setBackgroundColor(C.background)
monitor.setTextColor(C.white)
monitor.clear()

local function formatNumber(value)
    local result = tostring(math.floor(math.abs(value)))

    while true do
        local formatted, count = result:gsub("^(%d+)(%d%d%d)", "%1,%2")
        result = formatted
        if count == 0 then
            break
        end
    end

    return result
end

local function signedNumber(value)
    if value > 0 then
        return "+" .. formatNumber(value)
    elseif value < 0 then
        return "-" .. formatNumber(value)
    end

    return "0"
end

local function fit(value, maxLength)
    value = tostring(value)
    if #value <= maxLength then
        return value
    end

    if maxLength <= 3 then
        return value:sub(1, maxLength)
    end

    return value:sub(1, maxLength - 3) .. "..."
end

local function formatDuration(seconds)
    seconds = math.max(0, math.floor(seconds))

    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)

    if days > 0 then
        return days .. "d " .. hours .. "h"
    elseif hours > 0 then
        return hours .. "h " .. minutes .. "m"
    elseif minutes > 0 then
        return minutes .. "m"
    end

    return seconds .. "s"
end

local function setRow(rows, rowColours, y, value, colour, centered)
    if y < 1 or y > height then
        return
    end

    value = tostring(value or "")
    if #value > width then
        value = value:sub(1, width)
    end

    if centered then
        value = string.rep(" ", math.max(0, math.floor((width - #value) / 2))) .. value
    end

    rows[y] = value
    rowColours[y] = colour or C.white
end

-- Only rows whose text or colour changed are written to the monitor.
-- Avoiding clear() and full-screen redraws is what removes the flashing.
local function renderRows(rows, rowColours)
    for y = 1, height do
        local value = rows[y] or ""
        local colour = rowColours[y] or C.white
        local colourCode = colors.toBlit(colour)
        local cacheKey = value .. "|" .. colourCode

        if renderedRows[y] ~= cacheKey then
            local line = fit(value, width)
            line = line .. string.rep(" ", math.max(0, width - #line))

            monitor.setCursorPos(1, y)
            monitor.blit(
                line,
                string.rep(colourCode, width),
                string.rep(colors.toBlit(C.background), width)
            )

            renderedRows[y] = cacheKey
        end
    end
end

local function collectTotals()
    local now = os.epoch("utc")
    local allPools = {}
    local totalMana = 0
    local totalMaximum = 0
    local totalRate = 0
    local activeTransmitters = 0

    for computerId, source in pairs(sources) do
        if now - source.seen <= CONFIG.transmitterTimeout * 1000 then
            activeTransmitters = activeTransmitters + 1

            for _, pool in ipairs(source.pools) do
                allPools[#allPools + 1] = {
                    computer = computerId,
                    name = pool.name,
                    mana = pool.mana,
                    maximum = pool.maximum,
                    rate = pool.rate
                }

                totalMana = totalMana + pool.mana
                totalMaximum = totalMaximum + pool.maximum
                totalRate = totalRate + pool.rate
            end
        end
    end

    table.sort(allPools, function(a, b)
        if a.computer == b.computer then
            return a.name < b.name
        end

        return a.computer < b.computer
    end)

    return allPools, totalMana, totalMaximum, totalRate, activeTransmitters
end

local function drawDashboard()
    local rows = {}
    local rowColours = {}

    local pools, mana, maximum, rate, transmitters = collectTotals()
    local percentage = maximum > 0 and mana / maximum * 100 or 0
    percentage = math.max(0, math.min(100, percentage))

    setRow(rows, rowColours, 1, "+" .. string.rep("=", math.max(0, width - 2)) .. "+", C.border)
    setRow(rows, rowColours, 2, "POTATOCORE / MANA NETWORK", C.green, true)
    setRow(rows, rowColours, 3, "NINE-POOL OPERATIONS", C.blue, true)
    setRow(rows, rowColours, 4, string.rep("-", width), C.border)

    if #pools == 0 then
        setRow(rows, rowColours, 7, "WAITING FOR MANA TRANSMITTERS", C.orange, true)
        setRow(rows, rowColours, 9, "CHECK THE TRANSMITTERS AND ENDER MODEMS", C.muted, true)
        setRow(rows, rowColours, height, "+" .. string.rep("=", math.max(0, width - 2)) .. "+", C.border)
        renderRows(rows, rowColours)
        return
    end

    local status = "STABLE"
    local statusColour = C.muted

    if percentage >= 99.99 then
        status = "NETWORK FULL"
        statusColour = C.cyan
    elseif percentage <= 5 then
        status = "LOW MANA"
        statusColour = C.red
    elseif rate > 0.5 then
        status = "CHARGING"
        statusColour = C.green
    elseif rate < -0.5 then
        status = "DISCHARGING"
        statusColour = C.orange
    end

    setRow(
        rows,
        rowColours,
        5,
        status .. "  |  " .. string.format("%.1f%% STORED", percentage),
        statusColour,
        true
    )

    local barWidth = math.max(10, width - 4)
    local filled = math.floor(barWidth * percentage / 100)
    filled = math.max(0, math.min(barWidth, filled))
    local bar = "[" .. string.rep("#", filled) .. string.rep("-", barWidth - filled) .. "]"
    setRow(rows, rowColours, 6, bar, C.green, true)

    setRow(
        rows,
        rowColours,
        7,
        "MANA  " .. formatNumber(mana) .. " / " .. formatNumber(maximum),
        C.white,
        true
    )

    local flowText = "FLOW  " .. signedNumber(rate) .. "/s"
    if rate > 0.5 and mana < maximum then
        flowText = flowText .. "  |  FULL IN " .. formatDuration((maximum - mana) / rate)
    elseif rate < -0.5 and mana > 0 then
        flowText = flowText .. "  |  EMPTY IN " .. formatDuration(mana / math.abs(rate))
    end
    setRow(rows, rowColours, 8, flowText, rate > 0.5 and C.green or rate < -0.5 and C.orange or C.muted, true)

    setRow(
        rows,
        rowColours,
        9,
        #pools .. " POOLS ONLINE  |  " .. transmitters .. " TRANSMITTERS",
        C.blue,
        true
    )

    setRow(rows, rowColours, 10, string.rep("-", width), C.border)
    setRow(rows, rowColours, 11, "POOL             STORED / MAXIMUM         FILL    FLOW", C.cyan)

    local fullCount = 0
    local lowCount = 0
    local chargingCount = 0
    local drainingCount = 0
    local firstPoolRow = 12
    local lastPoolRow = math.min(height - 3, firstPoolRow + #pools - 1)
    local visiblePools = math.max(0, lastPoolRow - firstPoolRow + 1)

    for index, pool in ipairs(pools) do
        local poolPercentage = pool.maximum > 0 and pool.mana / pool.maximum * 100 or 0

        if poolPercentage >= 99.99 then
            fullCount = fullCount + 1
        elseif poolPercentage <= 5 then
            lowCount = lowCount + 1
        elseif pool.rate > 0.5 then
            chargingCount = chargingCount + 1
        elseif pool.rate < -0.5 then
            drainingCount = drainingCount + 1
        end

        if index <= visiblePools then
            local label = string.format("POOL %02d [PC%d]", index, pool.computer)
            local manaText = fit(formatNumber(pool.mana), 10)
            local maxText = fit(formatNumber(pool.maximum), 10)
            local flowText = signedNumber(pool.rate) .. "/s"

            local line = string.format(
                "%-14s %10s/%-10s %5.1f%% %s",
                label,
                manaText,
                maxText,
                poolPercentage,
                flowText
            )

            local colour = poolPercentage >= 99.99 and C.cyan
                or poolPercentage <= 5 and C.red
                or pool.rate > 0.5 and C.green
                or pool.rate < -0.5 and C.orange
                or C.white

            setRow(rows, rowColours, firstPoolRow + index - 1, line, colour)
        end
    end

    if #pools > visiblePools and height - 3 >= firstPoolRow then
        setRow(
            rows,
            rowColours,
            height - 3,
            "+" .. (#pools - visiblePools) .. " MORE POOLS",
            C.orange
        )
    end

    setRow(rows, rowColours, height - 2, string.rep("-", width), C.border)
    setRow(
        rows,
        rowColours,
        height - 1,
        "FULL " .. fullCount .. "  |  LOW " .. lowCount
            .. "  |  CHARGING " .. chargingCount
            .. "  |  DRAINING " .. drainingCount,
        C.blue
    )
    setRow(rows, rowColours, height, "+" .. string.rep("=", math.max(0, width - 2)) .. "+", C.border)

    renderRows(rows, rowColours)
end

print("POTATOCORE / MANA NETWORK")
print("Monitor: " .. CONFIG.monitorSide:upper())
print("Ender Modem: " .. CONFIG.modemSide:upper())
print("Text scale: " .. CONFIG.textScale)
print("Waiting for mana transmitters...")

while true do
    local senderId, message = rednet.receive(CONFIG.protocol, CONFIG.receiveInterval)

    if senderId
        and type(message) == "table"
        and message.kind == "mana_multi"
        and type(message.pools) == "table" then

        local cleanPools = {}

        for _, pool in ipairs(message.pools) do
            if type(pool) == "table"
                and type(pool.name) == "string"
                and type(pool.mana) == "number"
                and type(pool.maximum) == "number"
                and pool.maximum > 0
                and type(pool.rate) == "number" then

                cleanPools[#cleanPools + 1] = {
                    name = pool.name,
                    mana = math.max(0, pool.mana),
                    maximum = pool.maximum,
                    rate = pool.rate
                }
            end
        end

        sources[senderId] = {
            pools = cleanPools,
            seen = os.epoch("utc")
        }
    end

    local now = os.epoch("utc")
    local expired = false

    for computerId, source in pairs(sources) do
        if now - source.seen > CONFIG.transmitterTimeout * 1000 then
            sources[computerId] = nil
            expired = true
        end
    end

    -- Draw only when new data arrives or a transmitter expires.
    if senderId or expired then
        drawDashboard()
    end
end
