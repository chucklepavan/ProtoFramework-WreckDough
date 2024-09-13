local replicatedStorage = game:GetService("ReplicatedStorage")
local starterGui = game:GetService("StarterGui")

local protoModule = replicatedStorage.Proto

local hoarcekatSafeInstances = {
    shared = {
        "SharedUtil",
        "SharedClasses",
    },
    
    client = {
        "UI",
    }
}

local function loopInstances(cleanup, target, children)
    for _, instance in children do
        if instance:IsA("ScreenGui") then
            loopInstances(cleanup, target, instance:GetChildren())
            continue
        end

        local clone = instance:Clone()
        clone.Parent = target

        table.insert(cleanup, clone)
    end
end

return function(target)
    local protoModuleClone = protoModule:Clone()
    protoModuleClone.Parent = replicatedStorage

    local Proto = require(protoModuleClone)

    local cleanup = {}
    loopInstances(cleanup, target, starterGui:GetChildren())

    Proto:safeStart(hoarcekatSafeInstances, target)

	return function()
        protoModuleClone:Destroy()

        for _, child in cleanup do
            child:Destroy()
        end
	end
end