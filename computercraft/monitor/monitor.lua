-- ============================================================
-- POTATOCORE // BOTANIA PRODUCTION MONITOR
-- Dedicated receiver and expandable monitor dashboard.
--
-- Hardware:
--   BOTTOM = Ender Modem
--   Monitor = connected locally or through a wired monitor network
--
-- Receives Block Reader telemetry from machines.lua.
-- The old 3x3 Mana Core monitor remains separate and untouched.
-- ============================================================

local CONFIG = {
    modemSide = "bottom",
    textScale = 0.5,
    protocol = "potatocore_botania_machines_v1",
    sourceTimeout = 8,
    receiveInterval = 0.5,
    diagnosticInterval = 10,
    diagnosticFile = "botania_received_data.txt"
}

local modemType = peripheral.getType(CONFIG.modemSide)
if modemType ~= "modem" then
    error("Ender Modem not found on " .. CONFIG.modemSide:upper() .. "!")
end

local monitor = peripheral.find("monitor")
if not monitor then
    error("Botania monitor not found. This program belongs on the dedicated monitor computer.")
end

rednet.open(CONFIG.modemSide)
monitor.setTextScale(CONFIG.textScale)

local width, height = monitor.getSize()
if width < 54 or height < 32 then
    error(
        "Monitor is too small for the production dashboard. Detected "
        .. width .. "x" .. height .. "; need at least 54x32."
    )
end

local C = {
    background = colors.black,
    panel = colors.gray,
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

local sources = {}
local renderedRows = {}
local startedAt = os.epoch("utc")
local lastDiagnostic = 0
local lastDraw = 0

local MACHINES = {
    { id = "industrial_agglomeration_factory", label = "IND. AGGLOM." },
    { id = "alfheim_market", label = "ALFHEIM MARKET" },
    { id = "mechanical_mana_pool", label = "MANA POOL" },
    { id = "mechanical_runic_altar", label = "RUNIC ALTAR" },
    { id = "mechanical_apothecary", label = "APOTHECARY" },
    { id = "mechanical_daisy", label = "DAISY #1" },
    { id = "mechanical_daisy", label = "DAISY #2" }
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
        if #list < 3 then
            list[#list + 1] = path .. "=" .. value
        end
    end

    local function walk(node, path, depth)
        if type(node) ~= "table" or depth > 7 then
            return
        end

        local keys = {}
        for key in pairs(node) do
            keys[#keys + 1] = key
        end
        table.sort(keys, function(a, b)
            return tostring(a) < tostring(b)
        end)

        for _, key in ipairs(keys) do
            local value = node[key]
            local keyText = tostring(key)
            local currentPath = path == "" and keyText or path .. "." .. keyText
            local normalizedKey = keyText:lower()
            local normalizedPath = currentPath:lower()
            local numericValue = tonumber(value)
            local valueText = nil

            if type(value) == "string" or type(value) == "number" or type(value) == "boolean" then
                valueText = tostring(value)
            end

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

                if normalizedPath:find("recipe", 1, true)
                    or normalizedPath:find("craft", 1, true)
                    or normalizedPath:find("output", 1, true)
                    or normalizedPath:find("input", 1, true)
                    or normalizedPath:find("result", 1, true)
                    or normalizedPath:find("process", 1, true)
                    or normalizedPath:find("progress", 1, true) then
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

local function getFreshReaders()
    local readers = {}
    local now = os.epoch("utc")

    for computerId, source in pairs(sources) do
        if now - source.seen <= CONFIG.sourceTimeout * 1000 then
            for _, reader in ipairs(source.readers) do
                readers[#readers + 1] = {
                    computer = computerId,
                    reader = reader.reader,
                    block = reader.block,
                    data = reader.data,
                    states = reader.states
                }
            end
        end
    end

    table.sort(readers, function(a, b)
        if a.computer == b.computer then
            return tostring(a.reader) < tostring(b.reader)
        end

        return a.computer < b.computer
    end)

    return readers
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
            status = "OFFLINE",
            statusColour = C.red,
            computer = "--",
            craft = "Waiting for machine",
            mana = "Not exposed",
            required = "Not exposed",
            items = "Not exposed",
            manaCurrent = nil,
            manaMaximum = nil,
            manaRequired = nil
        }
    end

    local data = summarizeData(reader.data)
    local hasData = type(reader.data) == "table"
    local mana = joinValues(data.mana, "Not exposed")
    local required = joinValues(data.required, "Not exposed")

    if data.manaCurrent and data.manaMaximum then
        mana = compactNumber(data.manaCurrent) .. " / " .. compactNumber(data.manaMaximum)
    elseif data.manaCurrent then
        mana = compactNumber(data.manaCurrent)
    end

    if data.manaRequired then
        required = compactNumber(data.manaRequired) .. " mana"
    end

    return {
        status = hasData and "ONLINE" or "NO DATA",
        statusColour = hasData and C.green or C.orange,
        computer = "PC " .. tostring(reader.computer),
        craft = joinValues(data.process, "No recipe data"),
        mana = mana,
        required = required,
        items = joinValues(data.items, "Not exposed"),
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

local function drawCard(canvas, index, definition, info, x, y, cardWidth)
    local innerWidth = cardWidth - 2
    local heading = string.format("%02d  %s", index, definition.label)

    -- Solid header strip, then a clean five-line telemetry body.
    writeAt(canvas, x, y, string.rep(" ", cardWidth), C.white, C.panel)
    writeAt(canvas, x + 1, y, fit(heading, innerWidth), C.cyan, C.panel)
    writeAt(canvas, x + 1, y + 1, fit(info.status .. "  " .. info.computer, innerWidth), info.statusColour)
    writeAt(canvas, x + 1, y + 2, fit("RECIPE  " .. info.craft, innerWidth), C.yellow)
    writeAt(canvas, x + 1, y + 3, fit("MANA    " .. info.mana, innerWidth), C.green)
    writeAt(canvas, x + 1, y + 4, fit("NEED    " .. info.required, innerWidth), C.purple)
    writeAt(canvas, x + 1, y + 5, fit("I/O     " .. info.items, innerWidth), C.blue)
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

    file.writeLine("POTATOCORE // BOTANIA MONITOR DIAGNOSTICS")
    file.writeLine("Timestamp: " .. os.date("%Y-%m-%d %H:%M:%S"))
    file.writeLine("Active machine readers: " .. #readers)
    file.writeLine("Monitor modem: " .. CONFIG.modemSide)
    file.writeLine("")

    for _, reader in ipairs(readers) do
        file.writeLine("Computer: " .. reader.computer)
        file.writeLine("Reader: " .. tostring(reader.reader))
        file.writeLine("Block: " .. tostring(reader.block))
        file.writeLine("States: " .. textutils.serialize(reader.states))
        file.writeLine("Data: " .. textutils.serialize(reader.data))
        file.writeLine("")
    end

    file.close()
end

local function drawDashboard()
    local readers = getFreshReaders()
    local assigned = assignMachines(readers)
    local canvas = newCanvas()

    local online = 0
    for index = 1, #MACHINES do
        if assigned[index] then
            online = online + 1
        end
    end

    local activeComputers = 0
    local now = os.epoch("utc")
    for _, source in pairs(sources) do
        if now - source.seen <= CONFIG.sourceTimeout * 1000 then
            activeComputers = activeComputers + 1
        end
    end

    writeAt(canvas, 1, 1, "+" .. string.rep("=", width - 2) .. "+", C.border)
    writeCentered(canvas, 2, "POTATOCORE", C.green)
    writeCentered(canvas, 3, "BOTANIA PRODUCTION  /  MACHINE TELEMETRY", C.cyan)
    writeAt(canvas, 1, 4, "+" .. string.rep("=", width - 2) .. "+", C.border)

    local systemState = online == #MACHINES and "ALL MACHINES LINKED" or "WAITING FOR MACHINES"
    local systemColour = online == #MACHINES and C.green or C.orange
    writeAt(canvas, 2, 5, fit("SYSTEM  " .. systemState, math.floor(width / 2) - 2), systemColour)
    writeRight(canvas, 5, width - 2, "MACHINES " .. online .. "/" .. #MACHINES .. "  |  PCS " .. activeComputers, C.cyan)
    writeAt(canvas, 1, 6, "+" .. string.rep("-", width - 2) .. "+", C.border)

    -- Two columns keep each machine card wide enough to read on the 6x6 display.
    local columns = 2
    local gap = 2
    local cardWidth = math.floor((width - 3) / columns)
    local firstX = 2
    local secondX = firstX + cardWidth + gap
    local firstY = 7
    local cardHeight = 6
    local rowCount = math.ceil(#MACHINES / columns)
    local footerY = height - 1
    local usableCardHeight = footerY - firstY
    local extraSpace = usableCardHeight - rowCount * cardHeight
    local rowGap = math.max(0, math.floor(extraSpace / math.max(1, rowCount - 1)))

    for index, definition in ipairs(MACHINES) do
        local column = (index - 1) % columns
        local row = math.floor((index - 1) / columns)
        local x = column == 0 and firstX or secondX
        local y = firstY + row * (cardHeight + rowGap)

        drawCard(canvas, index, definition, buildMachineInfo(assigned[index]), x, y, cardWidth)
    end

    local uptime = formatDuration((os.epoch("utc") - startedAt) / 1000)
    local footerRight = "UP " .. uptime .. "  /  RX LIVE"
    local footerLeft = "DIAG  " .. CONFIG.diagnosticFile
    writeAt(canvas, 2, footerY, fit(footerLeft, width - #footerRight - 4), C.muted)
    writeRight(canvas, footerY, width - 2, footerRight, C.green)
    writeAt(canvas, 1, height, "+" .. string.rep("=", width - 2) .. "+", C.border)

    renderCanvas(canvas)
    saveDiagnostics(readers, assigned)
    lastDraw = os.clock()
end

print("========================================")
print(" POTATOCORE // BOTANIA MONITOR")
print("========================================")
print("Ender Modem : " .. CONFIG.modemSide:upper())
print("Monitor     : " .. width .. "x" .. height)
print("Protocol    : " .. CONFIG.protocol)
print("Waiting for machine computers...")
drawDashboard()

while true do
    local senderId, message, protocol = rednet.receive(nil, CONFIG.receiveInterval)
    local changed = false

    if senderId and protocol == CONFIG.protocol
        and type(message) == "table"
        and message.kind == "botania_machines"
        and type(message.readers) == "table" then

        local cleanReaders = {}

        for _, reader in ipairs(message.readers) do
            if type(reader) == "table" then
                cleanReaders[#cleanReaders + 1] = {
                    reader = tostring(reader.reader or "unknown"),
                    block = type(reader.block) == "string" and reader.block or nil,
                    data = type(reader.data) == "table" and reader.data or nil,
                    states = type(reader.states) == "table" and reader.states or nil
                }
            end
        end

        sources[senderId] = {
            readers = cleanReaders,
            seen = os.epoch("utc")
        }

        changed = true
    end

    local now = os.epoch("utc")
    for computerId, source in pairs(sources) do
        if now - source.seen > CONFIG.sourceTimeout * 1000 then
            sources[computerId] = nil
            changed = true
        end
    end

    if changed or os.clock() - lastDraw >= 1 then
        local ok, err = pcall(drawDashboard)

        if not ok then
            monitor.setTextColor(C.red)
            monitor.setCursorPos(1, height)
            monitor.clearLine()
            monitor.write(fit("MONITOR ERROR: " .. tostring(err), width))
        end
    end
end
