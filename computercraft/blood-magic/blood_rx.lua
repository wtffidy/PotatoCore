-- ============================================================
-- POTATOCORE // BLOOD ALTAR MONITOR
-- Project Infinity 0.1 | Blood Magic 3.3.8-50
--
-- Monitor computer:
--   Ender Modem: LEFT (auto-discovered if moved)
--   Monitor: BACK (auto-discovered)
--
-- Uses colored capacity/progress bars and avoids setTextScale
-- unless the attached monitor actually exposes that method.
-- ============================================================

local CONFIG = {
    modemSide = "left",
    monitorSide = "back",
    protocol = "potatocore_blood_altar_v1",
    transmitterTimeout = 6,
    receiveInterval = 0.25,
    textScale = 1.5
}

local C = {
    black = colors.black,
    white = colors.white,
    muted = colors.gray,
    red = colors.red,
    orange = colors.orange,
    green = colors.lime,
    cyan = colors.cyan,
    purple = colors.purple,
    blue = colors.lightBlue,
    yellow = colors.yellow
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

local function findPeripheral(preferredSide, expectedType)
    if peripheral.isPresent(preferredSide) and hasType(preferredSide, expectedType) then
        return peripheral.wrap(preferredSide), preferredSide
    end

    for _, name in ipairs(peripheral.getNames()) do
        if hasType(name, expectedType) then
            return peripheral.wrap(name), name
        end
    end

    return nil, nil
end

local modem, modemSide = findPeripheral(CONFIG.modemSide, "modem")
if not modem then
    error("Ender Modem not found. Expected LEFT. Peripherals: " .. table.concat(peripheral.getNames(), ", "))
end

local monitor, monitorSide = findPeripheral(CONFIG.monitorSide, "monitor")
if not monitor then
    error("Monitor not found. Expected BACK or a connected monitor peripheral.")
end

rednet.open(modemSide)

-- Some monitor peripherals expose setTextScale and some wrappers do not.
-- Never assume the method exists: the previous script crashed here.
if type(monitor.setTextScale) == "function" then
    pcall(monitor.setTextScale, CONFIG.textScale)
end

local width, height = monitor.getSize()
if width < 24 or height < 12 then
    error("Monitor is too small: " .. width .. "x" .. height .. ". Use a larger monitor or smaller text scale.")
end

local source
local lastError
local previousProgress
local previousRecipe
local previousRows = {}

local function fit(value, limit)
    value = tostring(value or "")
    if #value <= limit then
        return value
    end
    if limit <= 3 then
        return value:sub(1, limit)
    end
    return value:sub(1, limit - 3) .. "..."
end

local function number(value)
    local result = tostring(math.floor(math.max(0, tonumber(value) or 0)))
    while true do
        local formatted, count = result:gsub("^(%d+)(%d%d%d)", "%1,%2")
        result = formatted
        if count == 0 then
            return result
        end
    end
end

local function compact(value)
    value = tonumber(value) or 0
    local absolute = math.abs(value)
    if absolute >= 1000000 then
        return string.format("%.2fM", value / 1000000)
    elseif absolute >= 1000 then
        return string.format("%.1fK", value / 1000)
    end
    return number(value)
end

local function makeCanvas()
    local canvas = { chars = {}, foreground = {}, background = {} }
    local fg = colors.toBlit(C.white)
    local bg = colors.toBlit(C.black)

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

    value = fit(value, math.max(0, width - x + 1))
    local fg = colors.toBlit(foreground or C.white)
    local bg = colors.toBlit(background or C.black)

    for index = 1, #value do
        local position = x + index - 1
        if position >= 1 and position <= width then
            canvas.chars[y][position] = value:sub(index, index)
            canvas.foreground[y][position] = fg
            canvas.background[y][position] = bg
        end
    end
end

local function centered(canvas, y, value, colour)
    value = tostring(value)
    writeAt(canvas, math.max(1, math.floor((width - #value) / 2) + 1), y, value, colour)
end

local function rule(canvas, y, colour)
    writeAt(canvas, 1, y, string.rep("-", width), colour or C.purple)
end

local function bar(canvas, y, percent, fillColour)
    if y < 1 or y > height then
        return
    end

    local barWidth = math.max(4, math.min(width - 8, width - 8))
    local x = 4
    local filled = math.floor(barWidth * math.max(0, math.min(100, percent)) / 100)
    writeAt(canvas, x, y, "[", C.muted)
    for offset = 0, barWidth - 1 do
        local position = x + 1 + offset
        local colour = offset < filled and fillColour or C.muted
        canvas.chars[y][position] = " "
        canvas.foreground[y][position] = colors.toBlit(colour)
        canvas.background[y][position] = colors.toBlit(colour)
    end
    writeAt(canvas, x + barWidth + 1, y, "]", C.muted)
end

local function render(canvas)
    for y = 1, height do
        local chars = table.concat(canvas.chars[y])
        local fg = table.concat(canvas.foreground[y])
        local bg = table.concat(canvas.background[y])
        local key = chars .. fg .. bg
        if previousRows[y] ~= key then
            monitor.setCursorPos(1, y)
            monitor.blit(chars, fg, bg)
            previousRows[y] = key
        end
    end
end

local function drawOffline()
    local canvas = makeCanvas()

    -- Compact layout for smaller joined monitors (for example 33x17).
    -- Keep every draw operation inside the available screen height.
    if height < 30 then
        centered(canvas, 1, "POTATOCORE  //  BLOOD MAGIC", C.red)
        rule(canvas, 2, C.purple)
        centered(canvas, 3, status, statusColour)
        local tierText = "TIER " .. tostring(altar.tier or "?")
        writeAt(canvas, math.max(3, width - #tierText - 2), 4, tierText, C.purple)

        rule(canvas, 5, C.purple)
        writeAt(canvas, 3, 6, "LIFE ESSENCE", C.red)
        local lpText = compact(stored) .. " / " .. compact(capacity) .. " LP"
        writeAt(canvas, 3, 7, lpText, C.white)
        local percentText = string.format("%.1f%%", tankPercent)
        writeAt(canvas, math.max(3, width - #percentText - 2), 7, percentText, C.green)
        bar(canvas, 8, tankPercent, C.red)

        rule(canvas, 9, C.purple)
        writeAt(canvas, 3, 10, "CURRENT RECIPE", C.cyan)
        local item = tostring(altar.inputItem or "Empty")
        local count = tonumber(altar.inputCount) or 0
        local itemText = count > 0 and (item .. " x" .. count) or "No item on altar"
        writeAt(canvas, 3, 11, itemText, C.yellow)

        writeAt(canvas, 3, 12, compact(progress) .. " / " .. compact(required) .. " LP", C.white)
        local progressLabel = string.format("%.1f%%", progressPercent)
        writeAt(canvas, math.max(3, width - #progressLabel - 2), 12, progressLabel, C.cyan)
        bar(canvas, 13, progressPercent, altar.progressDecaying and C.orange or C.cyan)

        writeAt(canvas, 3, 14, "LP USE: " .. tostring(altar.consumptionRate or 0) .. "/tick", C.orange)
        writeAt(canvas, 3, 15, "DRAIN: " .. tostring(altar.drainRate or 0) .. "/tick", C.orange)

        local footer = altar.progressDecaying and "WARNING: PROGRESS DECAYING"
            or (altar.readingDelayed and "BLOCK READER RETRYING" or "LIVE ALTAR TELEMETRY")
        centered(canvas, 17, footer, (altar.progressDecaying or altar.readingDelayed) and C.orange or C.muted)
        render(canvas)
        return
    end

    centered(canvas, 2, "POTATOCORE  //  BLOOD MAGIC", C.red)
    rule(canvas, 3, C.purple)
    centered(canvas, math.floor(height / 2) - 1, "ALTAR LINK OFFLINE", C.orange)
    centered(canvas, math.floor(height / 2) + 1, lastError or "Waiting for altar telemetry...", C.muted)
    centered(canvas, height - 2, "CHECK ALTAR PC + ENDER MODEM", C.muted)
    render(canvas)
end

local function drawDashboard()
    local altar = source and source.altar
    local online = altar ~= nil and os.epoch("utc") - source.seen <= CONFIG.transmitterTimeout * 1000
    if not online then
        drawOffline()
        return
    end

    local stored = math.max(0, tonumber(altar.storedLP) or 0)
    local capacity = math.max(0, tonumber(altar.capacity) or 0)
    local tankPercent = capacity > 0 and math.max(0, math.min(100, stored / capacity * 100)) or 0

    local progress = math.max(0, tonumber(altar.progress) or 0)
    local required = math.max(0, tonumber(altar.liquidRequired) or 0)
    local progressPercent = required > 0 and math.max(0, math.min(100, progress / required * 100)) or 0

    local status = altar.active and "ACTIVE" or "STANDBY"
    local statusColour = altar.active and C.green or C.orange
    if altar.progressDecaying then
        status = "PROGRESS DECAYING"
        statusColour = C.orange
    elseif altar.active and progress > 0 then
        status = "CRAFTING"
        statusColour = C.cyan
    end
    if altar.readingDelayed then
        status = "READER RETRY"
        statusColour = C.orange
    end

    local canvas = makeCanvas()
    centered(canvas, 2, "POTATOCORE  //  BLOOD MAGIC", C.red)
    rule(canvas, 3, C.purple)

    writeAt(canvas, 3, 5, "ALTAR STATUS", C.muted)
    local tierText = "TIER " .. tostring(altar.tier or "?")
    writeAt(canvas, math.max(3, width - #tierText - 2), 5, tierText, C.purple)
    centered(canvas, 6, status, statusColour)

    rule(canvas, 8, C.purple)
    writeAt(canvas, 3, 10, "LIFE ESSENCE", C.red)
    local lpText = compact(stored) .. " / " .. compact(capacity) .. " LP"
    writeAt(canvas, 3, 11, lpText, C.white)
    local percentText = string.format("%.1f%%", tankPercent)
    writeAt(canvas, math.max(3, width - #percentText - 2), 11, percentText, C.green)
    bar(canvas, 13, tankPercent, C.red)

    rule(canvas, 15, C.purple)
    writeAt(canvas, 3, 17, "CURRENT RECIPE", C.cyan)
    local item = tostring(altar.inputItem or "Empty")
    local count = tonumber(altar.inputCount) or 0
    local itemText = count > 0 and (item .. " x" .. count) or "No item on altar"
    writeAt(canvas, 3, 18, itemText, C.yellow)

    writeAt(canvas, 3, 20, compact(progress) .. " / " .. compact(required) .. " LP", C.white)
    local progressLabel = string.format("%.1f%%", progressPercent)
    writeAt(canvas, math.max(3, width - #progressLabel - 2), 20, progressLabel, C.cyan)
    bar(canvas, 22, progressPercent, altar.progressDecaying and C.orange or C.cyan)

    rule(canvas, 24, C.purple)
    writeAt(canvas, 3, 26, "LP USE", C.muted)
    writeAt(canvas, 12, 26, tostring(altar.consumptionRate or 0) .. " / tick", C.orange)
    writeAt(canvas, math.max(3, math.floor(width / 2) + 2), 26, "DRAIN", C.muted)
    writeAt(canvas, math.max(3, math.floor(width / 2) + 10), 26, tostring(altar.drainRate or 0) .. " / tick", C.orange)

    writeAt(canvas, 3, 28, "CHARGING RUNE BUFFER", C.muted)
    local bufferText = compact(altar.totalCharge) .. " / " .. compact(altar.maxCharge)
    writeAt(canvas, math.max(3, width - #bufferText - 2), 28, bufferText, C.blue)

    if altar.progressDecaying then
        centered(canvas, math.min(height - 2, 30), "WARNING: PROGRESS IS DECAYING", C.orange)
    elseif altar.readingDelayed then
        centered(canvas, math.min(height - 2, 30), "BLOCK READER RETRYING", C.orange)
    else
        centered(canvas, math.min(height - 2, 30), "LIVE TELEMETRY  //  0.25s UPDATES", C.muted)
    end

    render(canvas)
end

print("========================================")
print(" POTATOCORE // BLOOD MAGIC MONITOR")
print("========================================")
print("Monitor: " .. monitorSide .. " (" .. width .. "x" .. height .. ")")
print("Modem  : " .. modemSide)
print("Scale  : " .. (type(monitor.setTextScale) == "function" and tostring(CONFIG.textScale) or "monitor default"))
print("Protocol: " .. CONFIG.protocol)
monitor.setBackgroundColor(C.black)
monitor.setTextColor(C.white)
monitor.clear()
drawOffline()

while true do
    local senderId, message = rednet.receive(CONFIG.protocol, CONFIG.receiveInterval)

    if senderId and type(message) == "table" then
        if message.kind == "blood_altar" and type(message.altar) == "table" then
            local incoming = message.altar
            local recipeKey = tostring(incoming.inputItem) .. ":" .. tostring(incoming.inputCount)
                .. ":" .. tostring(incoming.liquidRequired)

            incoming.progressDecaying = false
            if previousRecipe == recipeKey and previousProgress ~= nil
                and incoming.active and (tonumber(incoming.progress) or 0) < previousProgress then
                incoming.progressDecaying = true
            end

            previousRecipe = recipeKey
            previousProgress = tonumber(incoming.progress) or 0
            source = {
                computer = senderId,
                altar = incoming,
                seen = os.epoch("utc")
            }
            lastError = incoming.readerError
        elseif message.kind == "blood_altar_offline" then
            lastError = tostring(message.error or "Altar reader offline")
        end

        drawDashboard()
    elseif source and os.epoch("utc") - source.seen > CONFIG.transmitterTimeout * 1000 then
        source = nil
        previousProgress = nil
        previousRecipe = nil
        drawOffline()
    end
end
