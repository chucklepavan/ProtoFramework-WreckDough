local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local ObbyChoice = Proto:clientClass({
    moduleName = "ObbyChoice"
})


function ObbyChoice:init1()
    self.background = self.instance:WaitForChild("Background")
    --self.image = self.instance:WaitForChild("Image")

    local _, button = self.object:findDescendantWithComponentOfClass("UIButton")

    button:Connect(function()
        print("CLICKED", self.instance.Name)
    end)
end


return ObbyChoice