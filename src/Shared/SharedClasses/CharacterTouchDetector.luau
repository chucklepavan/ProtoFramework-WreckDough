local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local CharacterTouchDetector = Proto:sharedClass({
    moduleName = "CharacterTouchDetector",

    classSettings = {
        playerType = "all"-- or "others" or "local"
    }
})


function CharacterTouchDetector:init1()
    self.signal = Proto.Signal:new()

    self.instance.Touched:Connect(function(part)
        self:touched(part)
    end)
end

function CharacterTouchDetector:touched(part)
    local character = part.Parent
    local characterObject = Proto.ClassCharacterManager:getCharacterObject(character)
    if not characterObject then return end

    if Proto.isClient then
        if self.playerType == "local" and characterObject.player ~= Proto.player then
            return
        end

        if self.playerType == "others" and characterObject.player == Proto.player then
            return
        end
    end

    self.signal:Fire(characterObject)
end

function CharacterTouchDetector:Connect(func)
    return self.signal:Connect(func)
end


return CharacterTouchDetector