-- ============================================================
-- POTATOCORE // FLUIX MANA THROUGHPUT
-- Project Infinity 0.1 | CC:Tweaked + Advanced Peripherals
--
-- Hardware:
--   - Computer directly connected to a Botania Mana Pool peripheral.
--   - Monitor directly connected to the computer.
--   - A monitor multiblock may extend to the right; CC:Tweaked
--     exposes the joined display as one monitor peripheral.
--   - No Ender Modem or Rednet required.
-- ============================================================

local CONFIG = {
    poolName = nil, -- Set to a peripheral name to force a specific pool.
    sampleInterval = 0.5,
    smoothingSamples = 4,
    textScale = 0.5
}

local COLORS = {
    background = colors.black,
    white = colors.white,
    muted = colors.gray,
    purple = colors.purple,
    cyan = colors.cyan,
    green = colors.lime,
    red = colors.red
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
            local pool = peripheral.wrap(name)
            if pool and type(pool.getMana) == "function" then
                return pool, name
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

local function centered(value)
    value = tostring(value)
    return math.max(1, math.floor((width - #value) / 2) + 1)
end

local function writeCentered(y, value, foreground, background)
    value = tostring(value)
    local x = centered(value)
    monitor.setCursorPos(x, y)
    monitor.setTextColor(foreground or COLORS.white)
    monitor.setBackgroundColor(background or COLORS.background)
    monitor.write(value)
end

local function writeAt(x, y, value, foreground, background)
    if y < 1 or y > height or x > width then
        return
    end

    monitor.setCursorPos(math.max(1, x), y)
    monitor.setTextColor(foreground or COLORS.white)
    monitor.setBackgroundColor(background or COLORS.background)
    monitor.write(tostring(value))
end

local function drawRule(y, colour)
    monitor.setCursorPos(1, y)
    monitor.setTextColor(colour or COLORS.purple)
    monitor.setBackgroundColor(COLORS.background)
    monitor.write(string.rep("-", width))
end

local function draw()
    monitor.setBackgroundColor(COLORS.background)
    monitor.setTextColor(COLORS.white)
    monitor.clear()

    local titleY = math.max(2, math.floor(height * 0.15))
    local valueY = math.max(titleY + 2, math.floor(height * 0.34))
    local unitY = valueY + 2
    local ruleY = unitY + 2
    local minuteY = ruleY + 2
    local hourY = minuteY + 2
    local footerY = height - 2

    writeCentered(titleY, "FLUIX MANA GENERATION", COLORS.purple)
    drawRule(titleY + 1, COLORS.purple)

    local rateText = (currentRate >= 0 and "+" or "-") .. compactNumber(currentRate)
    local valueColour = currentRate > 0 and COLORS.green
        or currentRate < 0 and COLORS.red
        or COLORS.muted

    local maxValueLength = math.max(8, math.min(width - 4, 24))
    if #rateText > maxValueLength then
        rateText = (currentRate >= 0 and "+" or "-") .. compactNumber(currentRate)
    end

    writeCentered(valueY, rateText, valueColour)
    writeCentered(unitY, "MANA / SECOND", COLORS.cyan)

    drawRule(ruleY, COLORS.purple)
    writeAt(3, minuteY, "PER MINUTE", COLORS.muted)
    local minuteText = compactNumber(currentRate * 60)
    writeAt(width - #minuteText - 2, minuteY, minuteText, COLORS.white)

    writeAt(3, hourY, "PER HOUR", COLORS.muted)
    local hourText = compactNumber(currentRate * 3600)
    writeAt(width - #hourText - 2, hourY, hourText, COLORS.white)

    drawRule(math.max(hourY + 2, footerY - 1), COLORS.purple)
    writeAt(3, footerY, "LIVE MONITORING", COLORS.cyan)
    local status = pool and "ACTIVE" or "OFFLINE"
    writeAt(width - #status - 2, footerY, status,
        pool and COLORS.green or COLORS.red)

    if height >= 30 then
        writeCentered(height - 4, "NET MANA FLOW", COLORS.muted)
    end
end

local function updateRate()
    local ok, mana = pcall(pool.getMana)
    if not ok or type(mana) ~= "number" then
        currentRate = 0
        previousMana = nil
        previousTime = nil
        return
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
print(" POTATOCORE // FLUIX MANA MONITOR")
print("========================================")
print("Pool        : " .. tostring(poolName))
print("Monitor     : " .. tostring(monitorName) .. " (" .. width .. "x" .. height .. ")")
print("Modem       : NOT REQUIRED")
print("Status      : ONLINE")
print("----------------------------------------")

monitor.clear()
while true do
    updateRate()
    draw()
    sleep(CONFIG.sampleInterval)
end
