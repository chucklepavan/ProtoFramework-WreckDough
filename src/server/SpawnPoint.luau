local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local SpawnPoint = Proto:serverClass({
    moduleName = "SpawnPoint"
})


function SpawnPoint:init1()
    
end

function SpawnPoint:teleportCharacter(characterObject)
    characterObject.rootPart.CFrame = self.instance.CFrame
end

return SpawnPoint