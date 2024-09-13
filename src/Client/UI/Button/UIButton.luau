local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local UIButton = Proto:clientClass({
    moduleName = "UIButton",

    classSettings = {
        disabled = false,
        isHovering = false,
        isHeldDown = false,
    },
})


Proto:actLikeSignal(UIButton)


function UIButton:init1()
    self.lastActivation = Proto.heartbeatTime
    
    Proto:declare(self, function(self, Proto)
        self.isHeldDown = function(self, Proto)
            return self.isHovering and self.mouseDown
        end
    end)

    self.maid:add(Proto.InputManager:getInputSignal("Began", false, "MouseButton1", "Touch"):Connect(function()
        self.mouseDown = true
    end))

    self.maid:add(Proto.InputManager:getInputSignal("Ended", false, "MouseButton1", "Touch"):Connect(function()
        self.mouseDown = false

        if self.isHovering then
            self:Fire()
        end
    end))

    self.instance.MouseEnter:Connect(function()
        self.isHovering = true
    end)

    self.instance.MouseLeave:Connect(function()
        self.isHovering = false
    end)
end



return UIButton