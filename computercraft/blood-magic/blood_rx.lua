-- ============================================================
-- POTATOCORE // BLOOD ALTAR MONITOR
-- Remote Blood Magic altar dashboard.
--
-- Monitor PC:
--   5-wide x 4-tall monitor attached to BACK
--   Ender Modem attached to LEFT
--
-- Uses the same protocol as blood_tx.lua.
-- ============================================================

local CONFIG = {
    modemSide = "left",
    monitorSide = "back",
    protocol = "potatocore_blood_altar_v1",
    transmitterTimeout = 6,
    textScale = 1.5,
    receiveInterval = 0.5
}

if peripheral.getType(CONFIG.modemSide) ~= "modem" then
    error("Ender Modem not found on " .. CONFIG.modemSide:upper() .. "!")
end

if peripheral.getType(CONFIG.monitorSide) ~= "monitor" then
    print("Peripheral on BACK: " .. tostring(peripheral.getType(CONFIG.monitorSide)))
    error("Monitor not found on BACK. Check the monitor connection.")
end

local monitor = peripheral.wrap(CONFIG.monitorSide)
if not monitor then
    error("Could not wrap monitor on BACK.")
end

rednet.open(CONFIG.modemSide)

-- Some monitor peripherals/wrappers may not expose setTextScale.
-- Use 1.5 when available; otherwise continue with the monitor's current scale.
local scaleSupported = type(monitor.setTextScale) == "function"
if scaleSupported then
    local scaleOk, scaleError = pcall(monitor.setTextScale, CONFIG.textScale)
    if not scaleOk then
        printError("Could not set monitor scale: " .. tostring(scaleError))
        scaleSupported = false
    end
else
    printError("Monitor has no setTextScale method; keeping its current scale.")
end

local width, height = monitor.getSize()
local source
local lastError
local previousRows = {}
local previousProgress
local previousRecipe

local C = {
    background = colors.black,
    text = colors.white,
    muted = colors.gray,
    red = colors.red,
    orange = colors.orange,
    green = colors.lime,
    cyan = colors.cyan,
    purple = colors.purple,
    blue = colors.lightBlue
}

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
    value = math.floor(math.max(0, tonumber(value) or 0))
    local result = tostring(value)
    while true do
        local formatted, count = result:gsub("^(%d+)(%d%d%d)", "%1,%2")
        result = formatted
        if count == 0 then
            return result
        end
    end
end

local function addLine(lines, value, colour)
    if #lines < height then
        lines[#lines + 1] = {
            text = fit(value, width),
            colour = colour or C.text
        }
    end
end

local function addBar(lines, percent, colour)
    local barWidth = math.max(1, width - 4)
    local filled = math.floor(barWidth * math.max(0, math.min(100, percent)) / 100)
    local bar = "[" .. string.rep("#", filled) .. string.rep("-", barWidth - filled) .. "]"
    addLine(lines, bar, colour)
end

local function render(lines)
    for y = 1, height do
        local entry = lines[y] or { text = "", colour = C.text }
        local value = fit(entry.text, width)
        local key = value .. ":" .. tostring(entry.colour)

        if previousRows[y] ~= key then
            monitor.setCursorPos(1, y)
            monitor.setTextColor(entry.colour)
            monitor.setBackgroundColor(C.background)
            monitor.write(value .. string.rep(" ", math.max(0, width - #value)))
            previousRows[y] = key
        end
    end
end

local function dashboard()
    local lines = {}
    local altar = source and source.altar
    local online = altar ~= nil
        and os.epoch("utc") - source.seen <= CONFIG.transmitterTimeout * 1000

    addLine(lines, "POTATOCORE / HEMOCORE", C.red)
    addLine(lines, string.rep("=", width), C.red)

    if not online then
        addLine(lines, "ALTAR LINK OFFLINE", C.orange)
        addLine(lines, "Check altar PC", C.muted)
        if lastError then
            addLine(lines, fit(lastError, width), C.orange)
        end
        addLine(lines, "Waiting for telemetry", C.muted)
        render(lines)
        return
    end

    local stored = math.max(0, tonumber(altar.storedLP) or 0)
    local capacity = math.max(0, tonumber(altar.capacity) or 0)
    local tankPercent = capacity > 0 and stored / capacity * 100 or 0
    tankPercent = math.max(0, math.min(100, tankPercent))

    local progress = math.max(0, tonumber(altar.progress) or 0)
    local required = math.max(0, tonumber(altar.liquidRequired) or 0)
    local progressPercent = required > 0 and progress / required * 100 or 0
    progressPercent = math.max(0, math.min(100, progressPercent))

    local status = altar.active and "ACTIVE" or "STANDBY"
    local statusColour = altar.active and C.green or C.orange
    if altar.progressDecaying then
        status = "DECAYING"
        statusColour = C.orange
    elseif altar.active and progress > 0 then
        status = "CRAFTING"
        statusColour = C.cyan
    end

    addLine(lines, "TIER " .. tostring(altar.tier or "?") .. " / " .. status, statusColour)
    addLine(lines, string.rep("-", width), C.muted)
    addLine(lines, "LP TANK", C.purple)
    addLine(lines, number(stored) .. " / " .. number(capacity) .. " LP", C.text)
    addBar(lines, tankPercent, C.red)
    addLine(lines, string.format("%.1f%% STORED", tankPercent), C.text)
    addLine(lines, string.rep("-", width), C.muted)
    addLine(lines, "RECIPE PROGRESS", C.cyan)

    local item = tostring(altar.inputItem or "Empty")
    local count = tonumber(altar.inputCount) or 0
    addLine(lines, count > 0 and (item .. " x" .. count) or "No item in altar", C.text)
    addLine(lines, number(progress) .. " / " .. number(required) .. " LP", C.text)
    addBar(lines, progressPercent, altar.progressDecaying and C.orange or C.cyan)

    if altar.progressDecaying then
        addLine(lines, "!! PROGRESS DECAYING !!", C.orange)
    else
        addLine(lines, string.format("%.1f%% COMPLETE", progressPercent), C.cyan)
    end

    addLine(lines, "USE " .. tostring(altar.consumptionRate or 0)
        .. " / DRAIN " .. tostring(altar.drainRate or 0) .. " LP/T", C.orange)
    addLine(lines, "BUFFER " .. number(altar.totalCharge)
        .. "/" .. number(altar.maxCharge), C.blue)
    addLine(lines, "NODE " .. tostring(source.computer) .. " / LINK OK", C.green)

    render(lines)
end

print("POTATOCORE // BLOOD ALTAR MONITOR")
print("Monitor: BACK (" .. width .. "x" .. height .. ")")
print("Ender Modem: LEFT")
print("Text scale: " .. (scaleSupported and tostring(CONFIG.textScale) or "current"))
print("Protocol: " .. CONFIG.protocol)

monitor.setBackgroundColor(C.background)
monitor.setTextColor(C.text)
monitor.clear()
dashboard()

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
            lastError = nil
        elseif message.kind == "blood_altar_offline" then
            lastError = tostring(message.error or "Altar reader offline")
            if source then
                source.seen = 0
            end
        end

        dashboard()
    elseif source and os.epoch("utc") - source.seen > CONFIG.transmitterTimeout * 1000 then
        source = nil
        previousProgress = nil
        previousRecipe = nil
        dashboard()
    end
end
