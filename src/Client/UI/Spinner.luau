local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint

local Spinner = Proto:clientClass({
    moduleName = "Spinner",

    classSettings = {
        speed = 0.5,

        playing = true,
    }
})

function Spinner:start()
    self.playing = true
end

function Spinner:stop()
    self.playing = false
end

function Spinner:init1()
    Proto:declare(self, function(self, Proto)
        self.instance.Rotation = function(self, Proto)
            if not self.playing then return doNothing end

            local angle = Proto.Timer.time * self.speed * 360
            return angle % 360
        end
    end)
end

return Spinner