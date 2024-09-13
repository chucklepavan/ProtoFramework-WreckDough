-- created on July 24th, 2024 @TritiusDumorix
--!nolint LocalUnused
local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local RoundDuration = Proto:serverClass({
    moduleName = "RoundDuration",
    classSettings = {
        duration = 3*60
    }
})

function RoundDuration:heartbeat(deltaTime: number)
    self.duration -= deltaTime
end

function RoundDuration:endCondition()
    return self.duration <= 0
end

return RoundDuration