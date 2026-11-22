-- ============================================================
-- POTATOCORE // MANA CORE
-- Autonomous mana-array telemetry and reactor-style dashboard.
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
    expectedPools = 9,
    textScale = 0.8,
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

-- The 3x3 card layout needs room for its labels and footer.
if width < 90 or height < 30 then
    CONFIG.textScale = 0.7
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
    blue = colors.lightBlue,
    purple = colors.purple
}

local sources = {}
local renderedRows = {}
local startedAt = os.epoch("utc")

monitor.setBackgroundColor(C.background)
monitor.setTextColor(C.white)
monitor.clear()

local function compactNumber(value)
    value = math.abs(value)

    if value >= 1000000000 then
        return string.format("%.2fB", value / 1000000000)
    elseif value >= 1000000 then
        return string.format("%.2fM", value / 1000000)
    elseif value >= 1000 then
        return string.format("%.1fK", value / 1000)
    end

    return tostring(math.floor(value))
end

local function signedCompact(value)
    if value > 0 then
        return "+" .. compactNumber(value)
    elseif value < 0 then
        return "-" .. compactNumber(value)
    end

    return "0"
end

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

local function newCanvas()
    local canvas = {
        chars = {},
        foreground = {},
        background = {}
    }

    local foreground = colors.toBlit(C.white)
    local background = colors.toBlit(C.background)

    for y = 1, height do
        canvas.chars[y] = {}
        canvas.foreground[y] = {}
        canvas.background[y] = {}

        for x = 1, width do
            canvas.chars[y][x] = " "
            canvas.foreground[y][x] = foreground
            canvas.background[y][x] = background
        end
    end

    return canvas
end

local function writeAt(canvas, x, y, value, foreground, background)
    if y < 1 or y > height or x > width then
        return
    end

    value = tostring(value or "")
    local foregroundCode = colors.toBlit(foreground or C.white)
    local backgroundCode = colors.toBlit(background or C.background)

    for index = 1, #value do
        local position = x + index - 1

        if position >= 1 and position <= width then
            canvas.chars[y][position] = value:sub(index, index)
            canvas.foreground[y][position] = foregroundCode
            canvas.background[y][position] = backgroundCode
        end
    end
end

local function writeCentered(canvas, y, value, foreground)
    value = tostring(value)
    local x = math.floor((width - #value) / 2) + 1
    writeAt(canvas, x, y, value, foreground)
end

local function writeRight(canvas, y, x, value, foreground)
    value = tostring(value)
    writeAt(canvas, x - #value + 1, y, value, foreground)
end

local function writeRule(canvas, y, character, foreground)
    writeAt(canvas, 1, y, string.rep(character, width), foreground)
end

-- Only changed rows are sent to the monitor. This avoids full-screen
-- clearing and redraws, which cause visible flashing.
local function renderCanvas(canvas)
    for y = 1, height do
        local characters = table.concat(canvas.chars[y])
        local foreground = table.concat(canvas.foreground[y])
        local background = table.concat(canvas.background[y])
        local cacheKey = characters .. foreground .. background

        if renderedRows[y] ~= cacheKey then
            monitor.setCursorPos(1, y)
            monitor.blit(characters, foreground, background)
            renderedRows[y] = cacheKey
        end
    end
end

local function collectTotals()
    local now = os.epoch("utc")
    local arrayPools = {}
    local elvenPools = {}
    local materialsPools = {}
    local totalMana = 0
    local totalMaximum = 0
    local totalRate = 0
    local activeTransmitters = 0

    for computerId, source in pairs(sources) do
        if now - source.seen <= CONFIG.transmitterTimeout * 1000 then
            activeTransmitters = activeTransmitters + 1

            local target = arrayPools
            if source.group == "elven_portal" then
                target = elvenPools
            elseif source.group == "materials_exchange" then
                target = materialsPools
            end

            for _, pool in ipairs(source.pools) do
                target[#target + 1] = {
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

    local function sortPools(poolList)
        table.sort(poolList, function(a, b)
            if a.computer == b.computer then
                return a.name < b.name
            end

            return a.computer < b.computer
        end)
    end

    sortPools(arrayPools)
    sortPools(elvenPools)
    sortPools(materialsPools)

    return arrayPools, elvenPools, materialsPools,
        totalMana, totalMaximum, totalRate, activeTransmitters
end

local function getPoolStatus(pool, percentage)
    if percentage >= 99.99 then
        return "FULL", C.cyan
    elseif percentage <= 5 then
        return "LOW", C.red
    elseif pool.rate > 0.5 then
        return "CHARGING", C.green
    elseif pool.rate < -0.5 then
        return "DRAINING", C.orange
    end

    return "STABLE", C.blue
end

local function drawPoolCard(canvas, index, pool, x, y, cardWidth)
    local right = x + cardWidth - 1
    local innerWidth = cardWidth - 2
    local heading = pool
        and "POOL " .. string.format("%02d", index) .. " // PC" .. pool.computer
        or "POOL " .. string.format("%02d", index) .. " // OFFLINE"
    heading = fit(heading, innerWidth)

    local leftDashes = math.max(0, math.floor((innerWidth - #heading) / 2))
    local rightDashes = math.max(0, innerWidth - #heading - leftDashes)

    writeAt(canvas, x, y, "+" .. string.rep("-", leftDashes), C.border)
    writeAt(canvas, x + 1 + leftDashes, y, heading, pool and C.cyan or C.muted)
    writeAt(
        canvas,
        x + 1 + leftDashes + #heading,
        y,
        string.rep("-", rightDashes) .. "+",
        C.border
    )
    writeAt(canvas, x, y + 4, "+" .. string.rep("-", innerWidth) .. "+", C.border)

    if not pool then
        writeAt(canvas, x, y + 1, "|", C.border)
        writeAt(canvas, x + 1, y + 1, fit("NO SIGNAL", innerWidth), C.orange)
        writeAt(canvas, right, y + 1, "|", C.border)

        writeAt(canvas, x, y + 2, "|", C.border)
        writeAt(canvas, x + 1, y + 2, fit("[--------------------]", innerWidth), C.muted)
        writeAt(canvas, right, y + 2, "|", C.border)

        writeAt(canvas, x, y + 3, "|", C.border)
        writeAt(canvas, x + 1, y + 3, fit("WAITING FOR NODE", innerWidth), C.muted)
        writeAt(canvas, right, y + 3, "|", C.border)
        return
    end

    local percentage = pool.maximum > 0 and pool.mana / pool.maximum * 100 or 0
    percentage = math.max(0, math.min(100, percentage))
    local status, statusColour = getPoolStatus(pool, percentage)
    local statusText = status .. "  " .. string.format("%5.1f%%", percentage)

    writeAt(canvas, x, y + 1, "|", C.border)
    writeAt(canvas, x + 1, y + 1, fit(statusText, innerWidth), statusColour)
    writeAt(canvas, right, y + 1, "|", C.border)

    local barWidth = math.max(4, innerWidth - 4)
    local filled = math.floor(barWidth * percentage / 100)
    filled = math.max(0, math.min(barWidth, filled))

    writeAt(canvas, x, y + 2, "|", C.border)
    writeAt(canvas, x + 1, y + 2, "[", C.muted)
    writeAt(canvas, x + 2, y + 2, string.rep("#", filled), C.green)
    writeAt(canvas, x + filled + 2, y + 2, string.rep("-", barWidth - filled), C.muted)
    writeAt(canvas, x + barWidth + 2, y + 2, "]", C.muted)
    writeAt(canvas, right, y + 2, "|", C.border)

    local stats = compactNumber(pool.mana) .. "/" .. compactNumber(pool.maximum)
        .. "  " .. signedCompact(pool.rate) .. "/s"

    writeAt(canvas, x, y + 3, "|", C.border)
    writeAt(canvas, x + 1, y + 3, fit(stats, innerWidth), C.white)
    writeAt(canvas, right, y + 3, "|", C.border)
end

local function drawAuxPanel(canvas, x, y, panelWidth, title, pools, maxRows)
    local right = x + panelWidth - 1
    local innerWidth = panelWidth - 2
    local heading = fit(title, innerWidth)
    local leftDashes = math.max(0, math.floor((innerWidth - #heading) / 2))
    local rightDashes = math.max(0, innerWidth - #heading - leftDashes)

    writeAt(canvas, x, y, "+" .. string.rep("-", leftDashes), C.purple)
    writeAt(canvas, x + 1 + leftDashes, y, heading, C.cyan)
    writeAt(
        canvas,
        x + 1 + leftDashes + #heading,
        y,
        string.rep("-", rightDashes) .. "+",
        C.purple
    )

    writeAt(canvas, x, y + 1, "|", C.purple)
    writeAt(canvas, x + 1, y + 1, fit("AUXILIARY MANA LINK", innerWidth), C.muted)
    writeAt(canvas, right, y + 1, "|", C.purple)

    local visible = math.min(#pools, maxRows)
    if visible == 0 then
        writeAt(canvas, x, y + 2, "|", C.purple)
        writeAt(canvas, x + 1, y + 2, fit("NO POOL CONNECTED", innerWidth), C.orange)
        writeAt(canvas, right, y + 2, "|", C.purple)
        writeAt(canvas, x, y + 3, "+" .. string.rep("-", innerWidth) .. "+", C.purple)
        return
    end

    for index = 1, visible do
        local pool = pools[index]
        local percentage = pool.maximum > 0 and pool.mana / pool.maximum * 100 or 0
        percentage = math.max(0, math.min(100, percentage))
        local status, statusColour = getPoolStatus(pool, percentage)

        local line = string.format(
            "P%02d %5.1f%% %s/%s %s",
            index,
            percentage,
            compactNumber(pool.mana),
            compactNumber(pool.maximum),
            signedCompact(pool.rate) .. "/s"
        )

        if #pools > maxRows and index == visible then
            line = "+" .. (#pools - visible + 1) .. " MORE POOLS"
            statusColour = C.orange
        end

        writeAt(canvas, x, y + 1 + index, "|", C.purple)
        writeAt(canvas, x + 1, y + 1 + index, fit(line, innerWidth), statusColour)
        writeAt(canvas, right, y + 1 + index, "|", C.purple)
    end

    writeAt(canvas, x, y + 2 + visible, "+" .. string.rep("-", innerWidth) .. "+", C.purple)
end

local function drawDashboard()
    local canvas = newCanvas()
    local arrayPools, elvenPools, materialsPools, mana, maximum, rate, transmitters = collectTotals()
    local percentage = maximum > 0 and mana / maximum * 100 or 0
    percentage = math.max(0, math.min(100, percentage))

    local networkStatus = "SYSTEM STANDBY"
    local statusColour = C.blue

    if #arrayPools < CONFIG.expectedPools then
        networkStatus = "MAIN ARRAY PARTIAL"
        statusColour = C.orange
    elseif percentage >= 99.99 then
        networkStatus = "CAPACITY REACHED"
        statusColour = C.cyan
    elseif percentage <= 5 then
        networkStatus = "CRITICAL MANA"
        statusColour = C.red
    elseif rate > 0.5 then
        networkStatus = "MANA CHARGING"
        statusColour = C.green
    elseif rate < -0.5 then
        networkStatus = "MANA DISCHARGING"
        statusColour = C.orange
    end

    -- Main reactor header.
    writeAt(canvas, 1, 1, "+" .. string.rep("=", width - 2) .. "+", C.border)
    writeCentered(canvas, 2, "POTATOCORE // MANA CORE", C.green)
    writeCentered(canvas, 3, "AUTONOMOUS MANA DISTRIBUTION SYSTEM", C.blue)
    writeRule(canvas, 4, "=", C.border)

    writeAt(canvas, 3, 5, "[SYS] " .. networkStatus, statusColour)
    writeRight(
        canvas,
        5,
        width - 2,
        "[ARRAY] " .. #arrayPools .. "/" .. CONFIG.expectedPools
            .. "  [TX] " .. transmitters,
        C.cyan
    )

    -- Network-wide storage includes the main array and both auxiliary pools.
    local barWidth = math.max(10, width - 8)
    local filled = math.floor(barWidth * percentage / 100)
    filled = math.max(0, math.min(barWidth, filled))
    local barX = math.floor((width - barWidth - 2) / 2) + 1

    writeAt(canvas, barX, 6, "[", C.border)
    writeAt(canvas, barX + 1, 6, string.rep("#", filled), C.green)
    writeAt(canvas, barX + filled + 1, 6, string.rep("-", barWidth - filled), C.muted)
    writeAt(canvas, barX + barWidth + 1, 6, "]", C.border)

    writeCentered(
        canvas,
        7,
        "TOTAL MANA  " .. formatNumber(mana) .. " / " .. formatNumber(maximum)
            .. "  [" .. string.format("%.1f", percentage) .. "%]",
        C.white
    )

    local flowText = "NETWORK FLOW  " .. signedCompact(rate) .. " MANA/SEC"
    if rate > 0.5 and mana < maximum then
        flowText = flowText .. "  //  FULL IN " .. formatDuration((maximum - mana) / rate)
    elseif rate < -0.5 and mana > 0 then
        flowText = flowText .. "  //  EMPTY IN " .. formatDuration(mana / math.abs(rate))
    end

    writeCentered(
        canvas,
        8,
        fit(flowText, width - 4),
        rate > 0.5 and C.green or rate < -0.5 and C.orange or C.muted
    )

    writeRule(canvas, 9, "-", C.border)
    writeCentered(canvas, 10, "/// PRIMARY ARRAY // 3 x 3 POOL GRID ///", C.cyan)

    -- The nine main array slots remain fixed and separate from auxiliary pools.
    local columns = 3
    local gap = 2
    local cardWidth = math.floor((width - 4 - gap * (columns - 1)) / columns)
    local firstX = math.floor((width - (cardWidth * columns + gap * (columns - 1))) / 2) + 1
    local firstY = 11

    for index = 1, CONFIG.expectedPools do
        local column = (index - 1) % columns
        local row = math.floor((index - 1) / columns)
        local x = firstX + column * (cardWidth + gap)
        local y = firstY + row * 5

        drawPoolCard(canvas, index, arrayPools[index], x, y, cardWidth)
    end

    -- Separate auxiliary groups. Extra transmitters never take a slot in the 3x3 array.
    writeRule(canvas, 27, "=", C.purple)
    writeCentered(canvas, 28, "/// AUXILIARY MANA SYSTEMS ///", C.purple)

    local panelGap = 3
    local panelWidth = math.floor((width - 4 - panelGap) / 2)
    local panelY = 29
    local panelX = 3
    local maxRows = math.max(1, height - 32)

    if height >= 34 and panelWidth >= 24 then
        drawAuxPanel(
            canvas,
            panelX,
            panelY,
            panelWidth,
            "ELVEN PORTAL",
            elvenPools,
            maxRows
        )

        drawAuxPanel(
            canvas,
            panelX + panelWidth + panelGap,
            panelY,
            panelWidth,
            "BASIC MATERIALS EXCHANGE",
            materialsPools,
            maxRows
        )
    else
        writeCentered(
            canvas,
            29,
            "ELVEN PORTAL: " .. #elvenPools .. "  |  MATERIALS EXCHANGE: " .. #materialsPools,
            C.purple
        )
    end

    local fullCount = 0
    local lowCount = 0
    local chargingCount = 0
    local drainingCount = 0

    local allPools = {}
    for _, pool in ipairs(arrayPools) do
        allPools[#allPools + 1] = pool
    end
    for _, pool in ipairs(elvenPools) do
        allPools[#allPools + 1] = pool
    end
    for _, pool in ipairs(materialsPools) do
        allPools[#allPools + 1] = pool
    end

    for _, pool in ipairs(allPools) do
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
    end

    local uptime = formatDuration((os.epoch("utc") - startedAt) / 1000)
    writeAt(
        canvas,
        3,
        height - 1,
        "FULL " .. fullCount .. "  LOW " .. lowCount
            .. "  CHG " .. chargingCount .. "  DRAIN " .. drainingCount,
        C.blue
    )
    writeRight(canvas, height - 1, width - 2, "UP " .. uptime .. " // RX ONLINE", C.green)
    writeAt(canvas, 1, height, "+" .. string.rep("=", width - 2) .. "+", C.border)

    renderCanvas(canvas)
end

print("POTATOCORE // MANA CORE")
print("Monitor: " .. CONFIG.monitorSide:upper())
print("Ender Modem: " .. CONFIG.modemSide:upper())
print("Display: 3x3 reactor dashboard")
print("Waiting for mana transmitters...")

drawDashboard()

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

        local group = message.group
        if group ~= "elven_portal" and group ~= "materials_exchange" then
            group = "array"
        end

        sources[senderId] = {
            group = group,
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

    -- Refresh only when a packet arrives or a transmitter expires.
    -- The row cache keeps unchanged monitor content untouched.
    if senderId or expired then
        drawDashboard()
    end
end
