-- ============================================================
-- POTATOCORE // BOTANIA PRODUCTION LINE
-- Dedicated dashboard for a separate 6x6 monitor.
--
-- Connect this computer and all seven Block Readers to the
-- same wired modem network. Each reader must face its machine.
--
-- Advanced Peripherals 0.7.x / Minecraft 1.20.1:
--   Peripheral type: blockReader
-- ============================================================

local CONFIG = {
    textScale = 0.5,
    refreshInterval = 2,
    diagnosticFile = "botania_data.txt"
}

local monitor = peripheral.find("monitor")
if not monitor then
    error("Monitor not found on this wired network!")
end

monitor.setTextScale(CONFIG.textScale)

local width, height = monitor.getSize()
if width < 32 or height < 34 then
    error("Botania display needs a larger monitor. Detected " .. width .. "x" .. height .. ".")
end

monitor.setBackgroundColor(colors.black)
monitor.setTextColor(colors.white)
monitor.clear()

local renderedRows = {}
local lastDiagnostic = 0

local MACHINES = {
    { id = "industrial_agglomeration_factory", label = "INDUSTRIAL AGGLOMERATION" },
    { id = "alfheim_market", label = "ALFHEIM MARKET" },
    { id = "mechanical_mana_pool", label = "MECHANICAL MANA POOL" },
    { id = "mechanical_runic_altar", label = "MECHANICAL RUNIC ALTAR" },
    { id = "mechanical_apothecary", label = "MECHANICAL APOTHECARY" },
    { id = "mechanical_daisy", label = "MECHANICAL DAISY #1" },
    { id = "mechanical_daisy", label = "MECHANICAL DAISY #2" }
}

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

    for _, definition in ipairs(MACHINES) do
        if id:find(definition.id, 1, true) then
            return definition.id
        end
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
        keys = {}
    }

    if type(data) ~= "table" then
        return result
    end

    for key in pairs(data) do
        result.keys[#result.keys + 1] = tostring(key)
    end
    table.sort(result.keys)

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

            if valueText then
                if normalizedKey:find("mana", 1, true) then
                    add(result.mana, currentPath, valueText)
                end

                if normalizedKey:find("cost", 1, true)
                    or normalizedKey:find("required", 1, true)
                    or normalizedKey:find("need", 1, true) then
                    add(result.required, currentPath, valueText)
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
            status = "READER NOT FOUND",
            mana = "Not available",
            required = "Not exposed",
            process = "Not available",
            items = "Not available"
        }
    end

    local data = summarizeData(reader.data)
    local status = type(reader.data) == "table" and "ONLINE" or "BLOCK DATA UNAVAILABLE"

    return {
        status = status,
        mana = joinValues(data.mana, "Not exposed"),
        required = joinValues(data.required, "Not exposed"),
        process = joinValues(data.process, "Not exposed"),
        items = joinValues(data.items, "Not exposed")
    }
end

local function padLine(content, innerWidth)
    content = fit(content, innerWidth)
    return "|" .. content .. string.rep(" ", innerWidth - #content) .. "|"
end

local function makeCard(title, info, cardWidth)
    local inner = cardWidth - 2

    return {
        "+" .. string.rep("-", inner) .. "+",
        padLine(" " .. title, inner),
        padLine(" STATUS: " .. info.status, inner),
        padLine(" MANA: " .. info.mana, inner),
        padLine(" REQUIRED: " .. info.required, inner),
        padLine(" JOB: " .. info.process, inner),
        padLine(" ITEMS: " .. info.items, inner),
        "+" .. string.rep("-", inner) .. "+"
    }
end

local function saveDiagnostics(readers, assigned)
    local now = os.epoch("utc")
    if now - lastDiagnostic < 10000 then
        return
    end
    lastDiagnostic = now

    local file = fs.open(CONFIG.diagnosticFile, "w")
    if not file then
        return
    end

    file.writeLine("POTATOCORE // BOTANIA PRODUCTION DIAGNOSTICS")
    file.writeLine("Timestamp: " .. os.date("%Y-%m-%d %H:%M:%S"))
    file.writeLine("Readers detected: " .. #readers)
    file.writeLine("")

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
    local rows = {}

    local function put(x, y, value)
        if y < 1 or y > height then
            return
        end

        value = tostring(value or "")
        for index = 1, #value do
            local position = x + index - 1
            if position >= 1 and position <= width then
                rows[y] = rows[y] or {}
                rows[y][position] = value:sub(index, index)
            end
        end
    end

    put(1, 1, fit("POTATOCORE // BOTANIA PRODUCTION LINE", width))
    put(1, 2, fit("READERS " .. #readers .. "/7  |  REFRESH " .. CONFIG.refreshInterval .. "s", width))

    local cardWidth = math.floor((width - 3) / 2)
    local startY = 3
    local rowGap = 8

    for index, definition in ipairs(MACHINES) do
        local column = (index - 1) % 2
        local row = math.floor((index - 1) / 2)
        local x = column == 0 and 1 or cardWidth + 2
        local y = startY + row * rowGap
        local info = buildMachineInfo(assigned[index])
        local card = makeCard(definition.label, info, cardWidth)

        for lineIndex, line in ipairs(card) do
            put(x, y + lineIndex - 1, fit(line, cardWidth))
        end
    end

    put(1, height - 1, fit("NBT LOG: " .. CONFIG.diagnosticFile, width))
    put(1, height, fit("POTATOCORE // LIVE MACHINE TELEMETRY", width))

    for y = 1, height do
        local line = {}
        for x = 1, width do
            line[x] = rows[y] and rows[y][x] or " "
        end

        local rendered = table.concat(line)

        if renderedRows[y] ~= rendered then
            monitor.setCursorPos(1, y)
            monitor.setTextColor(colors.white)
            monitor.setBackgroundColor(colors.black)
            monitor.write(rendered)
            renderedRows[y] = rendered
        end
    end

    saveDiagnostics(readers, assigned)
end

print("POTATOCORE // BOTANIA PRODUCTION LINE")
print("Monitor: " .. width .. "x" .. height)
print("Scanning Block Readers...")
drawDashboard()

while true do
    sleep(CONFIG.refreshInterval)

    local ok, err = pcall(drawDashboard)
    if not ok then
        monitor.setTextColor(colors.red)
        monitor.setCursorPos(1, height)
        monitor.clearLine()
        monitor.write(fit("DASHBOARD ERROR: " .. tostring(err), width))
    end
end
