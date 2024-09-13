-- created on July 23rd, 2024 @TritiusDumorix
--!nolint LocalUnused 
local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
TableUtil = Proto.TableUtil

type layer_t = {
	priority: number,
	layerName: string,
	data:{[any]:any}
}

local LayerGroup = Proto:sharedClass({
	moduleName="LayerGroup",
	compilerFunc = function(compiledData, currentLayer: layer_t) 
		TableUtil:replaceDeep(compiledData, currentLayer.data)
	end
})
LayerGroup.__index = LayerGroup


function LayerGroup:init1()
	-- fires when the new data differs from the old
	self.changed = Proto.Signal.new()
	self.layers = {} :: {layer_t}
	self.oldCompiled = {}
	self.compiled = {}
end


-- compiles all layers together with the compiler function;
function LayerGroup:compile(compilerFunc: ({[any]:any}, layer_t) -> nil)
	self.oldCompiled = TableUtil:copyDeep(self.compiled)
	for i, v in ipairs(self.layers) do
		self.compilerFunc(self.compiled, v)
	end
	if not TableUtil:tablesEqualDeep(self.oldCompiled, self.compiled) then 
		self.changed:Fire(self.compiled)
	end
end 

-- sorts the layers; starting from higher priority to lesser priority
-- a higher priority will have a larger numerical value
function LayerGroup:sortLayers()
	table.sort(self.layers, function(layer0, layer1) return layer0.priority > layer1.priority end)
end 

-- inserts a layer into the layer group;
-- if a layer already has the same name as the passed in layer 
-- it will be replaced;
function LayerGroup:addLayer(layerData: layer_t)
    for i, v in ipairs(self.layers) do
		if v.layerName == layerData.layerName then
			table.remove(self.layers, i)
			break
		end 
	end
	table.insert(self.layers, layerData)
	self:sortLayers()
	self:compile()
end

-- removes the layer with the provided layerName
function LayerGroup:removeLayer(layerName: string)
    for i, v in ipairs(self.layers) do
		if v.layerName == layerName then
			table.remove(self.layers, i)
			break
		end 
	end
	self:compile()
end 

return LayerGroup