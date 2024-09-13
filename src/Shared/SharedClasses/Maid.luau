local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint

local Maid = Proto:external({}, "Maid")
Maid.__index = Maid


function Maid:new()
    return setmetatable({
        objects = {},
    }, Maid)
end

function Maid:extend()
    local maid = self:new()
    self:add(maid)

    return maid
end



function Maid:clean()
    for _, object in self.objects do
        local cleanupFunction = self:getCleanupFunction(object)
        cleanupFunction(object)
    end

    table.clear(self.objects)
end

function Maid:add(object)
    self:getCleanupFunction(object)--test for if you can clean it up but don't do anything with it
    table.insert(self.objects, object)

    return object
end

function Maid:remove(object)
    local index = table.find(self.objects, object)
    if index then
        table.remove(self.objects, object)
    end
end

function Maid:signal(signal, callback)
    self:add(signal:Connect(callback))
end





function Maid:getCleanupFunction(object)
    local typeString = typeof(object)

    if typeString == "RBXScriptConnection" then
        return object.Disconnect

    elseif typeString == "Instance" then
        return object.Destroy

    elseif typeString == "table" then
        return self:getTableCleanupFunction(object)

    elseif typeString == "function" then
        return object

    elseif typeString == "thread" or typeString == "coroutine" then
        return coroutine.close

    end

    error("no cleanup function found for object: ", object)
end

function Maid:getTableCleanupFunction(tbl)
    if getmetatable(tbl) == Maid then
        return tbl.clean
    end

    if typeof(tbl.Disconnect) == "function" then
        return function()
            tbl:Disconnect()

            if tbl.destroy then
                tbl:destroy()
            end
        end

    elseif typeof(tbl.destroy) == "function" then
        return tbl.destroy

    end

    error("no cleanup function found for table: ", tbl)
end


return Maid