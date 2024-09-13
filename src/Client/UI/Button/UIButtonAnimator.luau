local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local UIButtonAnimator = Proto:clientClass({
    moduleName = "UIButtonAnimator"
})


function UIButtonAnimator:init2()
    self.spring = self.maid:add(Proto.Spring:new({
        damping = 1.5
    }))

    self.uiScale = Instance.new("UIScale")
    self.uiScale.Parent = self.instance

    Proto:declare(self, function(self, Proto)
        self.spring.target = function(self, Proto)
            if self.button.disabled then return 1 end
            if self.button.isHeldDown then return 0.9 end
            if self.button.isHovering then return 1.1 end

            return 1
        end

        self.uiScale.Scale = function(self, Proto)
            return self.spring.value
        end
    end)
end


return UIButtonAnimator