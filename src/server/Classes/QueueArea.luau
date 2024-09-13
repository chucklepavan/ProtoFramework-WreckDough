local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local QueueArea = Proto:serverClass({
    moduleName = "QueueArea",

    classSettings = {
        playerCountText = nil,
        timerText = nil,
    },
})


function QueueArea:init1()
    self.timer = Proto.Timer:new()
end


return QueueArea