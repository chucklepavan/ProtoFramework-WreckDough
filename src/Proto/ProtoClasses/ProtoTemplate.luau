local Template = {}
Template.__index = Template


local Proto = _G.Proto


function Template:objectFromTemplate(instance)
    if not instance then instance = self.instance:Clone() end

    local object = Proto:newObject(instance)

    for _, componentInfo in self.components do
        local component = Proto:newComponent(componentInfo.class, componentInfo.config)

        object:insertComponent(component)
    end

    return object
end

function Template:addComponentsToObject(object)
    for _, componentInfo in self.components do
        local component = Proto:newComponent(componentInfo.class, componentInfo.config)

        object:insertComponent(component)
    end
end

function Template:insertComponent(class, config)
    table.insert(self.components, {
        class = class,
        config = config,
    })
end




return Template