-- ============================================================
-- POTATOCORE // BLOOD ALTAR MONITOR
-- Remote Blood Magic altar dashboard.
--
-- Monitor computer hardware:
--   Monitor: TOP
--   Ender Modem: BOTTOM
--
-- Receives telemetry from blood_tx.lua over Ender Modem.
-- Cached row rendering prevents full-screen flicker.
-- ============================================================

local CONFIG = {
    modemSide = "bottom",
    monitorSide = "top",
    protocol = "potatocore_blood_altar_v1",
    transmitterTimeout = 6,
    textScale = 1.5,
    receiveInterval = 0.5
}

if peripheral.getType(CONFIG.modemSide) ~= "modem" then
    error("Ender Modem not found on " .. CONFIG.modemSide:upper() .. "!")
end

local monitor = peripheral.wrap(CONFIG.monitorSide)
if not monitor then
    error("Monitor not found on " .. CONFIG.monitorSide:upper() .. "!")
end

rednet.open(CONFIG.modemSide)
monitor.setTextScale(CONFIG.textScale)

local width, height = monitor.getSize()

-- Grandpa Mode MAX: keep the requested 3.0 font scale.
-- The dashboard switches to a minimal layout instead of shrinking text.
local ultraCompactLayout = width < 36 or height < 22
local compactLayout = width < 58 or height < 30

local C = {
    background = colors.black,
    white = colors.white,
    muted = colors.gray,
    border = colors.red,
    red = colors.red,
    orange = colors.orange,
    green = colors.lime,
    cyan = colors.cyan,
    blue = colors.lightBlue,
    purple = colors.purple
}

local source = nil
local lastError = nil
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
    value = tostring(value or "")
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

    local fg = colors.toBlit(C.white)
    local bg = colors.toBlit(C.background)

    for y = 1, height do
        canvas.chars[y] = {}
        canvas.foreground[y] = {}
        canvas.background[y] = {}

        for x = 1, width do
            canvas.chars[y][x] = " "
            canvas.foreground[y][x] = fg
            canvas.background[y][x] = bg
        end
    end

    return canvas
end

local function writeAt(canvas, x, y, value, foreground, background)
    if y < 1 or y > height or x > width then
        return
    end

    value = tostring(value or "")
    local fg = colors.toBlit(foreground or C.white)
    local bg = colors.toBlit(background or C.background)

    for index = 1, #value do
        local position = x + index - 1
        if position >= 1 and position <= width then
            canvas.chars[y][position] = value:sub(index, index)
            canvas.foreground[y][position] = fg
            canvas.background[y][position] = bg
        end
    end
end

local function center(canvas, y, value, colour)
    value = tostring(value)
    writeAt(canvas, math.floor((width - #value) / 2) + 1, y, value, colour)
end

local function right(canvas, y, x, value, colour)
    value = tostring(value)
    writeAt(canvas, x - #value + 1, y, value, colour)
end

local function rule(canvas, y, char, colour)
    writeAt(canvas, 1, y, string.rep(char, width), colour)
end

local function render(canvas)
    for y = 1, height do
        local chars = table.concat(canvas.chars[y])
        local fg = table.concat(canvas.foreground[y])
        local bg = table.concat(canvas.background[y])
        local key = chars .. fg .. bg

        if renderedRows[y] ~= key then
            monitor.setCursorPos(1, y)
            monitor.blit(chars, fg, bg)
            renderedRows[y] = key
        end
    end
end

local function drawDashboard()
    local canvas = newCanvas()
    local altar = source and source.altar or nil
    local online = altar ~= nil
        and os.epoch("utc") - source.seen <= CONFIG.transmitterTimeout * 1000

    local function fittedCenter(y, value, colour)
        center(canvas, y, fit(value, math.max(1, width - 2)), colour)
    end

    local function drawBar(y, percent, colour)
        local barWidth = math.max(1, width - 6)
        local filled = math.floor(barWidth * percent / 100)
        filled = math.max(0, math.min(barWidth, filled))
        local x = math.max(1, math.floor((width - barWidth - 2) / 2) + 1)

        writeAt(canvas, x, y, "[", C.border)
        writeAt(canvas, x + 1, y, string.rep("#", filled), colour)
        writeAt(canvas, x + filled + 1, y, string.rep("-", barWidth - filled), C.muted)
        writeAt(canvas, x + barWidth + 1, y, "]", C.border)
    end

    writeAt(canvas, 1, 1, "+" .. string.rep("=", math.max(0, width - 2)) .. "+", C.border)

    if not online then
        fittedCenter(2, "POTATOCORE // HEMOCORE", C.red)
        rule(canvas, 4, "-", C.border)
        fittedCenter(6, "ALTAR LINK OFFLINE", C.orange)
        fittedCenter(8, "CHECK TRANSMITTER", C.muted)

        if lastError then
            fittedCenter(10, lastError, C.orange)
        end

        if height >= 12 then
            fittedCenter(height - 1, "WAITING FOR ALTAR", C.muted)
        end

        writeAt(canvas, 1, height, "+" .. string.rep("=", math.max(0, width - 2)) .. "+", C.border)
        render(canvas)
        return
    end

    local stored = math.max(0, altar.storedLP or 0)
    local capacity = math.max(0, altar.capacity or 0)
    local percentage = capacity > 0 and stored / capacity * 100 or 0
    percentage = math.max(0, math.min(100, percentage))

    local required = math.max(0, (altar.liquidRequired or 0) * math.max(0, altar.inputCount or 0))
    local progress = math.max(0, altar.progress or 0)
    local progressPercent = required > 0 and math.min(100, progress / required * 100) or 0

    local status = altar.active and "ACTIVE" or "STANDBY"
    local statusColour = altar.active and C.green or C.orange

    if altar.progressDecaying then
        status = "DECAYING"
        statusColour = C.orange
    elseif altar.active and altar.progress > 0 then
        status = "CRAFTING"
        statusColour = C.cyan
    end

    -- Grandpa Mode layout: large font, short labels, essential information first.
    if ultraCompactLayout then
        fittedCenter(2, "POTATOCORE / HEMOCORE", C.red)
        fittedCenter(3, "TIER " .. tostring(altar.tier or "?") .. " // " .. status, statusColour)
        rule(canvas, 4, "=", C.border)

        fittedCenter(5, "LP TANK", C.purple)
        fittedCenter(6, formatNumber(stored) .. "/" .. formatNumber(capacity), C.white)
        drawBar(7, percentage, C.red)
        fittedCenter(8, string.format("%.1f%% STORED", percentage), C.white)

        rule(canvas, 9, "-", C.border)
        fittedCenter(10, "RECIPE PROGRESS", C.cyan)

        local itemText = altar.inputCount > 0
            and (altar.inputItem .. " x" .. altar.inputCount)
            or "NO INPUT"
        fittedCenter(11, "IN: " .. itemText, C.white)
        fittedCenter(
            12,
            formatNumber(progress) .. "/" .. formatNumber(required) .. " LP",
            C.white
        )
        drawBar(13, progressPercent, altar.progressDecaying and C.orange or C.cyan)

        local progressLabel = altar.progressDecaying and "!! DECAYING !!"
            or string.format("%.1f%% COMPLETE", progressPercent)
        fittedCenter(14, progressLabel, altar.progressDecaying and C.orange or C.cyan)

        rule(canvas, 15, "-", C.border)
        fittedCenter(16, "ALTAR SYSTEMS", C.purple)
        fittedCenter(
            17,
            "USE " .. tostring(altar.consumptionRate) .. " / DRAIN " .. tostring(altar.drainRate),
            C.orange
        )
        fittedCenter(
            18,
            "BUFFER " .. formatNumber(altar.totalCharge) .. "/" .. formatNumber(altar.maxCharge),
            C.blue
        )

        if height >= 20 then
            fittedCenter(19, "NODE " .. tostring(source.computer) .. " // LINK OK", C.green)
        end
        if height >= 21 then
            fittedCenter(height - 1, "BLOOD MAGIC ONLINE", C.red)
        end

        writeAt(canvas, 1, height, "+" .. string.rep("=", math.max(0, width - 2)) .. "+", C.border)
        render(canvas)
        return
    end

    -- Compact / full layouts retain the same visual hierarchy.
    fittedCenter(2, "POTATOCORE // HEMOCORE", C.red)
    fittedCenter(3, "BLOOD ALTAR // TIER " .. tostring(altar.tier or "?"), C.purple)
    rule(canvas, 4, "=", C.border)

    writeAt(canvas, 3, 5, "STATUS: " .. status, statusColour)
    right(canvas, 5, width - 2, "NODE " .. tostring(source.computer), C.green)

    fittedCenter(7, "LP TANK", C.purple)
    fittedCenter(
        8,
        formatNumber(stored) .. " / " .. formatNumber(capacity) .. " LP",
        C.white
    )
    drawBar(9, percentage, C.red)
    fittedCenter(10, string.format("%.1f%% STORED", percentage), C.white)

    rule(canvas, 12, "-", C.border)
    fittedCenter(13, "RECIPE PROGRESS", C.cyan)

    local itemText = altar.inputCount > 0
        and (altar.inputItem .. " x" .. altar.inputCount)
        or "No item in altar"
    writeAt(canvas, 3, 15, "INPUT: " .. fit(itemText, width - 10), C.white)

    writeAt(
        canvas,
        3,
        17,
        "PROGRESS: " .. formatNumber(progress) .. " / " .. formatNumber(required) .. " LP",
        C.white
    )
    drawBar(18, progressPercent, altar.progressDecaying and C.orange or C.cyan)
    fittedCenter(
        19,
        altar.progressDecaying and "!! PROGRESS DECAYING !!"
            or string.format("%.1f%% COMPLETE", progressPercent),
        altar.progressDecaying and C.orange or C.cyan
    )

    rule(canvas, 21, "-", C.border)
    fittedCenter(22, "ALTAR SYSTEMS", C.purple)
    writeAt(canvas, 3, 24, "USE: " .. tostring(altar.consumptionRate) .. " LP/TICK", C.orange)
    writeAt(canvas, 3, 25, "DRAIN: " .. tostring(altar.drainRate) .. " LP/TICK", C.orange)
    writeAt(
        canvas,
        3,
        27,
        "BUFFER: " .. formatNumber(altar.totalCharge) .. "/" .. formatNumber(altar.maxCharge),
        C.blue
    )

    right(canvas, height - 1, width - 2, "SIGNAL ONLINE", C.green)
    writeAt(canvas, 3, height - 1, "POTATOCORE // BLOOD MAGIC", C.red)
    writeAt(canvas, 1, height, "+" .. string.rep("=", math.max(0, width - 2)) .. "+", C.border)

    render(canvas)
end

print("POTATOCORE // BLOOD ALTAR MONITOR")
print("Monitor: " .. CONFIG.monitorSide:upper())
print("Ender Modem: " .. CONFIG.modemSide:upper())
print("Protocol: " .. CONFIG.protocol)
print("Waiting for altar transmitter...")

drawDashboard()

while true do
    local senderId, message = rednet.receive(CONFIG.protocol, CONFIG.receiveInterval)

    if senderId and type(message) == "table" then
        if message.kind == "blood_altar" and type(message.altar) == "table" then
            local incomingAltar = message.altar
            local previousAltar = source and source.altar or nil

            local sameRecipe = previousAltar ~= nil
                and previousAltar.inputItem == incomingAltar.inputItem
                and previousAltar.inputCount == incomingAltar.inputCount
                and previousAltar.liquidRequired == incomingAltar.liquidRequired

            incomingAltar.progressDecaying = false

            if sameRecipe and previousAltar.active and incomingAltar.active then
                if (incomingAltar.progress or 0) < (previousAltar.progress or 0) then
                    incomingAltar.progressDecaying = true
                elseif (incomingAltar.progress or 0) == (previousAltar.progress or 0) then
                    incomingAltar.progressDecaying = previousAltar.progressDecaying == true
                end
            end

            source = {
                computer = senderId,
                altar = incomingAltar,
                seen = os.epoch("utc")
            }
            lastError = nil
        elseif message.kind == "blood_altar_offline" then
            lastError = tostring(message.error or "Altar reader offline")
            if source then
                source.seen = 0
            end
        end

        drawDashboard()
    elseif source and os.epoch("utc") - source.seen > CONFIG.transmitterTimeout * 1000 then
        source = nil
        drawDashboard()
    end
end
