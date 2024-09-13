local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local PartPool = Proto:sharedClass({
    moduleName = "PartPool",

    classSettings = {
        minimum = 0,
        maximum = 5000,
        maxPerFrame = 15,

        clonePart = nil,
    },
})


local SKY_CFRAME = CFrame.new(0, 1000000, 0)

local POOL_PARTS_FOLDER

function PartPool.static:init1()
    if Proto.isClient then
        POOL_PARTS_FOLDER = workspace:WaitForChild("PoolParts")
        return
    end

    POOL_PARTS_FOLDER = Instance.new("Model")
    POOL_PARTS_FOLDER.Name = "PoolParts"
    POOL_PARTS_FOLDER.Parent = workspace
end

function PartPool.static:init2()
    Proto.RunService.Heartbeat:Connect(function()
        self:update()
    end)
end


function PartPool:init1()
    self.pool = {}
    self.holding = {}

    if not self.clonePart then
        self.clonePart = Instance.new("Part")
        self.clonePart.Anchored = true
        self.clonePart.CanCollide = false
        self.clonePart.CanQuery = false
        self.clonePart.Size = Vector3.new(1, 1, 1)
    end

    self.clonePart.CFrame = SKY_CFRAME
end

function PartPool:getPart()
    if #self.holding > 0 then
        return table.remove(self.holding)
    elseif #self.pool > 0 then
        return table.remove(self.pool)
    else
        return self:createPart()
    end
end

function PartPool:releasePart(part)
    table.insert(self.holding, part)
end

function PartPool:moveHolding()
    for _, part in self.holding do
        Proto.BulkMove:cframeTo(part, SKY_CFRAME)
    end

    table.move(self.holding, 1, #self.holding, #self.pool + 1, self.pool)
end



function PartPool:update()
    local needToCreate = math.clamp(self.minimum - #self.pool, 0, self.maxPerFrame)

    if needToCreate > 0 then
        self:createCount(needToCreate)
        return
    end

    local needToDestroy = math.clamp(#self.pool - self.maximum, 0, self.maxPerFrame)

    if needToDestroy > 0 then
        self:destroyCount(needToDestroy)
    end
end

function PartPool:createCount(count)
    for _ = 1, count do
        table.insert(self.pool, self:createPart())
    end
end

function PartPool:destroyCount(count)
    for _ = 1, count do
        local part = table.remove(self.pool)
        part:Destroy()
    end
end

function PartPool:createPart()
    local part = self.clonePart:Clone()
    part.Parent = POOL_PARTS_FOLDER

    return part
end




return PartPool