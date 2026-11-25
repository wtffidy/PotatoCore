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
    textScale = 0.8,
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
local width, height

-- Prefer the Mana Core's readable scale, then step down only when needed.
for _, scale in ipairs({ 0.8, 0.7, 0.5 }) do
    monitor.setTextScale(scale)
    width, height = monitor.getSize()

    if width >= 54 and height >= 32 then
        CONFIG.textScale = scale
        break
    end
end

if width < 54 or height < 32 then
    error(
        "Monitor is too small for the Botania dashboard. Detected "
        .. width .. "x" .. height .. "; need at least 54x32."
    )
end

local C = {
    background = colors.black,
    white = colors.white,
    muted = colors.gray,
    red = colors.red,
    orange = colors.orange,
    border = colors.blue,
    cyan = colors.cyan,
    green = colors.lime,
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
    { id = "industrial_agglomeration_factory", label = "INDUSTRIAL AGGLOMERATION" },
    { id = "alfheim_market", label = "ALFHEIM MARKET" },
    { id = "mechanical_mana_pool", label = "MANA POOL" },
    { id = "mechanical_runic_altar", label = "RUNIC ALTAR" },
    { id = "mechanical_apothecary", label = "APOTHECARY" },
    { id = "mechanical_daisy", label = "PURE DAISY 01" },
    { id = "mechanical_daisy", label = "PURE DAISY 02" }
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
        manaCurrent = nil,
        manaMaximum = nil,
        manaRequired = nil
    }

    if type(data) ~= "table" then
        return result
    end

    local seen = {}

    local function walk(node, path, depth)
        if type(node) ~= "table" or depth > 8 or seen[node] then
            return
        end

        seen[node] = true

        local keys = {}
        for key in pairs(node) do
            keys[#keys + 1] = key
        end
        table.sort(keys, function(a, b)
            return tostring(a) < tostring(b)
        end)

        for _, key in ipairs(keys) do
            local value = node[key]
            local keyText = tostring(key):lower()
            local normalizedKey = keyText:gsub("[^%w]", "")
            local currentPath = path == "" and keyText or path .. "." .. keyText
            local numericValue = tonumber(value)

            if type(value) == "table" then
                walk(value, currentPath, depth + 1)
            elseif numericValue then
                local manaPath = currentPath:find("mana", 1, true) ~= nil

                if manaPath then
                    if normalizedKey:find("required", 1, true)
                        or normalizedKey:find("cost", 1, true)
                        or normalizedKey:find("need", 1, true) then
                        result.manaRequired = numericValue
                    elseif normalizedKey:find("maximum", 1, true)
                        or normalizedKey:find("max", 1, true)
                        or normalizedKey:find("capacity", 1, true) then
                        result.manaMaximum = numericValue
                    elseif normalizedKey == "mana"
                        or normalizedKey:find("current", 1, true)
                        or normalizedKey:find("amount", 1, true)
                        or normalizedKey:find("stored", 1, true)
                        or normalizedKey == "value" then
                        result.manaCurrent = numericValue
                    end
                elseif normalizedKey == "manacost" or normalizedKey == "manarequired"
                    or normalizedKey == "requiredmana" or normalizedKey == "neededmana" then
                    result.manaRequired = numericValue
                end
            end
        end
    end

    walk(data, "", 0)
    return result
end

local function findCraftItem(data)
    if type(data) ~= "table" then
        return nil
    end

    local candidates = {}
    local seen = {}

    local function normalizeItem(value)
        local item = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if item == "" or item:lower() == "air" or item:lower() == "empty"
            or item:lower() == "none" or item:lower() == "null" then
            return nil
        end

        local namespace, path = item:match("^([%w_.%-]+):([%w_./%-]+)$")
        if namespace and path then
            item = path:gsub("[_./%-]+", " ")
        end

        item = item:gsub("(%a)([%w']*)", function(first, rest)
            return first:upper() .. rest
        end)

        return item
    end

    local function walk(node, path, depth)
        if type(node) ~= "table" or depth > 8 or seen[node] then
            return
        end

        seen[node] = true

        local keys = {}
        for key in pairs(node) do
            keys[#keys + 1] = key
        end
        table.sort(keys, function(a, b)
            return tostring(a) < tostring(b)
        end)

        for _, key in ipairs(keys) do
            local value = node[key]
            local keyText = tostring(key):lower()
            local normalizedKey = keyText:gsub("[^%w]", "")
            local currentPath = path == "" and keyText or path .. "." .. keyText
            local lowerPath = currentPath:lower()
            local recipePath = lowerPath:find("output", 1, true)
                or lowerPath:find("result", 1, true)
                or lowerPath:find("recipe", 1, true)
                or lowerPath:find("craft", 1, true)
                or lowerPath:find("product", 1, true)

            if type(value) == "table" then
                walk(value, currentPath, depth + 1)
            elseif type(value) == "string" and recipePath then
                local itemField = normalizedKey:find("item", 1, true)
                    or normalizedKey == "id"
                    or normalizedKey == "name"
                    or normalizedKey == "output"
                    or normalizedKey == "result"
                    or normalizedKey == "crafted"
                    or normalizedKey == "product"
                    or normalizedKey == "registryname"

                if itemField then
                    local item = normalizeItem(value)
                    if item then
                        local score = 0
                        if lowerPath:find("output", 1, true) then
                            score = score + 100
                        elseif lowerPath:find("result", 1, true) then
                            score = score + 90
                        elseif lowerPath:find("recipe", 1, true) then
                            score = score + 80
                        elseif lowerPath:find("craft", 1, true) then
                            score = score + 70
                        end

                        if normalizedKey:find("item", 1, true) then
                            score = score + 20
                        end

                        candidates[#candidates + 1] = {
                            item = item,
                            score = score
                        }
                    end
                end
            end
        end
    end

    walk(data, "", 0)
    table.sort(candidates, function(a, b)
        if a.score == b.score then
            return a.item < b.item
        end
        return a.score > b.score
    end)

    return candidates[1] and candidates[1].item or nil
end

local function formatNumber(value)
    local result = tostring(math.floor(math.max(0, tonumber(value) or 0)))
    while true do
        local formatted, count = result:gsub("^(%d+)(%d%d%d)", "%1,%2")
        result = formatted
        if count == 0 then
            return result
        end
    end
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
            craftItem = "—",
            mana = "[N/A / N/A]",
            manaRequired = "[N/A]"
        }
    end

    local data = summarizeData(reader.data)
    local craftItem = findCraftItem(reader.data) or "—"
    local function displayMana(value)
        if value == nil then
            return "N/A"
        end

        return width >= 80 and formatNumber(value) or compactNumber(value)
    end

    local manaCurrent = displayMana(data.manaCurrent)
    local manaMaximum = displayMana(data.manaMaximum)
    local manaRequired = displayMana(data.manaRequired)

    return {
        craftItem = craftItem,
        mana = "[" .. manaCurrent .. " / " .. manaMaximum .. "]",
        manaRequired = "[" .. manaRequired .. "]"
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

local function drawCard(canvas, definition, info, x, y, cardWidth, cardHeight)
    local right = x + cardWidth - 1
    local innerWidth = cardWidth - 2
    local heading = fit(definition.label, innerWidth)
    local leftDashes = math.max(0, math.floor((innerWidth - #heading) / 2))
    local rightDashes = math.max(0, innerWidth - #heading - leftDashes)

    writeAt(canvas, x, y, "+" .. string.rep("-", leftDashes), C.border)
    writeAt(canvas, x + 1 + leftDashes, y, heading, C.cyan)
    writeAt(canvas, x + 1 + leftDashes + #heading, y, string.rep("-", rightDashes) .. "+", C.border)

    local function cardLine(offset, label, value, colour)
        local line = label .. "  " .. value
        writeAt(canvas, x, y + offset, "|", C.border)
        writeAt(canvas, x + 1, y + offset, fit(line, innerWidth), colour)
        writeAt(canvas, right, y + offset, "|", C.border)
    end

    cardLine(1, "CRAFTING", info.craftItem, C.yellow)
    cardLine(2, "MANA", info.mana, C.green)
    cardLine(3, "REQUIRED", info.manaRequired, C.purple)

    writeAt(canvas, x, y + cardHeight - 1, "+" .. string.rep("-", innerWidth) .. "+", C.border)
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

-- Block Reader peripheral data can contain shared table references.
-- textutils.serialize rejects repeated references, so diagnostics use a
-- defensive formatter that marks repeats and limits recursion/output size.
local function diagnosticSerialize(value, seen, depth)
    local valueType = type(value)

    if valueType == "string" then
        return string.format("%q", value)
    elseif valueType == "number" or valueType == "boolean" or valueType == "nil" then
        return tostring(value)
    elseif valueType ~= "table" then
        return string.format("<%s>", valueType)
    end

    seen = seen or {}
    depth = depth or 0

    if seen[value] then
        return '"<repeated table reference>"'
    end

    if depth >= 8 then
        return '"<maximum diagnostic depth>"'
    end

    seen[value] = true

    local entries = {}
    local count = 0

    for key, entry in pairs(value) do
        count = count + 1

        if count > 128 then
            entries[#entries + 1] = '"<additional entries omitted>"'
            break
        end

        entries[#entries + 1] = "["
            .. diagnosticSerialize(key, seen, depth + 1)
            .. "] = "
            .. diagnosticSerialize(entry, seen, depth + 1)
    end

    return "{ " .. table.concat(entries, ", ") .. " }"
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
        file.writeLine("Computer: " .. tostring(reader.computer))
        file.writeLine("Reader: " .. tostring(reader.reader))
        file.writeLine("Block: " .. tostring(reader.block))
        file.writeLine("States: " .. diagnosticSerialize(reader.states))
        file.writeLine("Data: " .. diagnosticSerialize(reader.data))
        file.writeLine("")
    end

    file.close()
end

local function drawDashboard()
    local readers = getFreshReaders()
    local assigned = assignMachines(readers)
    local canvas = newCanvas()

    -- A quiet title, then the seven production modules. No diagnostics,
    -- computer IDs, link counters, uptime, or peripheral status on-screen.
    writeAt(canvas, 1, 1, "+" .. string.rep("=", width - 2) .. "+", C.border)
    writeCentered(canvas, 2, "BOTANIA PRODUCTION", C.green)
    writeAt(canvas, 1, 3, "+" .. string.rep("=", width - 2) .. "+", C.border)

    local columns = 2
    local gap = 2
    local cardWidth = math.floor((width - 4) / columns)
    local firstX = 2
    local secondX = firstX + cardWidth + gap
    local firstY = 5
    local rowCount = math.ceil(#MACHINES / columns)
    local cardHeight = 5
    local availableRows = height - firstY + 1
    local extraRows = math.max(0, availableRows - rowCount * cardHeight)
    local rowGap = math.max(1, math.min(4, math.floor(extraRows / math.max(1, rowCount - 1))))

    for index, definition in ipairs(MACHINES) do
        local column = (index - 1) % columns
        local row = math.floor((index - 1) / columns)
        local x = column == 0 and firstX or secondX
        local y = firstY + row * (cardHeight + rowGap)

        drawCard(canvas, definition, buildMachineInfo(assigned[index]), x, y, cardWidth, cardHeight)
    end

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
