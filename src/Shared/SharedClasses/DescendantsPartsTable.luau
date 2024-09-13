local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local DescendantsPartsTable = Proto:sharedClass({
    moduleName = "DescendantsPartsTable",

    classSettings = {
        tableName = nil
    },

    tablesLookup = {}
})


function DescendantsPartsTable:init1()
    assert(self.tableName, "tableName must be set")

    self.table = self:getTable(self.tableName)

    for _, instance in self.instance:GetDescendants() do
        self:processInstance(instance)
    end

    self.instance.DescendantAdded:Connect(function(instance)
        self:processInstance(instance)
    end)

    self.instance.DescendantRemoving:Connect(function(instance)
        self:removeInstance(instance)
    end)
end

function DescendantsPartsTable:processInstance(instance)
    if not instance:IsA("BasePart") then return end

    table.insert(self.table, instance)
end

function DescendantsPartsTable:removeInstance(instance)
    if not instance:IsA("BasePart") then return end

    local index = table.find(self.table, instance)

    if index then
        table.remove(self.table, index)
    end
end

function DescendantsPartsTable.static:getTable(tableName)
    local table = self.tablesLookup[tableName]

    if not table then
        table = {}
        self.tablesLookup[tableName] = table
    end

    return table
end

function DescendantsPartsTable.static:getRaycastParams(tableName, include)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = self:getTable(tableName)
    raycastParams.FilterType = include and Enum.RaycastFilterType.Include or Enum.RaycastFilterType.Exclude

    return raycastParams
end



return DescendantsPartsTable