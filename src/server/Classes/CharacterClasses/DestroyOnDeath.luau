local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local DestroyOnDeath = Proto:serverClass({
    moduleName = "DestroyOnDeath"
})


function DestroyOnDeath:characterLoaded()
    self.humanoid.Died:Connect(function()
        self.maid:add(coroutine.running())

        task.wait(2)

        self.playerObject.CharacterLoader:load()
    end)
end


return DestroyOnDeath