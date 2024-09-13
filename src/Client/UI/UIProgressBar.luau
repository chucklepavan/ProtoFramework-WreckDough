local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local UIProgressBar = Proto:clientClass({
    moduleName = "UIProgressBar",

    classSettings = {
        value = 1,
    }
})


function UIProgressBar:init1()
    local defaultYScale = self.bar.Size.Y.Scale

    Proto:declare(self, function(self, Proto)
        self.bar.Size = function(self, Proto)
            return UDim2.fromScale(self.value, defaultYScale)
        end
    end)
end


return UIProgressBar