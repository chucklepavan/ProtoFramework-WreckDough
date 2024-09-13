local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local InputManager = Proto:clientModule({
    moduleName = "InputManager",

    frameStart = 0,

    eventLookup = {},
    inputEvents = {},
})


local platformLookup = {
    MouseButton1 = "PC",
    MouseButton2 = "PC",
    MouseButton3 = "PC",
    MouseMovement = "PC",
    MouseWheel = "PC",
    Keyboard = "PC",

    Touch = "Mobile",
    Accelerometer = "Mobile",
    Gyro = "Mobile",

    Gamepad1 = "Gamepad",
    Gamepad2 = "Gamepad",
    Gamepad3 = "Gamepad",
    Gamepad4 = "Gamepad",
    Gamepad5 = "Gamepad",
    Gamepad6 = "Gamepad",
    Gamepad7 = "Gamepad",
    Gamepad8 = "Gamepad",
}


local frameStartTable



--adding custom input things like:
--axis 2D which is wasd movement, vec2 or vec with no y
-- 3d which is wasdeq for like helicopter controls, vec3


function InputManager:init1()
    frameStartTable = Proto.SharedTableRegistry:GetSharedTable("FrameStart", frameStartTable)

    self:typeChanged(Proto.UserInputService:GetLastInputType())

    Proto.UserInputService.LastInputTypeChanged:Connect(function(inputType)
        self:typeChanged(inputType.Name)
    end)

    Proto.UserInputService.InputBegan:Connect(function(inputObject, gameProcessed)
        self:inputFrameStart()
        self:inputReceived("Began", inputObject, gameProcessed)
    end)

    Proto.UserInputService.InputEnded:Connect(function(inputObject, gameProcessed)
        self:inputFrameStart()
        self:inputReceived("Ended", inputObject, gameProcessed)
    end)

    Proto.UserInputService.InputChanged:Connect(function(inputObject, gameProcessed)
        self:inputFrameStart()
        self:inputReceived("Changed", inputObject, gameProcessed)
    end)

    Proto.RunService:BindToRenderStep("frame start", -100000, function()
        self:renderStepFrameStart()
    end)
end

function InputManager:renderStepFrameStart()
    if not self.setFrameStartInInput then
        self.frameStart = os.clock() - 0.0002
        frameStartTable.frameStart = self.frameStart
    end

    self.setFrameStartInInput = false
end

function InputManager:inputFrameStart()
    if not self.setFrameStartInInput then
        self.frameStart = os.clock()
        frameStartTable.frameStart = self.frameStart

        self.setFrameStartInInput = true
    end
end


function InputManager:getInputSignal(state, receiveGameProcessed, ...)
    return self:getInputSignalFromTable(state, receiveGameProcessed, {...})
end

function InputManager:getInputSignalFromTable(state, receiveGameProcessed, inputs)
    assert(typeof(state) == "string", "state arg must be a string")
    assert(typeof(receiveGameProcessed) == "boolean", "receiveGameProccessed arg must be a boolean")
    assert(typeof(inputs) == "table", "inputs must be an array")

    local inputString, sorted = self:getInputString(state, receiveGameProcessed, inputs)
    local event = self.eventLookup[inputString]

    if not event then
        event = Proto.Signal.new()
        self.eventLookup[inputString] = event

        self.inputEvents[event] = {
            receiveGameProcessed = receiveGameProcessed,
            inputs = #sorted > 0 and sorted,
            state = state,
        }
    end

    return event
end




function InputManager:inputReceived(state, inputObject, gameProcessed)
    local typeName = inputObject.UserInputType.Name
    local keyName = inputObject.KeyCode.Name

    for event, eventInfo in self.inputEvents do
        if eventInfo.state ~= state then continue end
        if gameProcessed and not eventInfo.receiveGameProcessed then continue end

        if not eventInfo.inputs then
            event:Fire()
        end

        for _, input in eventInfo.inputs do
            if input == typeName or input == keyName then
                event:Fire(input, inputObject)
                break
            end
        end
    end
end

function InputManager:typeChanged(inputType)
    local platform = platformLookup[inputType]
    if not platform then return end

    self.platform = platform
end

function InputManager:getInputString(state, receiveGameProcessed, inputs)
    local sorted = table.clone(inputs)
    table.sort(sorted)

    local inputString = state.."_"..tostring(receiveGameProcessed).."_"

    for _, value in sorted do
        inputString ..= value.."_"
    end

    return inputString, sorted
end


return InputManager