local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local BulkMove = Proto:sharedModule({
    moduleName = "BulkMove",
})

local instances = {}
local cframes = {}


function BulkMove:originTo(instance, origin)
    local cframe = origin * instance.PivotOffset:Inverse()

    table.insert(instances, instance)
    table.insert(cframes, cframe)
end

function BulkMove:cframeTo(instance, cframe)
    table.insert(instances, instance)
    table.insert(cframes, cframe)
end

function BulkMove:init1()
    Proto.RunService.Heartbeat:Connect(function()
        workspace:BulkMoveTo(instances, cframes, Enum.BulkMoveMode.FireCFrameChanged)

        table.clear(instances)
        table.clear(cframes)
    end)
end


return BulkMove