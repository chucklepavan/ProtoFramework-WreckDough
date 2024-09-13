local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local FollowMouse = Proto:clientClass({
    moduleName = "FollowMouse",
})


function FollowMouse:init1()
    self.spring = self.maid:add(Proto.Spring:new({
        value = self.instance.Position,
    }))

    Proto:declare(self, function(self, Proto)
        self.spring.target = function(self, Proto)
            return UDim2.fromOffset(
                Proto.mousePosition.X,
                Proto.mousePosition.Y
            )
        end

        self.instance.Position = function(self, Proto) return self.spring.value end
    end)
end


return FollowMouse