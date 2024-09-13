local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local CharacterLoader = Proto:serverClass({
    moduleName = "CharacterLoader"
})


function CharacterLoader:load()
    self.maid:add(task.spawn(function()
        self.instance:LoadCharacter()
    end))
end

function CharacterLoader:loadAndGetCharacterObject()
    self.instance:LoadCharacter()

    return self.instance.Character
end


return CharacterLoader