-- ============================================================
-- POTATOCORE // FLUIX MANA DASHBOARD
-- Project Infinity 0.1 | CC:Tweaked + Advanced Peripherals
--
-- Hardware:
--   - Computer directly connected to a Botania Mana Pool peripheral.
--   - Monitor directly connected to the computer.
--   - A monitor multiblock extending right is detected as one display.
--   - No modem or Rednet required.
-- ============================================================

local CONFIG = {
    poolName = nil, -- Set to a peripheral name to force a specific pool.
    sampleInterval = 0.5,
    smoothingSamples = 8,
    textScale = 0.5
}

local COLORS = {
    background = colors.black,
    white = colors.white,
    muted = colors.gray,
    purple = colors.purple,
    cyan = colors.cyan,
    green = colors.lime,
    red = colors.red,
    yellow = colors.yellow,
    barEmpty = colors.gray
}

local function findManaPool()
    if CONFIG.poolName then
        if peripheral.getType(CONFIG.poolName) == "manaPool" then
            return peripheral.wrap(CONFIG.poolName), CONFIG.poolName
        end
        return nil, CONFIG.poolName
    end

    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "manaPool" then
            local candidate = peripheral.wrap(name)
            if candidate and type(candidate.getMana) == "function" then
                return candidate, name
            end
        end
    end

    return nil, nil
end

local monitor, monitorName = peripheral.find("monitor")
if not monitor or type(monitor.setTextScale) ~= "function" then
    error("No directly connected monitor found.")
end

monitor.setTextScale(CONFIG.textScale)

local pool, poolName = findManaPool()
if not pool then
    error("No Mana Pool peripheral found. Connect the computer directly to the pool.")
end

if type(pool.getMana) ~= "function" then
    error("Mana Pool peripheral does not provide getMana().")
end

local width, height = monitor.getSize()
local samples = {}
local sampleIndex = 1
local sampleCount = 0
local previousMana = nil
local previousTime = nil
local currentRate = 0
local currentMana = 0
local maxMana = nil
local manaNeeded = nil
local poolEmpty = nil
local poolFull = nil
local chargeMode = nil
local hasItems = nil
local poolItems = nil
local readError = nil

local function callPool(method)
    if type(pool[method]) ~= "function" then
        return nil
    end

    local ok, result = pcall(pool[method])
    if ok then
        return result
    end

    return nil
end

local function formatNumber(value)
    local number = math.floor(math.abs(value) + 0.5)
    local result = tostring(number)

    while true do
        local formatted, count = result:gsub("^(%d+)(%d%d%d)", "%1,%2")
        result = formatted
        if count == 0 then
            break
        end
    end

    return result
end

local function compactNumber(value)
    local absolute = math.abs(value)
    if absolute >= 1000000000 then
        return string.format("%.2fB", value / 1000000000)
    elseif absolute >= 1000000 then
        return string.format("%.2fM", value / 1000000)
    elseif absolute >= 1000 then
        return string.format("%.1fK", value / 1000)
    end

    return formatNumber(value)
end

local function formatDuration(seconds)
    if not seconds or seconds < 0 or seconds == math.huge then
        return "N/A"
    end

    seconds = math.floor(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local remaining = seconds % 60

    if hours > 0 then
        return string.format("%dh %02dm", hours, minutes)
    elseif minutes > 0 then
        return string.format("%dm %02ds", minutes, remaining)
    end

    return string.format("%ds", remaining)
end

local function writeAt(x, y, value, foreground, background)
    if y < 1 or y > height or x > width then
        return
    end

    value = tostring(value)
    value = value:sub(1, math.max(0, width - x + 1))
    monitor.setCursorPos(math.max(1, x), y)
    monitor.setTextColor(foreground or COLORS.white)
    monitor.setBackgroundColor(background or COLORS.background)
    monitor.write(value)
end

local function writeCentered(y, value, foreground)
    value = tostring(value)
    local x = math.max(1, math.floor((width - #value) / 2) + 1)
    writeAt(x, y, value, foreground)
end

local function drawRule(y, colour)
    if y < 1 or y > height then
        return
    end

    monitor.setCursorPos(1, y)
    monitor.setTextColor(colour or COLORS.purple)
    monitor.setBackgroundColor(COLORS.background)
    monitor.write(string.rep("-", width))
end

local function drawBar(x, y, barWidth, ratio)
    if y < 1 or y > height or barWidth < 3 then
        return
    end

    ratio = math.max(0, math.min(1, ratio or 0))
    local innerWidth = barWidth - 2
    local filled = math.floor(innerWidth * ratio)

    writeAt(x, y, "[", COLORS.muted)
    monitor.setCursorPos(x + 1, y)
    monitor.setBackgroundColor(COLORS.barEmpty)
    monitor.setTextColor(COLORS.barEmpty)
    monitor.write(string.rep(" ", innerWidth))

    if filled > 0 then
        monitor.setCursorPos(x + 1, y)
        monitor.setBackgroundColor(COLORS.green)
        monitor.setTextColor(COLORS.green)
        monitor.write(string.rep(" ", filled))
    end

    writeAt(x + barWidth - 1, y, "]", COLORS.muted)
    monitor.setBackgroundColor(COLORS.background)
end

local function getPoolStatus()
    if readError then
        return "READ ERROR", COLORS.red
    elseif poolFull then
        return "FULL", COLORS.cyan
    elseif poolEmpty then
        return "EMPTY", COLORS.yellow
    elseif currentRate > 0 then
        return "RECEIVING MANA", COLORS.green
    elseif currentRate < 0 then
        return "DRAINING MANA", COLORS.yellow
    end

    return "STANDBY", COLORS.muted
end

local function draw()
    monitor.setBackgroundColor(COLORS.background)
    monitor.setTextColor(COLORS.white)
    monitor.clear()

    local titleY = 2
    local statusY = 4
    local manaY = 7
    local barY = 9
    local rateY = 12
    local rateDetailY = 14
    local capacityY = 17
    local modeY = 20
    local footerY = height - 2

    writeCentered(titleY, "POTATOCORE  //  FLUIX MANA", COLORS.purple)
    drawRule(3, COLORS.purple)

    local status, statusColour = getPoolStatus()
    writeAt(3, statusY, "POOL STATUS", COLORS.muted)
    writeAt(width - #status - 2, statusY, status, statusColour)

    writeAt(3, manaY, "STORED MANA", COLORS.cyan)
    local manaText = compactNumber(currentMana)
    local capacityText = maxMana and compactNumber(maxMana) or "UNKNOWN"
    writeAt(3, manaY + 1, manaText .. " / " .. capacityText, COLORS.white)

    local fillRatio = maxMana and maxMana > 0 and currentMana / maxMana or 0
    local percentText = maxMana and string.format("%.2f%%", fillRatio * 100) or "N/A"
    writeAt(width - #percentText - 2, manaY + 1, percentText, COLORS.green)

    local barWidth = math.max(8, width - 6)
    drawBar(3, barY, barWidth, fillRatio)

    drawRule(11, COLORS.purple)
    writeAt(3, rateY, "NET FLOW", COLORS.muted)
    local rateColour = currentRate > 0 and COLORS.green
        or currentRate < 0 and COLORS.red
        or COLORS.white
    local rateText = (currentRate > 0 and "+" or "") .. compactNumber(currentRate) .. " mana/s"
    writeAt(width - #rateText - 2, rateY, rateText, rateColour)

    writeAt(3, rateDetailY, "PER MINUTE", COLORS.muted)
    local minuteText = (currentRate > 0 and "+" or "") .. compactNumber(currentRate * 60)
    writeAt(width - #minuteText - 2, rateDetailY, minuteText, rateColour)

    writeAt(3, rateDetailY + 1, "PER HOUR", COLORS.muted)
    local hourText = (currentRate > 0 and "+" or "") .. compactNumber(currentRate * 3600)
    writeAt(width - #hourText - 2, rateDetailY + 1, hourText, rateColour)

    drawRule(16, COLORS.purple)
    writeAt(3, capacityY, "CAPACITY LEFT", COLORS.muted)
    writeAt(width - #(manaNeeded and compactNumber(manaNeeded) or "N/A") - 2, capacityY,
        manaNeeded and compactNumber(manaNeeded) or "N/A", COLORS.white)

    local estimate = "N/A"
    if currentRate > 0 and manaNeeded and manaNeeded > 0 then
        estimate = formatDuration(manaNeeded / currentRate)
    elseif poolFull then
        estimate = "FULL"
    end
    writeAt(3, capacityY + 1, "TIME TO FULL", COLORS.muted)
    writeAt(width - #estimate - 2, capacityY + 1, estimate, COLORS.cyan)

    local drainEstimate = "N/A"
    if currentRate < 0 and currentMana > 0 then
        drainEstimate = formatDuration(currentMana / math.abs(currentRate))
    elseif poolEmpty then
        drainEstimate = "EMPTY"
    end
    writeAt(3, capacityY + 2, "TIME TO EMPTY", COLORS.muted)
    writeAt(width - #drainEstimate - 2, capacityY + 2, drainEstimate, COLORS.yellow)

    drawRule(21, COLORS.purple)
    writeAt(3, modeY, "POOL MODE", COLORS.muted)
    local modeText = chargeMode == nil and "NOT REPORTED"
        or (chargeMode and "CHARGE ITEMS" or "MANA STORAGE")
    writeAt(width - #modeText - 2, modeY, modeText, COLORS.white)

    writeAt(3, modeY + 1, "ITEM ON POOL", COLORS.muted)
    local itemText = hasItems == nil and "NOT REPORTED"
        or (hasItems and "YES" or "NO")
    writeAt(width - #itemText - 2, modeY + 1, itemText,
        hasItems and COLORS.green or COLORS.muted)

    if poolItems and type(poolItems) == "table" and #poolItems > 0 then
        local item = poolItems[1]
        local itemName = type(item) == "table" and (item.displayName or item.name or item.id) or tostring(item)
        if itemName then
            writeAt(3, modeY + 2, "POOL ITEM: " .. tostring(itemName), COLORS.cyan)
        end
    end

    drawRule(footerY - 1, COLORS.purple)
    writeAt(3, footerY, "POOL: " .. tostring(poolName), COLORS.muted)
    local sampleText = "AVG " .. tostring(sampleCount) .. "/" .. tostring(CONFIG.smoothingSamples)
    writeAt(width - #sampleText - 2, footerY, sampleText, COLORS.cyan)

    if height >= 30 then
        writeCentered(height - 4, "LIVE TELEMETRY  //  " .. tostring(CONFIG.sampleInterval) .. "s REFRESH", COLORS.muted)
    end
end

local function updateStats()
    local ok, mana = pcall(pool.getMana)
    if not ok or type(mana) ~= "number" then
        readError = true
        currentRate = 0
        previousMana = nil
        previousTime = nil
        return
    end

    readError = false
    currentMana = mana
    maxMana = callPool("getMaxMana")
    manaNeeded = callPool("getManaNeeded")

    if type(maxMana) ~= "number" and type(manaNeeded) == "number" then
        maxMana = mana + manaNeeded
    end
    if type(manaNeeded) ~= "number" and type(maxMana) == "number" then
        manaNeeded = math.max(0, maxMana - mana)
    end

    poolEmpty = callPool("isEmpty")
    poolFull = callPool("isFull")
    chargeMode = callPool("canChargeItem")
    hasItems = callPool("hasItems")
    poolItems = callPool("getItems")

    if type(maxMana) == "number" then
        poolEmpty = poolEmpty == nil and mana <= 0 or poolEmpty
        poolFull = poolFull == nil and mana >= maxMana or poolFull
    end

    local now = os.epoch("utc")
    if previousMana ~= nil and previousTime ~= nil then
        local elapsed = (now - previousTime) / 1000
        if elapsed > 0 then
            local rate = (mana - previousMana) / elapsed
            samples[sampleIndex] = rate
            sampleIndex = sampleIndex % CONFIG.smoothingSamples + 1
            sampleCount = math.min(sampleCount + 1, CONFIG.smoothingSamples)

            local total = 0
            for index = 1, sampleCount do
                total = total + samples[index]
            end
            currentRate = total / sampleCount
        end
    end

    previousMana = mana
    previousTime = now
end

print("========================================")
print(" POTATOCORE // FLUIX MANA DASHBOARD")
print("========================================")
print("Pool        : " .. tostring(poolName))
print("Monitor     : " .. tostring(monitorName) .. " (" .. width .. "x" .. height .. ")")
print("Modem       : NOT REQUIRED")
print("Status      : ONLINE")
print("----------------------------------------")

monitor.clear()
while true do
    updateStats()
    draw()
    sleep(CONFIG.sampleInterval)
end
