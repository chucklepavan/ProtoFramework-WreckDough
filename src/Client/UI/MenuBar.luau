local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local MenuBar = Proto:clientClass({
    moduleName = "MenuBar",
})


function MenuBar:init1()
    self.tween = Proto.Tween({
        style = Enum.EasingStyle.Sine,
        direction = Enum.EasingDirection.InOut,
        length = 0.2,
    })

    Proto:declare(function()
        self.tween.target = self.menuIsOpen and Vector2.new(0.5, 0) or Vector2.new(0.5, -1)
        self.instance.AnchorPoint = self.tween.value
    end)
end


return MenuBar