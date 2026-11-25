-- ============================================================
-- POTATOCORE // BOTANIA PRODUCTION LINE
-- Dedicated 6x6 production dashboard.
--
-- Hardware on THIS monitor computer:
--   TOP = Wired Modem
--   Monitor = connected to this computer or its wired network
--
-- Seven Block Readers connect through the same wired modem
-- network. Each reader sits above its machine and faces DOWN.
--
-- This is separate from the existing Mana Core receiver.
-- ============================================================

local CONFIG = {
    modemSide = "top",
    textScale = 0.5,
    refreshInterval = 2,
    diagnosticInterval = 10,
    diagnosticFile = "botania_data.txt"
}

local modemType = peripheral.getType(CONFIG.modemSide)
if modemType ~= "modem" then
    error("Wired modem not found on " .. CONFIG.modemSide:upper() .. "!")
end

local monitor = peripheral.find("monitor")
if not monitor then
    error("Botania monitor not found on the wired modem network!")
end

monitor.setTextScale(CONFIG.textScale)

local width, height = monitor.getSize()
if width < 70 or height < 49 then
    error(
        "Botania display needs more space. Detected "
        .. width .. "x" .. height .. "; need at least 70x49."
    )
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
    purple = colors.purple,
    yellow = colors.yellow
}

local renderedRows = {}
local lastDiagnostic = 0
local startedAt = os.epoch("utc")

local MACHINES = {
    { id = "industrial_agglomeration_factory", label = "INDUSTRIAL AGGLOMERATION FACTORY" },
    { id = "alfheim_market", label = "ALFHEIM MARKET" },
    { id = "mechanical_mana_pool", label = "MECHANICAL MANA POOL" },
    { id = "mechanical_runic_altar", label = "MECHANICAL RUNIC ALTAR" },
    { id = "mechanical_apothecary", label = "MECHANICAL APOTHECARY" },
    { id = "mechanical_daisy", label = "MECHANICAL DAISY // 01" },
    { id = "mechanical_daisy", label = "MECHANICAL DAISY // 02" }
}

monitor.setBackgroundColor(C.background)
monitor.setTextColor(C.white)
monitor.clear()

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

local function formatDuration(seconds)
    seconds = math.max(0, math.floor(seconds))

    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local remainder = seconds % 60

    if hours > 0 then
        return hours .. "h " .. minutes .. "m"
    elseif minutes > 0 then
        return minutes .. "m " .. remainder .. "s"
    end

    return remainder .. "s"
end

local function safeCall(object, method)
    if not object or type(object[method]) ~= "function" then
        return nil
    end

    local ok, result = pcall(object[method])
    if ok then
        return result
    end

    return nil
end

local function isBlockReader(name)
    local peripheralType = peripheral.getType(name)
    return peripheralType == "blockReader" or peripheralType == "block_reader"
end

local function classify(blockName)
    local id = tostring(blockName or ""):lower()

    if id:find("industrial_agglomeration_factory", 1, true)
        or id:find("industrial_agglomeration", 1, true) then
        return "industrial_agglomeration_factory"
    elseif id:find("alfheim_market", 1, true) then
        return "alfheim_market"
    elseif id:find("mechanical_mana_pool", 1, true) then
        return "mechanical_mana_pool"
    elseif id:find("mechanical_runic_altar", 1, true) then
        return "mechanical_runic_altar"
    elseif id:find("mechanical_apothecary", 1, true) then
        return "mechanical_apothecary"
    elseif id:find("mechanical_daisy", 1, true) then
        return "mechanical_daisy"
    end

    return nil
end

local function scanReaders()
    local readers = {}

    for _, name in ipairs(peripheral.getNames()) do
        if isBlockReader(name) then
            local reader = peripheral.wrap(name)

            if reader then
                readers[#readers + 1] = {
                    name = name,
                    block = safeCall(reader, "getBlockName"),
                    data = safeCall(reader, "getBlockData"),
                    states = safeCall(reader, "getBlockStates")
                }
            end
        end
    end

    table.sort(readers, function(a, b)
        return a.name < b.name
    end)

    return readers
end

local function scalar(value)
    if type(value) == "string" or type(value) == "number" or type(value) == "boolean" then
        return tostring(value)
    end

    return nil
end

local function summarizeData(data)
    local result = {
        mana = {},
        required = {},
        process = {},
        items = {},
        manaCurrent = nil,
        manaMaximum = nil,
        manaRequired = nil
    }

    if type(data) ~= "table" then
        return result
    end

    local function add(list, path, value)
        if #list < 4 then
            list[#list + 1] = path .. "=" .. value
        end
    end

    local function walk(node, path, depth)
        if type(node) ~= "table" or depth > 7 then
            return
        end

        for key, value in pairs(node) do
            local keyText = tostring(key)
            local currentPath = path == "" and keyText or path .. "." .. keyText
            local normalizedKey = keyText:lower()
            local normalizedPath = currentPath:lower()
            local valueText = scalar(value)
            local numericValue = tonumber(value)

            if valueText then
                if normalizedKey:find("mana", 1, true) then
                    add(result.mana, currentPath, valueText)

                    if numericValue then
                        if normalizedKey == "mana"
                            or normalizedKey == "currentmana"
                            or normalizedKey == "storedmana"
                            or normalizedKey == "manastored" then
                            result.manaCurrent = numericValue
                        elseif normalizedKey:find("maxmana", 1, true)
                            or normalizedKey:find("manacapacity", 1, true)
                            or normalizedKey:find("manamax", 1, true) then
                            result.manaMaximum = numericValue
                        end
                    end
                end

                if normalizedKey:find("cost", 1, true)
                    or normalizedKey:find("required", 1, true)
                    or normalizedKey:find("need", 1, true) then
                    add(result.required, currentPath, valueText)

                    if numericValue and normalizedKey:find("mana", 1, true) then
                        result.manaRequired = numericValue
                    end
                end

                if normalizedKey:find("recipe", 1, true)
                    or normalizedKey:find("craft", 1, true)
                    or normalizedKey:find("progress", 1, true)
                    or normalizedKey:find("output", 1, true)
                    or normalizedKey:find("input", 1, true)
                    or normalizedKey:find("result", 1, true)
                    or normalizedKey:find("process", 1, true) then
                    add(result.process, currentPath, valueText)
                end

                if normalizedPath:find("item", 1, true)
                    or normalizedPath:find("invent", 1, true)
                    or normalizedPath:find("slot", 1, true)
                    or normalizedPath:find("fluid", 1, true) then
                    add(result.items, currentPath, valueText)
                end
            elseif type(value) == "table" then
                walk(value, currentPath, depth + 1)
            end
        end
    end

    walk(data, "", 0)
    return result
end

local function joinValues(values, fallback)
    if #values == 0 then
        return fallback
    end

    return table.concat(values, " | ")
end

local function assignMachines(readers)
    local assigned = {}
    local daisyIndex = 0

    for _, reader in ipairs(readers) do
        local machineId = classify(reader.block)

        if machineId == "mechanical_daisy" then
            daisyIndex = daisyIndex + 1

            if daisyIndex <= 2 then
                assigned[5 + daisyIndex] = reader
            end
        elseif machineId then
            for index, definition in ipairs(MACHINES) do
                if index <= 5 and definition.id == machineId and not assigned[index] then
                    assigned[index] = reader
                    break
                end
            end
        end
    end

    return assigned
end

local function buildMachineInfo(reader)
    if not reader then
        return {
            status = "NO SIGNAL",
            statusColour = C.red,
            reader = "NOT CONNECTED",
            block = "Machine not detected",
            mana = "Not available",
            required = "Not exposed",
            process = "Waiting for reader",
            items = "Not available",
            manaCurrent = nil,
            manaMaximum = nil,
            manaRequired = nil
        }
    end

    local data = summarizeData(reader.data)
    local hasData = type(reader.data) == "table"

    return {
        status = hasData and "ONLINE" or "DATA UNAVAILABLE",
        statusColour = hasData and C.green or C.orange,
        reader = reader.name,
        block = reader.block or "Nothing in front",
        mana = joinValues(data.mana, "Not exposed"),
        required = joinValues(data.required, "Not exposed"),
        process = joinValues(data.process, "No active recipe fields exposed"),
        items = joinValues(data.items, "No inventory fields exposed"),
        manaCurrent = data.manaCurrent,
        manaMaximum = data.manaMaximum,
        manaRequired = data.manaRequired
    }
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

local function drawCard(canvas, index, definition, info, x, y, cardWidth)
    local right = x + cardWidth - 1
    local innerWidth = cardWidth - 2
    local heading = fit(string.format("%02d // %s", index, definition.label), innerWidth)
    local leftDashes = math.max(0, math.floor((innerWidth - #heading) / 2))
    local rightDashes = math.max(0, innerWidth - #heading - leftDashes)

    writeAt(canvas, x, y, "+" .. string.rep("-", leftDashes), C.border)
    writeAt(canvas, x + 1 + leftDashes, y, heading, C.cyan)
    writeAt(
        canvas,
        x + 1 + leftDashes + #heading,
        y,
        string.rep("-", rightDashes) .. "+",
        C.border
    )

    writeAt(canvas, x, y + 1, "|", C.border)
    writeAt(canvas, x + 1, y + 1, fit("STATUS: " .. info.status, innerWidth), info.statusColour)
    writeAt(canvas, right, y + 1, "|", C.border)

    writeAt(canvas, x, y + 2, "|", C.border)
    writeAt(canvas, x + 1, y + 2, fit("READER: " .. info.reader, innerWidth), C.muted)
    writeAt(canvas, right, y + 2, "|", C.border)

    writeAt(canvas, x, y + 3, "|", C.border)
    writeAt(canvas, x + 1, y + 3, fit("CRAFTING: " .. info.process, innerWidth), C.yellow)
    writeAt(canvas, right, y + 3, "|", C.border)

    local manaText = "MANA: " .. info.mana
    if info.manaCurrent and info.manaMaximum then
        local percentage = info.manaMaximum > 0
            and math.max(0, math.min(100, info.manaCurrent / info.manaMaximum * 100))
            or 0
        manaText = string.format(
            "MANA: %s / %s  %.1f%%",
            compactNumber(info.manaCurrent),
            compactNumber(info.manaMaximum),
            percentage
        )
    end

    writeAt(canvas, x, y + 4, "|", C.border)
    writeAt(canvas, x + 1, y + 4, fit(manaText, innerWidth), C.green)
    writeAt(canvas, right, y + 4, "|", C.border)

    writeAt(canvas, x, y + 5, "|", C.border)
    writeAt(canvas, x + 1, y + 5, fit("MANA REQUIRED: " .. info.required, innerWidth), C.purple)
    writeAt(canvas, right, y + 5, "|", C.border)

    writeAt(canvas, x, y + 6, "|", C.border)
    writeAt(canvas, x + 1, y + 6, fit("INPUT / OUTPUT: " .. info.items, innerWidth), C.blue)
    writeAt(canvas, right, y + 6, "|", C.border)

    if info.manaCurrent and info.manaMaximum and info.manaMaximum > 0 then
        local barWidth = math.max(4, innerWidth - 4)
        local percentage = math.max(0, math.min(100, info.manaCurrent / info.manaMaximum * 100))
        local filled = math.floor(barWidth * percentage / 100)

        writeAt(canvas, x, y + 7, "|", C.border)
        writeAt(canvas, x + 1, y + 7, "[", C.muted)
        writeAt(canvas, x + 2, y + 7, string.rep("#", filled), C.green)
        writeAt(canvas, x + filled + 2, y + 7, string.rep("-", barWidth - filled), C.muted)
        writeAt(canvas, x + barWidth + 2, y + 7, "]", C.muted)
        writeAt(canvas, right, y + 7, "|", C.border)
    else
        writeAt(canvas, x, y + 7, "|", C.border)
        writeAt(canvas, x + 1, y + 7, fit("MANA TELEMETRY: WAITING FOR DATA", innerWidth), C.muted)
        writeAt(canvas, right, y + 7, "|", C.border)
    end

    writeAt(canvas, x, y + 8, "+" .. string.rep("-", innerWidth) .. "+", C.border)
end

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

local function saveDiagnostics(readers, assigned)
    local now = os.epoch("utc")
    if now - lastDiagnostic < CONFIG.diagnosticInterval * 1000 then
        return
    end
    lastDiagnostic = now

    local file = fs.open(CONFIG.diagnosticFile, "w")
    if not file then
        return
    end

    file.writeLine("POTATOCORE // BOTANIA PRODUCTION DIAGNOSTICS")
    file.writeLine("Timestamp: " .. os.date("%Y-%m-%d %H:%M:%S"))
    file.writeLine("Reader count: " .. #readers)
    file.writeLine("Wired modem side: " .. CONFIG.modemSide)
    file.writeLine("")

    file.writeLine("ALL DETECTED READERS")
    for _, reader in ipairs(readers) do
        file.writeLine("Reader: " .. reader.name)
        file.writeLine("Block: " .. tostring(reader.block))
        file.writeLine("Block states: " .. textutils.serialize(reader.states))
        file.writeLine("Block data:")
        file.writeLine(textutils.serialize(reader.data))
        file.writeLine("")
    end

    file.writeLine("EXPECTED MACHINE ASSIGNMENTS")
    for index, definition in ipairs(MACHINES) do
        local reader = assigned[index]
        file.writeLine(definition.label)

        if reader then
            file.writeLine("Reader: " .. reader.name)
            file.writeLine("Block: " .. tostring(reader.block))
            file.writeLine("Block states: " .. textutils.serialize(reader.states))
            file.writeLine("Block data:")
            file.writeLine(textutils.serialize(reader.data))
        else
            file.writeLine("NOT FOUND")
        end

        file.writeLine("")
    end

    file.close()
end

local function drawDashboard()
    local readers = scanReaders()
    local assigned = assignMachines(readers)
    local canvas = newCanvas()

    local online = 0
    for index = 1, #MACHINES do
        if assigned[index] then
            online = online + 1
        end
    end

    writeAt(canvas, 1, 1, "+" .. string.rep("=", width - 2) .. "+", C.border)
    writeCentered(canvas, 2, "POTATOCORE // BOTANIA CORE", C.green)
    writeCentered(canvas, 3, "AUTONOMOUS PRODUCTION & CRAFTING TELEMETRY", C.blue)
    writeAt(canvas, 1, 4, "+" .. string.rep("=", width - 2) .. "+", C.border)

    writeAt(canvas, 3, 5, "[SYS] PRODUCTION LINE " .. (online == 7 and "ONLINE" or "PARTIAL"),
        online == 7 and C.green or C.orange)
    writeRight(canvas, 5, width - 3, "[MACHINES] " .. online .. "/7  [READERS] " .. #readers, C.cyan)

    writeRule(canvas, 6, "-", C.border)
    writeCentered(canvas, 7, "/// LIVE MACHINE STATUS // RECIPE // MANA REQUIREMENTS ///", C.cyan)

    local columns = 2
    local gap = 2
    local cardWidth = math.floor((width - 4 - gap) / columns)
    local firstX = math.floor((width - (cardWidth * columns + gap)) / 2) + 1
    local firstY = 8
    local cardHeight = 9
    local rowGap = 1

    for index, definition in ipairs(MACHINES) do
        local column = (index - 1) % columns
        local row = math.floor((index - 1) / columns)
        local x = firstX + column * (cardWidth + gap)
        local y = firstY + row * (cardHeight + rowGap)

        drawCard(canvas, index, definition, buildMachineInfo(assigned[index]), x, y, cardWidth)
    end

    local uptime = formatDuration((os.epoch("utc") - startedAt) / 1000)
    writeRule(canvas, height - 2, "=", C.purple)
    writeAt(canvas, 3, height - 1, "DIAGNOSTICS: " .. CONFIG.diagnosticFile, C.blue)
    writeRight(canvas, height - 1, width - 3, "UPTIME " .. uptime .. " // MONITOR ONLINE", C.green)
    writeAt(canvas, 1, height, "+" .. string.rep("=", width - 2) .. "+", C.border)

    renderCanvas(canvas)
    saveDiagnostics(readers, assigned)
end

print("POTATOCORE // BOTANIA PRODUCTION LINE")
print("Wired modem: " .. CONFIG.modemSide:upper())
print("Monitor: " .. width .. "x" .. height)
print("Scanning seven Block Readers...")
drawDashboard()

while true do
    sleep(CONFIG.refreshInterval)

    local ok, err = pcall(drawDashboard)
    if not ok then
        monitor.setTextColor(C.red)
        monitor.setCursorPos(1, height)
        monitor.clearLine()
        monitor.write(fit("DASHBOARD ERROR: " .. tostring(err), width))
    end
end
