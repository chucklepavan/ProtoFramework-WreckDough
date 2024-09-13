local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local PrioritySignal = Proto:sharedClass({
    moduleName = "PrioritySignal",

    classSettings = {
        lowerPriorityFirst = true,
    },
})


local Connection = {}
Connection.__index = Connection


function PrioritySignal.static:wrapRbxSignal(rbxSignal, config)
    local signal = self:new(config)

    rbxSignal:Connect(function(...)
        signal:Fire(...)
    end)

    return signal
end




function PrioritySignal:init1()
    self.connections = {}
end

function PrioritySignal:Fire(...)
    for _, connection in self.connections do
        task.spawn(connection.func, ...)
    end
end

function PrioritySignal:Connect(func, priority)
    assert(typeof(priority) == "number", "must be number")

    local connection = setmetatable({
        signal = self,
        priority = priority,
        func = func,
    }, Connection)

    self:insertConnection(connection)

    return connection
end

function PrioritySignal:insertConnection(connection)
    local priority = connection.priority
    local connections = self.connections

    for index, otherConnection in connections do
        local otherPriority = otherConnection.priority

        local shouldInsert = if self.lowerPriorityFirst then priority <= otherPriority else priority >= otherPriority

        if shouldInsert then
            table.insert(connections, index, connection)
            return
        end
    end

    connections[#connections + 1] = connection
end

function PrioritySignal:removeConnection(connection)
    table.remove(self.connections, table.find(self.connections, connection))
end





function Connection:Disconnect()
    self.signal:removeConnection(self)
end


return PrioritySignal