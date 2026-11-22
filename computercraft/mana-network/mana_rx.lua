-- ============================================================
-- POTATOCORE // MULTI-POOL MANA COMMAND
-- Remote dashboard for a 5x5 monitor wall
--
-- Hardware on this computer:
--   BOTTOM = Ender Modem
--   TOP    = Monitor (or monitor network)
--
-- Receives data from one or more mana_tx computers.
-- Each transmitter is identified by its ComputerCraft ID.
-- ============================================================

local CONFIG = {
    modemSide = "bottom",
    monitorSide = "top",
    protocol = "potatocore_mana_multi_v1",
    transmitterTimeout = 6,
    textScale = 0.5,
    receiveInterval = 0.25
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
monitor.setBackgroundColor(colors.black)
monitor.setTextColor(colors.white)

local width, height = monitor.getSize()
local screen = window.create(monitor, 1, 1, width, height, true)

local sources = {}

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

local function formatNumber(value)
    local result = tostring(math.floor(math.abs(value)))

    while true do
        local formatted, count = result:gsub(
            "^(%d+)(%d%d%d)",
            "%1,%2"
        )

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

local function writeAt(x, y, value, foreground)
    if y < 1 or y > height or x > width then
        return
    end

    value = tostring(value)
    x = math.floor(x)

    if x < 1 then
        value = value:sub(2 - x)
        x = 1
    end

    value = value:sub(1, width - x + 1)
    if #value == 0 then
        return
    end

    screen.setCursorPos(x, y)
    screen.setTextColor(foreground or C.white)
    screen.write(value)
end

local function center(y, value, foreground)
    local x = math.floor((width - #value) / 2) + 1
    writeAt(x, y, value, foreground)
end

local function horizontal(y, character, foreground)
    writeAt(2, y, string.rep(character, math.max(0, width - 2)), foreground)
end

local function drawFrame()
    writeAt(1, 1, "+" .. string.rep("-", width - 2) .. "+", C.border)
    writeAt(1, height, "+" .. string.rep("-", width - 2) .. "+", C.border)

    for y = 2, height - 1 do
        writeAt(1, y, "|", C.border)
        writeAt(width, y, "|", C.border)
    end
end

local function drawBar(y, percentage)
    local barWidth = math.max(1, width - 14)
    local filled = math.floor(barWidth * percentage / 100)
    filled = math.max(0, math.min(barWidth, filled))

    local x = math.floor((width - barWidth - 2) / 2) + 1

    writeAt(x, y, "[", C.border)
    writeAt(x + 1, y, string.rep("#", filled), C.green)
    writeAt(
        x + filled + 1,
        y,
        string.rep("-", barWidth - filled),
        C.muted
    )
    writeAt(x + barWidth + 1, y, "]", C.border)
end

local function estimateTime(mana, maximum, rate)
    if rate > 0.5 and mana < maximum then
        return "FULL IN " .. math.floor((maximum - mana) / rate) .. "s"
    elseif rate < -0.5 and mana > 0 then
        return "EMPTY IN " .. math.floor(mana / math.abs(rate)) .. "s"
    end

    return "ETA --"
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
    screen.setBackgroundColor(C.background)
    screen.setTextColor(C.white)
    screen.clear()

    drawFrame()

    local pools, mana, maximum, rate, transmitters = collectTotals()

    center(2, "POTATOCORE // MANA NETWORK", C.green)
    center(3, "MULTI-POOL OPERATIONS CENTRE", C.blue)
    horizontal(4, "=", C.border)

    if #pools == 0 then
        center(8, "WAITING FOR MANA TRANSMITTERS", C.orange)
        center(10, "CHECK BOTH ENDER MODEMS", C.muted)
        center(12, "PROTOCOL: " .. CONFIG.protocol, C.muted)
        screen.redraw()
        return
    end

    local percentage = maximum > 0 and mana / maximum * 100 or 0
    percentage = math.max(0, math.min(100, percentage))

    local status = "IDLE"
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

    center(5, status, statusColour)
    center(7, string.format("%.2f%%", percentage), C.cyan)
    drawBar(9, percentage)

    horizontal(11, "-", C.border)

    center(12, "TOTAL NETWORK MANA", C.muted)
    center(13, formatNumber(mana) .. " / " .. formatNumber(maximum), C.white)

    center(
        14,
        "FLOW: " .. signedNumber(rate) .. " MANA/SEC",
        rate > 0.5 and C.green or rate < -0.5 and C.red or C.muted
    )

    center(
        15,
        "POOLS: " .. #pools .. "  |  TRANSMITTERS: " .. transmitters,
        C.blue
    )

    center(17, "INDIVIDUAL MANA POOLS", C.cyan)
    horizontal(18, "-", C.border)

    local listStart = 19
    local listEnd = height - 3
    local availableRows = math.max(0, listEnd - listStart + 1)

    for index, pool in ipairs(pools) do
        if index > availableRows then
            writeAt(4, listEnd, "+" .. ( #pools - index + 1 ) .. " MORE POOLS", C.orange)
            break
        end

        local y = listStart + index - 1
        local poolPercentage = pool.maximum > 0
            and pool.mana / pool.maximum * 100
            or 0

        local name = "PC" .. pool.computer .. "/" .. pool.name
        local rateText = signedNumber(pool.rate) .. "/s"

        local lineText = string.format(
            "%-18s %5.1f%%  %s/%s  %s",
            fit(name, 18),
            poolPercentage,
            formatNumber(pool.mana),
            formatNumber(pool.maximum),
            rateText
        )

        local colour = poolPercentage >= 99.99 and C.cyan
            or poolPercentage <= 5 and C.red
            or C.white

        writeAt(3, y, lineText, colour)
    end

    horizontal(height - 2, "-", C.border)
    writeAt(3, height - 1, "POTATOCORE", C.green)
    writeAt(width - 15, height - 1, "LINK: ONLINE", C.green)

    screen.redraw()
end

print("POTATOCORE // MANA NETWORK")
print("Monitor: " .. CONFIG.monitorSide:upper())
print("Ender Modem: " .. CONFIG.modemSide:upper())
print("Protocol: " .. CONFIG.protocol)
print("Waiting for transmitters...")

while true do
    local senderId, message = rednet.receive(
        CONFIG.protocol,
        CONFIG.receiveInterval
    )

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
                    mana = pool.mana,
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

    for computerId, source in pairs(sources) do
        if now - source.seen > CONFIG.transmitterTimeout * 1000 then
            sources[computerId] = nil
        end
    end

    drawDashboard()
end
