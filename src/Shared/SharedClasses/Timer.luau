local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local Timer = Proto:sharedClass({
    moduleName = "Timer",

    classSettings = {
        length = 1,
        fireOnStart = false,
    },
})


Proto:actLikeSignal(Timer)


function Timer:init1()
    self.signal = Proto.Signal:new()

    if self.fireOnStart then
        self:Fire()
    end

    task.spawn(function()
        self.maid:add(coroutine.running())

        self.startTime = Proto.t

        while task.wait(self.length) do
            self:Fire()
        end
    end)

    Proto:declare(self, function(self, Proto)
        self.timeLeft = function(self, Proto)
            return self.length - (Proto.t - self.startTime)
        end
    end)
end

function Timer:pause()

end


return Timer