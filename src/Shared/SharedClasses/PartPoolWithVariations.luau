local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local PartPoolWithVariations = Proto:sharedClass({
    moduleName = "PartPoolWithVariations"
})


--right now only variation allowed is color
--eventually need to make pools share parts if one pool is empty, and change properties of shared parts


function PartPoolWithVariations.static:new(new, config)
    local component = new()
    component.config = config or {}

    return component
end


function PartPoolWithVariations:init1()
    self.pools = {}
    self.colors = {}
end

function PartPoolWithVariations:getColorIndex(color)
    local colorIndex = table.find(self.colors, color)
    if colorIndex then return colorIndex end

    table.insert(self.colors, color)

    local config = table.clone(self.config)
    config.clonePart = if config.clonePart then config.clonePart else Proto.assets.DefaultPoolPart
    config.clonePart = config.clonePart:Clone()
    config.clonePart.Color = color

    table.insert(self.pools, Proto.PartPool:new(config))

    return #self.colors
end

function PartPoolWithVariations:getPart(colorIndex)
    local pool = self.pools[colorIndex]

    return pool:getPart()
end

function PartPoolWithVariations:releasePart(part, colorIndex)
    local pool = self.pools[colorIndex]

    pool:releasePart(part)
end

function PartPoolWithVariations:moveHolding()
    for _, pool in self.pools do
        pool:moveHolding()
    end
end



return PartPoolWithVariations