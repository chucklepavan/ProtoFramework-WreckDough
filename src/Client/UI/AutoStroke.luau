local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local AutoStroke = Proto:clientClass({
    moduleName = "AutoStroke"
})

local billboardStrokes = {}
local screenStrokes = {}

local BASE_VIEWPORT_SIZE = Vector2.new(1918, 1078)
local BASE_BILLBOARD_DISTANCE = 10


function AutoStroke.static:init2()
    Proto:declare(self, function(self, Proto)
        self(function(self, Proto, ...) self:updateScreenStrokes(...) end, function(self, Proto) return Proto.Camera.ViewportSize end)
    end)

    Proto.RunService.Heartbeat:Connect(function()
        self.screenRatio = self:getScreenRatio()
        self:updateBillboardStrokes()
    end)
end

function AutoStroke.static:updateBillboardStrokes()
    for billboardGui, strokes in billboardStrokes do
        if not billboardGui.Enabled then continue end

        local adornee = billboardGui.Adornee
        local position = Proto.Math:getInstancePosition(adornee or billboardGui.Parent)
        local distanceRatio = BASE_BILLBOARD_DISTANCE / (Proto.Camera.Position - position).Magnitude

        for _, stroke in strokes do
            local newThickness = stroke.originalThickness * distanceRatio * self.screenRatio
            stroke:updateThickness(newThickness)
        end
    end
end

function AutoStroke.static:updateScreenStrokes(viewportSize)
    for _, stroke in screenStrokes do
        local newThickness = stroke.originalThickness * self.screenRatio
        stroke:updateThickness(newThickness)
    end
end

function AutoStroke.static:getScreenRatio()
    return self:getBox(Proto.Camera.viewportSize) / self:getBox(BASE_VIEWPORT_SIZE)
end

function AutoStroke.static:getBox(size)
    return math.min(size.X, size.Y)
end





function AutoStroke:updateThickness(newThickness)
    if self.lastThickness ~= newThickness then
        self.stroke.Thickness = self.originalThickness * self.screenRatio
    end
end

function AutoStroke:init1()
    local container = self.instance:FindFirstAncestorWhichIsA("LayerCollector")
    self.container = container

    self.originalThickness = self.instance.Thickness
    self.lastThickness = self.instance.Thickness

    self.instance.Thickness = self.originalThickness * self:getScreenRatio()

    if container:IsA("SurfaceGui") then
        warn("Unkown AutoStroke behavior for SurfaceGui!")

        return
    end

    if container:IsA("ScreenGui") then
        table.insert(screenStrokes, self)
        self.strokes = screenStrokes

    elseif container:IsA("BillboardGui") then
        local strokes = billboardStrokes[container]
        billboardStrokes[container] = strokes or {}

        table.insert(strokes, self)
        self.strokes = strokes
    end
end

function AutoStroke:destroying()
    table.remove(self.strokes, self)

    if #self.strokes == 0 then
        billboardStrokes[self.container] = nil
    end
end


return AutoStroke