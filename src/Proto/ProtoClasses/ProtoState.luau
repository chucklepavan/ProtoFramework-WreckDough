local State = {}

--[[
local replicatedStorage = game:GetService("ReplicatedStorage")

local protoModule = replicatedStorage.Proto


function State:new()
    local proxy = {
        __index
    }

    return Proto:setDeclarativeMetatable({
        proxy = proxy
    }, proxy)
end

--]]
return State