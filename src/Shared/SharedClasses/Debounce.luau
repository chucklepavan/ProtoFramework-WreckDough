local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local Debounce = Proto:sharedClass({
    moduleName = "Debounce",

    classSettings = {
        cooldown = 1,

        lastActivate = 0,
    },
})


function Debounce:try()
    local now = os.clock()

    if now - self.lastActivate > self.cooldown then
        self.lastActivate = now
        return true
    end

    return false
end


return Debounce