local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local BufferUtil = Proto:sharedModule({
    moduleName = "BufferUtil"
})


local POSITIVE_INTEGER_MARKER = 0
local NEGATIVE_INTEGER_MARKER = 1
local TRUE_MARKER = 2
local FALSE_MARKER = 3
local FLOAT_MARKER = 4
local VECTOR3_MARKER = 5
local STRING_MARKER = 6
local CFRAME_MARKER = 7
local TABLE_START_MARKER = 8
local TABLE_END_MARKER = 9


local TEMP_BUFFER = buffer.create(100000)


function BufferUtil:writeElementToQueue(queueSharedTable, data)
    local cursor = self:writeTable(TEMP_BUFFER, 0, data)

    self:writeBufferToQueue(queueSharedTable, TEMP_BUFFER, cursor)
end

function BufferUtil:writeBufferToQueue(queueSharedTable, dataBuffer, dataLength)
    SharedTable.update(queueSharedTable, 1, function(queueBuffer)
        if not queueBuffer then
            local newBuffer = buffer.create(dataLength)
            buffer.copy(newBuffer, 0, dataBuffer, 0, dataLength)
            return newBuffer
        end

        local queueBufferLength = buffer.len(queueBuffer)
        local newLength = queueBufferLength + dataLength

        local newBuffer = buffer.create(newLength)

        buffer.copy(newBuffer, 0, queueBuffer, 0, queueBufferLength)
        buffer.copy(newBuffer, queueBufferLength, dataBuffer, 0, dataLength)

        return newBuffer
    end)
end

function BufferUtil:readElementFromQueue(queueSharedTable)
    local element

    SharedTable.update(queueSharedTable, 1, function(queueBuffer)
        if not queueBuffer then return end

        local data, cursor = self:readValue(queueBuffer, 0)
        element = data

        if cursor >= buffer.len(queueBuffer) then
            return nil
        end

        local newLength = buffer.len(queueBuffer) - cursor
        local newBuffer = buffer.create(newLength)
        buffer.copy(newBuffer, 0, queueBuffer, cursor, newLength)

        return newBuffer
    end)

    return element
end



function BufferUtil:readBuffer(buff)
    local data = {}

    local length = buffer.len(buff)
    local cursor = 0

    while cursor < length do
        local value, newCursor = self:readValue(buff, cursor)
        cursor = newCursor

        table.insert(data, value)
    end

    return data
end

function BufferUtil:readValue(buff, cursor)
    local marker = buffer.readu8(buff, cursor)
    cursor += 1

    if marker == TRUE_MARKER then
        return true, cursor

    elseif marker == FALSE_MARKER then
        return false, cursor

    elseif marker == POSITIVE_INTEGER_MARKER then
        return buffer.readu32(buff, cursor), cursor + 4

    elseif marker == NEGATIVE_INTEGER_MARKER then
        return -buffer.readu32(buff, cursor), cursor + 4

    elseif marker == FLOAT_MARKER then
        return buffer.readf32(buff, cursor), cursor + 4

    elseif marker == VECTOR3_MARKER then
        local x = buffer.readf32(buff, cursor)
        local y = buffer.readf32(buff, cursor + 4)
        local z = buffer.readf32(buff, cursor + 8)

        return Vector3.new(x, y, z), cursor + 12
    
    elseif marker == STRING_MARKER then
        local stringLength = buffer.readu32(buff, cursor)
        cursor += 4

        return buffer.readstring(buff, cursor, stringLength), cursor + stringLength

    elseif marker == CFRAME_MARKER then
        local x = buffer.readf32(buff, cursor)
        local y = buffer.readf32(buff, cursor + 4)
        local z = buffer.readf32(buff, cursor + 8)

        local quaternion = Proto.Quaternion.new(
            buffer.readf32(buff, cursor + 12),
            buffer.readf32(buff, cursor + 16),
            buffer.readf32(buff, cursor + 20),
            buffer.readf32(buff, cursor + 24)
        )

        return quaternion:ToCFrame(Vector3.new(x, y, z)), cursor + 28

    elseif marker == TABLE_START_MARKER then
        return self:readTable(buff, cursor)

    elseif marker == TABLE_END_MARKER then
        return nil, cursor

    end

    error(`Invalid marker: ${marker}`)
end

function BufferUtil:readTable(buff, cursor)
    local tbl = {}

    while true do
        local value, newCursor = self:readValue(buff, cursor)
        cursor = newCursor

        if value == nil then break end--value is nil if it reaches TABLE_END_MARKER or marker that it can't read

        table.insert(tbl, value)
    end

    return tbl, cursor
end





function BufferUtil:writeValue(buff, cursor, value)
    if typeof(value) == "number" then
        return self:writeNumber(buff, cursor, value)

    elseif typeof(value) == "boolean" then
        buffer.writeu8(buff, cursor, if value then TRUE_MARKER else FALSE_MARKER)
        return cursor + 1

    elseif typeof(value) == "Vector3" then
        buffer.writeu8(buff, cursor, VECTOR3_MARKER)
        buffer.writef32(buff, cursor + 1, value.X)
        buffer.writef32(buff, cursor + 5, value.Y)
        buffer.writef32(buff, cursor + 9, value.Z)
        return cursor + 13

    elseif typeof(value) == "string" then
        local stringBuff = buffer.fromstring(value)
        local stringLength = buffer.len(stringBuff)

        buffer.writeu8(buff, cursor, STRING_MARKER)

        buffer.writeu32(buff, cursor + 1, stringLength)
        buffer.copy(buff, cursor + 5, stringBuff, 0, stringLength)

        return cursor + 5 + stringLength

    elseif typeof(value) == "CFrame" then
        local quaternion = Proto.Quaternion.cframe(value)

        buffer.writeu8(buff, cursor, CFRAME_MARKER)

        buffer.writef32(buff, cursor + 1, value.X)
        buffer.writef32(buff, cursor + 5, value.Y)
        buffer.writef32(buff, cursor + 9, value.Z)

        buffer.writef32(buff, cursor + 13, quaternion.X)
        buffer.writef32(buff, cursor + 17, quaternion.Y)
        buffer.writef32(buff, cursor + 21, quaternion.Z)
        buffer.writef32(buff, cursor + 25, quaternion.W)

        return cursor + 29

    elseif typeof(value) == "table" then
        return self:writeTable(buff, cursor, value)

    end

    return cursor
end

function BufferUtil:writeTable(buff, cursor, tbl)
    buffer.writeu8(buff, cursor, TABLE_START_MARKER)
    cursor += 1

    for _, value in tbl do
        cursor = self:writeValue(buff, cursor, value)
    end

    buffer.writeu8(buff, cursor, TABLE_END_MARKER)
    return cursor + 1
end

function BufferUtil:writeNumber(buff, cursor, value)
    if value % 1 ~= 0 then
        buffer.writeu8(buff, cursor, FLOAT_MARKER)
        buffer.writef32(buff, cursor + 1, value)

        return cursor + 5
    else
        buffer.writeu8(buff, cursor, if value >= 0 then POSITIVE_INTEGER_MARKER else NEGATIVE_INTEGER_MARKER)
        buffer.writeu32(buff, cursor + 1, math.abs(value))

        return cursor + 5
    end
end



return BufferUtil