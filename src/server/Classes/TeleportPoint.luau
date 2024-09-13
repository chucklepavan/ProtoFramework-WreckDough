local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint

local TeleportPoint = Proto:serverClass({
    moduleName = "TeleportPoint",

    classSettings = {
        category = nil,
    },
})

local categories = {}



function TeleportPoint:init1()    
    self.instance.Transparency = 1
    self.instance:WaitForChild("Decal"):Destroy()

    local spawnCFrame = self.instance.CFrame - Vector3.yAxis * (self.instance.Size.Y / 2)

    categories[self.category] = categories[self.category] or {}
    table.insert(categories[self.category], spawnCFrame)
end

function TeleportPoint.static:moveCharacter(categoryName, characterObject)
    local spawnCFrames = categories[categoryName]
    local spawnCFrame = spawnCFrames[math.random(1, #spawnCFrames)]

    local characterHeightOffset = Vector3.yAxis * (characterObject.humanoid.HipHeight / 2)

    characterObject.instance:PivotTo(spawnCFrame + characterHeightOffset)
end


return TeleportPoint