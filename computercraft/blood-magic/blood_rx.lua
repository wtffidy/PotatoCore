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
    textScale = 1.0,
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

-- Keep the font large on the 6x6 display. Fall back only if the
-- monitor cannot fit even the compact layout at scale 1.0.
if width < 32 or height < 18 then
    CONFIG.textScale = 0.8
    monitor.setTextScale(CONFIG.textScale)
    width, height = monitor.getSize()
end

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

    writeAt(canvas, 1, 1, "+" .. string.rep("=", width - 2) .. "+", C.border)
    center(canvas, 2, "POTATOCORE // BLOOD ALTAR CORE", C.red)
    center(canvas, 3, "LIFE ESSENCE MONITORING SYSTEM", C.purple)
    rule(canvas, 4, "=", C.border)

    if not online then
        if compactLayout then
            center(canvas, 2, "BLOOD ALTAR CORE", C.red)
            center(canvas, 5, "ALTAR LINK OFFLINE", C.orange)
            center(canvas, 7, "CHECK ALTAR TRANSMITTER", C.muted)
            if lastError then
                center(canvas, 9, fit(lastError, width - 4), C.orange)
            end
        else
            center(canvas, 7, "ALTAR LINK OFFLINE", C.orange)
            center(canvas, 9, "CHECK THE ALTAR TRANSMITTER", C.muted)
            if lastError then
                center(canvas, 11, fit(lastError, width - 4), C.orange)
            end
        end

        writeAt(canvas, 1, 1, "+" .. string.rep("=", width - 2) .. "+", C.border)
        writeAt(canvas, 1, height, "+" .. string.rep("=", width - 2) .. "+", C.border)
        render(canvas)
        return
    end

    local stored = altar.storedLP or 0
    local capacity = math.max(0, altar.capacity or 0)
    local percentage = capacity > 0 and stored / capacity * 100 or 0
    percentage = math.max(0, math.min(100, percentage))

    local status = altar.active and "ACTIVE" or "IDLE"
    local statusColour = altar.active and C.green or C.orange

    if altar.active and altar.progress > 0 then
        status = "CRAFTING"
        statusColour = C.cyan
    elseif not altar.active then
        status = "STANDBY"
        statusColour = C.orange
    end

    if compactLayout then
        writeAt(canvas, 1, 1, "+" .. string.rep("=", width - 2) .. "+", C.border)
        center(canvas, 2, "BLOOD ALTAR CORE", C.red)
        center(canvas, 3, "TIER " .. tostring(altar.tier or "UNKNOWN") .. "  |  " .. status, statusColour)
        rule(canvas, 4, "-", C.border)

        center(canvas, 5, "LIFE ESSENCE", C.purple)
        center(canvas, 6, formatNumber(stored) .. " / " .. formatNumber(capacity) .. " LP", C.white)

        local compactBarWidth = math.max(6, width - 6)
        local compactFilled = math.floor(compactBarWidth * percentage / 100)
        compactFilled = math.max(0, math.min(compactBarWidth, compactFilled))
        local compactBarX = math.floor((width - compactBarWidth - 2) / 2) + 1

        writeAt(canvas, compactBarX, 7, "[", C.border)
        writeAt(canvas, compactBarX + 1, 7, string.rep("#", compactFilled), C.red)
        writeAt(canvas, compactBarX + compactFilled + 1, 7, string.rep("-", compactBarWidth - compactFilled), C.muted)
        writeAt(canvas, compactBarX + compactBarWidth + 1, 7, "]", C.border)
        center(canvas, 8, string.format("%.1f%% STORED", percentage), C.white)

        rule(canvas, 9, "-", C.border)
        center(canvas, 10, "CRAFTING", C.cyan)

        local itemText = altar.inputCount > 0
            and (altar.inputItem .. " x" .. altar.inputCount)
            or "No item in altar"
        writeAt(canvas, 2, 11, "ITEM: " .. fit(itemText, width - 9), C.white)

        local required = math.max(0, (altar.liquidRequired or 0) * math.max(1, altar.inputCount or 0))
        local progress = math.max(0, altar.progress or 0)
        local progressPercent = required > 0 and math.min(100, progress / required * 100) or 0
        writeAt(
            canvas,
            2,
            12,
            "PROGRESS " .. formatNumber(progress) .. "/" .. formatNumber(required) .. " LP",
            C.white
        )

        local progressFilled = math.floor(compactBarWidth * progressPercent / 100)
        progressFilled = math.max(0, math.min(compactBarWidth, progressFilled))
        writeAt(canvas, compactBarX, 13, "[", C.border)
        writeAt(canvas, compactBarX + 1, 13, string.rep("#", progressFilled), C.cyan)
        writeAt(canvas, compactBarX + progressFilled + 1, 13, string.rep("-", compactBarWidth - progressFilled), C.muted)
        writeAt(canvas, compactBarX + compactBarWidth + 1, 13, "]", C.border)
        center(canvas, 14, string.format("%.1f%% COMPLETE", progressPercent), C.cyan)

        rule(canvas, 15, "-", C.border)
        center(canvas, 16, "ALTAR TELEMETRY", C.purple)
        writeAt(canvas, 2, 17, "USE: " .. tostring(altar.consumptionRate) .. " LP/TICK", C.orange)
        writeAt(canvas, 2, 18, "DRAIN: " .. tostring(altar.drainRate) .. " LP/TICK", C.orange)
        writeAt(
            canvas,
            2,
            19,
            "BUFFER: " .. formatNumber(altar.totalCharge) .. "/" .. formatNumber(altar.maxCharge),
            C.blue
        )
        if height >= 21 then
            writeAt(canvas, 2, 20, "CAP: " .. formatNumber(altar.bufferCapacity), C.blue)
        end

        writeAt(canvas, 1, height - 1, fit("POTATOCORE // BLOOD MAGIC", width - 2), C.red)
        writeAt(canvas, 1, height, "+" .. string.rep("=", width - 2) .. "+", C.border)
        render(canvas)
        return
    end

    writeAt(canvas, 3, 5, "[ALTAR] " .. status, statusColour)
    right(canvas, 5, width - 2, "[LINK] ONLINE // PC " .. source.computer, C.green)

    center(canvas, 7, "TIER " .. tostring(altar.tier or "UNKNOWN"), C.purple)

    local barWidth = math.max(10, width - 8)
    local filled = math.floor(barWidth * percentage / 100)
    filled = math.max(0, math.min(barWidth, filled))
    local barX = math.floor((width - barWidth - 2) / 2) + 1

    writeAt(canvas, barX, 9, "[", C.border)
    writeAt(canvas, barX + 1, 9, string.rep("#", filled), C.red)
    writeAt(canvas, barX + filled + 1, 9, string.rep("-", barWidth - filled), C.muted)
    writeAt(canvas, barX + barWidth + 1, 9, "]", C.border)

    center(
        canvas,
        10,
        "LIFE ESSENCE  " .. formatNumber(stored) .. " / " .. formatNumber(capacity)
            .. " LP  [" .. string.format("%.1f", percentage) .. "%]",
        C.white
    )

    rule(canvas, 12, "-", C.border)
    center(canvas, 13, "CRAFTING OPERATIONS", C.cyan)

    local itemText = altar.inputCount > 0
        and (altar.inputItem .. " x" .. altar.inputCount)
        or "No item in altar"
    writeAt(canvas, 3, 15, "INPUT: " .. fit(itemText, width - 10), C.white)

    local required = math.max(0, (altar.liquidRequired or 0) * math.max(1, altar.inputCount or 0))
    local progress = math.max(0, altar.progress or 0)
    local progressPercent = required > 0 and math.min(100, progress / required * 100) or 0

    writeAt(
        canvas,
        3,
        17,
        "PROGRESS: " .. formatNumber(progress) .. " / " .. formatNumber(required)
            .. " LP  [" .. string.format("%.1f", progressPercent) .. "%]",
        C.white
    )

    local progressWidth = math.max(10, width - 8)
    local progressFilled = math.floor(progressWidth * progressPercent / 100)
    local progressX = math.floor((width - progressWidth - 2) / 2) + 1

    writeAt(canvas, progressX, 18, "[", C.border)
    writeAt(canvas, progressX + 1, 18, string.rep("#", progressFilled), C.cyan)
    writeAt(
        canvas,
        progressX + progressFilled + 1,
        18,
        string.rep("-", progressWidth - progressFilled),
        C.muted
    )
    writeAt(canvas, progressX + progressWidth + 1, 18, "]", C.border)

    rule(canvas, 20, "-", C.border)
    center(canvas, 21, "ALTAR TELEMETRY", C.purple)

    writeAt(canvas, 3, 23, "CONSUMPTION: " .. tostring(altar.consumptionRate) .. " LP/TICK", C.orange)
    writeAt(canvas, 3, 24, "DRAIN RATE: " .. tostring(altar.drainRate) .. " LP/TICK", C.orange)

    writeAt(
        canvas,
        3,
        26,
        "CHARGING BUFFER: " .. formatNumber(altar.totalCharge)
            .. " / " .. formatNumber(altar.maxCharge),
        C.blue
    )

    writeAt(
        canvas,
        3,
        27,
        "BUFFER CAPACITY: " .. formatNumber(altar.bufferCapacity),
        C.blue
    )

    local uptime = formatDuration((os.epoch("utc") - (source.seen or os.epoch("utc"))) / 1000)
    right(canvas, height - 1, width - 2, "SIGNAL ONLINE", C.green)
    writeAt(canvas, 3, height - 1, "POTATOCORE // BLOOD MAGIC", C.red)
    writeAt(canvas, 1, height, "+" .. string.rep("=", width - 2) .. "+", C.border)

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
            source = {
                computer = senderId,
                altar = message.altar,
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
