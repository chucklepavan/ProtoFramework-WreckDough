local RunService = game:GetService("RunService")

local ProtoValues = {}


local Proto = _G.Proto



function ProtoValues:safeStart()
    Proto.isServer = RunService:IsServer()
    Proto.isClient = RunService:IsClient()

    self:shared()

    if Proto.isServer then
        self:server()
    end

    if Proto.isClient then
        self:client()
    end
end

function ProtoValues:start()
    self:shared()

    if Proto.isServer then
        self:server()
    end

    if Proto.isClient then
        self:client()
        self:moveUI()
    end
end




function ProtoValues:shared()
    Proto.heartbeatDelta = 1 / 60
    Proto.heartbeatTime = os.clock()

    Proto.t = workspace:GetServerTimeNow()

    Proto.maid:add(Proto.RunService.Heartbeat:Connect(function(deltaTime)
        Proto.heartbeatDelta = deltaTime
        Proto.heartbeatTime = os.clock()

        Proto.t = workspace:GetServerTimeNow()
    end))

    Proto.assets = Proto.ReplicatedStorage.Assets
end

function ProtoValues:server()
    
end

function ProtoValues:client()
    Proto.renderDelta = 1 / 60
    Proto.renderTime = os.clock()

    Proto.maid:add(Proto.RunService.RenderStepped:Connect(function(deltaTime)
        Proto.renderDelta = deltaTime
        Proto.renderTime = os.clock()
    end))



    Proto.mousePosition = Vector2.new()
    Proto.mouseDelta = Vector2.new()

    Proto.maid:add(Proto.UserInputService.InputChanged:Connect(function(inputObject, gameProcessed)
        if gameProcessed then return end

        local userInputType = inputObject.UserInputType

        if userInputType == Enum.UserInputType.MouseMovement then
            Proto.mousePosition = inputObject.Position
            Proto.mouseDelta = inputObject.Delta
        end
    end))
end

function ProtoValues:moveUI()
    Proto.playerGui = Proto.player:WaitForChild("PlayerGui")

    local uiFolder = Proto.ReplicatedStorage:WaitForChild("UI")

    for _, child in uiFolder:GetChildren() do
        child.Parent = Proto.playerGui
    end

    uiFolder:Destroy()
end



return ProtoValues