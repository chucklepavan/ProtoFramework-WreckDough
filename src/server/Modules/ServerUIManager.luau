local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local ServerUIManager = Proto:serverModule({
    moduleName = "ServerUIManager",
})


function ServerUIManager:init1()
    local uiFolder = Instance.new("Folder")
    uiFolder.Name = "UI"
    uiFolder.Parent = Proto.ReplicatedStorage

    for _, child in Proto.StarterGui:GetChildren() do
        if child:IsA("ScreenGui") then
            child.ResetOnSpawn = false
        end

        child.Parent = uiFolder
    end
end


return ServerUIManager