local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local Camera = Proto:clientModule({
    moduleName = "Camera",
})



function Camera:init1()
    self.camera = workspace.CurrentCamera

    Proto:declare(self, function(self, Proto)
        self.viewportSize = function(self, Proto)
            return self.camera.ViewportSize
        end
    end)

    Proto.RunService.Heartbeat:Connect(function()
        self.cframe = self.camera.CFrame
        self.position = self.cframe.Position
    end)
end



return Camera