local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local EffectBase = Proto:clientClass({
    moduleName = "EffectBase"
})


--need to find best way to only get effects in radius

function EffectBase:init1()
    Proto.RunService.Heartbeat:Connect(function()
        Proto.ScreenCulling:isBoundingInScreen(self.instance.CFrame, self.instance.Size / 2, self.instance.Position)
    end)
end


return EffectBase