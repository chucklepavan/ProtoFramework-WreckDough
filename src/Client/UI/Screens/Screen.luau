local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local Screen = Proto:clientClass({
    moduleName = "Screen"
})


function Screen:init1()
    print("PLAYING CLOSE ANIMATION")
    self.instance.Enabled = false
    Proto.Animator:setDescendantsToTarget(self.object, "ScreenClose")
end

function Screen:open()
    self.instance.Enabled = true

    task.spawn(function()
        Proto.Animator:playDescendantsAnimationAsync(self.object, "ScreenOpen")
    end)
end

function Screen:close()
    task.spawn(function()
        local completed = Proto.Animator:playDescendantsAnimationAsync(self.object, "ScreenClose")

        if completed then
            self.enabled = false
        end
    end)
end


return Screen