local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local Selectable = Proto:clientClass({
    moduleName = "Selectable",

    classSettings = {
        onlySelectOneAtATime = true,
        useHighlight = true,
    }
})


local instanceLookup = {}


local currentHovering
local currentSelected = {}


function Selectable.static:init1()
    Proto.RunService.Heartbeat:Connect(function()
        local raycastParams = Proto.DescendantsPartsTable:getRaycastParams("characterParts")

        local result = Proto.Math:raycastInMouseDirection(raycastParams)
        local instance = result and result.Instance

        if not instance then return end

        local selectable = self:findSelectableAncestor(instance)

        if not selectable then
            self:unhoverAll()

            return 
        end

        selectable:hover()
    end)

    Proto.InputManager:getInputSignal("Began", false, "MouseButton1"):Connect(function()
        if currentHovering then
            currentHovering:select()
        end
    end)
end

function Selectable:hover()
    if currentHovering == self then return end

    if currentHovering then
        currentHovering.hovering = false
    end

    self.hovering = true
    currentHovering = self
end

function Selectable.static:unhoverAll()
    if currentHovering then
        currentHovering.hovering = false
        currentHovering = nil
    end
end

function Selectable:select()
    if self.selected then return end

    if self.onlySelectOneAtATime then
        self:deselectAll()
    end

    self.selected = true
    table.insert(currentSelected, self)
end

function Selectable.static:deselectAll()
    for _, selectable in currentSelected do
        selectable.selected = false
    end
    
    table.clear(currentSelected)
end

function Selectable:init1()
    print("INITTED")
    instanceLookup[self.instance] = self

    self.hovering = false
    self.selected = false

    if self.useHighlight then
        self:setupHighlight()
    end
end

function Selectable:setupHighlight()
    self.highlight = Instance.new("Highlight")
    self.highlight.Adornee = self.instance
    self.highlight.Parent = self.instance

    Proto:declare(self, function(self, Proto)
        self.highlight.OutlineTransparency = function(self, Proto)
            return self.hovering and 0 or 1
        end

        self.highlight.FillTransparency = function(self, Proto)
            return self.selected and 0.5 or 1
        end
    end)
end

function Selectable.static:findSelectableAncestor(instance)
    while instance and instance ~= game do
        local selectable = instanceLookup[instance]

        if selectable then
            return selectable
        end

        instance = instance.Parent
    end

    return nil
end


return Selectable