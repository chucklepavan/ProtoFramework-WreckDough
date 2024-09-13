local ProtoClasses = {
    classes = {},
}

local Proto = _G.Proto

local Object = require(script.Parent.ProtoObject)
local Template = require(script.Parent.ProtoTemplate)

local objectLookup = {}
local componentFolders = {}
local templateLookup = {}

local didInitialFamilySetup = false

local IS_CLASS = newproxy()
local IS_OBJECT = newproxy()
local IS_TEMPLATE = newproxy()
local IS_COMPONENT = newproxy()



function ProtoClasses:newComponent(class, config, shouldInit)
    assert(class, "No class provided")
    assert(Proto.didRequireModules, "Cannot create component before init started")

    class = self:getClass(class)

    local component = Proto:setDeclarativeMetatable({
        class = class,
        className = class.moduleName,

        maid = Proto.Maid:new(),
        [IS_COMPONENT] = true,
    }, class)

    if config then
        for settingName, value in config do
            if component[settingName] == nil then
                component[settingName] = value
            end
        end
    end

    if class.classSettings then
        for settingName, defaultValue in class.classSettings do
            if config and config[settingName] ~= nil then
                component[settingName] = config[settingName]
            else
                component[settingName] = defaultValue
            end
        end
    end

    if class.actLikeSignal then
        component.signal = Proto.Signal:new()
        component.lastFired = 0
    end

    table.insert(class.components, component)
    if shouldInit then
        Proto:componentInit(component)
    end

    return component
end

function ProtoClasses:componentDestroyLogic(component)--is and should only be used as abstraction for component:destroy()
    table.remove(component.class.components)
    component.maid:clean()

    Proto:undeclareAll(component)

    if component.destroying then
        component:destroying()
    end
end

function ProtoClasses:isComponent(component)
    return typeof(component) == "table" and not not component[IS_COMPONENT]
end




--need to allow function metamethods
--then only create a maid when its used in the component

function ProtoClasses:newObject(instance)
    assert(not self:getObjectFromInstance(instance), "Object already exists")

    local object = Proto:setDeclarativeMetatable({
        instance = instance,
        components = {},
        namedComponents = {},

        parent = nil,
        ancestors = {},
        children = {},
        descendants = {},

        [IS_OBJECT] = true,

        maid = Proto.Maid:new()
    }, Object)

    objectLookup[instance] = object

    object.maid:signal(instance.Destroying, function()
        object:destroy()
    end)

    if didInitialFamilySetup then
        object:setupFamilyLate()
    end

    return object
end

function ProtoClasses:newTemplate(instance)
    local template = Proto:setDeclarativeMetatable({
        instance = instance,
        components = {},

        [IS_TEMPLATE] = true
    }, Template)

    templateLookup[instance.Name] = template
    instance.Parent = script

    return template
end


function ProtoClasses:cloneFromTemplate(templateName, parent)
    local template = templateLookup[templateName]
    assert(template, `No template of name ${templateName}`)

    local instance = template.instance:Clone()
    instance.Parent = parent

    return self:objectFromTemplate(templateName, instance)
end


--instance is optional
function ProtoClasses:objectFromTemplate(templateName, instance)
    local template = templateLookup[templateName]
    assert(template, `No template of name ${templateName}`)

    local object = template:objectFromTemplate(instance)
    object:init()

    return object
end

function ProtoClasses:addTemplateComponentsToObject(object, templateName)
    local template = templateLookup[templateName]
    assert(template, `No template of name ${templateName}`)

    template:addComponentsToObject(object)
end

function ProtoClasses:destroyObject(object)
    object.maid:clean()
    Proto:undeclareAll(object)

    for _, component in object.components do
        component:destroy()
    end

    objectLookup[object.instance] = nil
    
    object:removeFromFamily()
end

function ProtoClasses:isObject(object)
    return typeof(object) == "table" and not not object[IS_OBJECT]
end



local objectComponents = {}

function ProtoClasses:componentFolderAdded(folder)
    local config = {}

    for _, child in folder:GetChildren() do
        if child:IsA("Configuration") then
            config[child.Name] = child:GetAttribute("Value")
        elseif child:IsA("ValueBase") then
            config[child.Name] = child.Value
        else
            error("Invalid child in component folder", child:GetFullName())
        end
    end

    componentFolders[folder] = config
    
    local instanceParent = folder.Parent
    while instanceParent:IsA("Folder") do
        instanceParent = instanceParent.Parent
    end

    print(instanceParent)

    objectComponents[instanceParent] = objectComponents[instanceParent] or {}
    table.insert(objectComponents[instanceParent], folder)
end

function ProtoClasses:initComponentFolders()
    for instance, folders in objectComponents do
        if instance:HasTag("ProtoTemplate") then

            local template = self:newTemplate(instance)

            for _, folder in folders do
                local class, config = self:getInfoFromComponentFolder(folder)
                if not class then continue end
                
                template:insertComponent(class, config)
            end
        else

            local object = self:newObject(instance)

            for _, folder in folders do
                local class, config = self:getInfoFromComponentFolder(folder)
                if not class then continue end
                
                local component = self:newComponent(class, config)
                componentFolders[folder] = component

                object:insertComponent(component)
            end
    
            object:init()
        end
    end

    for _, component in componentFolders do
        self:connectComponentVariables(component)
    end
end

function ProtoClasses:connectComponentVariables(component)
    for index, value in component do
        if index == "object" or index == "instance" then continue end

        local otherComponent = componentFolders[value]
        if otherComponent then
            component[index] = otherComponent
        end
    end
end

function ProtoClasses:getInfoFromComponentFolder(folder)
    local class = self:getClass(folder.Name)
    if not class then return end

    local config = componentFolders[folder]
    assert(class, "Invalid class for component folder "..folder:GetFullName())

    return class, config
end


function ProtoClasses:getObjectFromInstance(instance)
    return objectLookup[instance]
end

function ProtoClasses:getComponentFromInstance(instance, class)
    local object = self:getObjectFromInstance(instance)

    if object then
        return object:getComponentOfClass(class)
    end

    return nil
end





function ProtoClasses:newClass(class)
    self.classes[class.moduleName] = class

    class[IS_CLASS] = true
    class.static = {}
    class.components = {}

    class.__index = class
end

function ProtoClasses:getClass(class)
    return if typeof(class) == "string" then self.classes[class] else class
end

function ProtoClasses:isClass(class)
    return typeof(class) == "table" and not not class[IS_CLASS]
end



function ProtoClasses:safeStart(classInstanceBase)
    if not classInstanceBase then return end

    self:newObject(game)

    self:setupAllFamilies()
end
--TODO: let you make folder so you can have tables of settings in component settings
function ProtoClasses:start()
    for _, instance in Proto.CollectionService:GetTagged("ProtoTemplate") do
        self:newTemplate(instance)
    end

    local tagName = Proto.isServer and "ServerComponent" or "ClientComponent"

    for _, instance in Proto.CollectionService:GetTagged(tagName) do
        self:componentFolderAdded(instance)
    end

    self:newObject(game)

    self:initComponentFolders()
    self:setupAllFamilies()
end

--breadth first search (in relation to objects, not instances) starting with the top most instance (game) and going down
--done so that object.descendants are put in the right order when everything is created
function ProtoClasses:setupAllFamilies()
    local queue = {game}

    while true do
        local instance = table.remove(queue)
        if not instance then break end

        local object = self:getObjectFromInstance(instance)
        local children = instance:GetChildren()

        if object then
            object:setupFamily()

            table.move(children, 1, #children, #queue + 1, queue)
        else
            for _, child in children do
                table.insert(queue, 1, child)
            end
        end
    end

    didInitialFamilySetup = true
end





return ProtoClasses