local Object = {}
Object.__index = Object


local Proto = _G.Proto

local State = require(script.Parent.ProtoState)


function Object:init()
    if self.didInit then return end
    self.didInit = true

    Proto:objectInit(self)
end

function Object:destroy()
    if self.isDestroyed then return end
    self.isDestroyed = true

    Proto:destroyObject(self)
end

function Object:setComponentValue(variableName, value)
    self[variableName] = value

    for _, component in self.components do
        component[variableName] = value
    end
end

--same as setComponentValue but won't override a value that's already there
function Object:setComponentValueLoose(variableName, value)
    if self[variableName] == nil then
        self[variableName] = value
    end

    for _, component in self.components do
        if component[variableName] == nil then
            component[variableName] = value
        end
    end
end

--sets the component variable to nil if the value of that variable and the value provided are the same
function Object:setComponentValueNilLoose(variableName, value)
    if self[variableName] == value then
        self[variableName] = nil
    end

    for _, component in self.components do
        if component[variableName] == value then
            component[variableName] = nil
        end
    end
end

function Object:callComponentMethod(methodName, ...)
    for _, component in self.components do
        local method = component[methodName]
        if not method then continue end
       
        method(component, ...)
    end
end

-- similar to 'Object:callComponentMethod()' but returns a table
-- of all the returned values; assumes <= 1 return value per method call
function Object:invokeComponentMethod(methodName, ...)
    local returns = {}
    for _, component in self.components do
        local method = component[methodName]
        if not method then continue end
        
        local ret = method(component, ...)
        if ret ~= nil then 
            table.insert(returns, ret)
        end
    end
    return returns
end

function Object:callDescendantMethod(methodName, ...)
    for _, descendant in self.descendants do
        local method = descendant[methodName]
        if not method then continue end

        method(descendant, ...)
    end
end

-- similar to 'Object:callComponentMethod()' but returns a table
-- of all the returned values; assumes <= 1 return value per method call
function Object:invokeDescendantMethod(methodName, ...)
    local returns = {}
    for _, component in self.descendants do
        local method = component[methodName]

        local ret = method(component, ...)
        if ret ~= nil then 
            table.insert(returns, ret)
        end
    end
    return returns
end

function Object:insertComponent(component)
    component.object = self
    component.instance = self.instance

    self:setComponentValueLoose(component.className, component)

    for _, otherComponent in self.components do
        component[otherComponent.className] = otherComponent
    end

    table.insert(self.components, component)
end

function Object:removeComponent(component)
    table.remove(self.components, table.find(self.components, component))

    self:setComponentValueNilLoose(component.className, component)

    component.object = nil
    component.instance = nil
end

function Object:getComponentOfClass(class)
    class = Proto:getClass(class)

    for _, component in self.components do
        if component.class == class then
            return component
        end
    end

    return nil
end

function Object:hasComponentOfClass(class)
    local component = self:getComponentOfClass(class)

    return not not component
end

--ancestors are ordered, [1] is parent, [2] is grandparent, etc
--descendants are ordered, [1] is child, [2] is grandchild, etc

function Object:setupFamily()
    local ancestorInstance = self.instance.Parent

    while ancestorInstance do
        local object = Proto:getObjectFromInstance(ancestorInstance)
        ancestorInstance = ancestorInstance.Parent

        if not object then continue end

        if not self.parent then
            self.parent = object
            table.insert(object.children, self)
        end

        table.insert(self.ancestors, object)
        table.insert(object.descendants, self)
    end
end

function Object:setupFamilyLate()
    self:setupFamily()

    local instance = self.instance
    local parent = self.parent

    local index = 1
    while true do
        local child = parent.children[index]
        if not child then break end

        if child == self or not instance:isAncestorOf(child.instance) then--table.insert(self.descendants, descendant)
            index += 1
            continue 
        end


        table.remove(parent.children, index)

        child.parent = instance
        table.insert(self.children, child)

        table.insert(child.ancestors, 1, self)
        table.insert(self.descendants, 1, child)

        for _, descendant in child.descendants do
            table.insert(self.descendants, descendant)--DOES NOT KEEP DESCENDANT ORDER

            local childIndex = table.find(descendant.ancestors, child)
            table.insert(descendant.ancestors, childIndex + 1, self)
        end
    end
end

function Object:removeFromFamily()
    local parent = self.parent

    for _, child in self.children do
        child.parent = parent
    end

    for _, descendant in self.descendants do
        self:removeSelf(descendant.ancestors)
    end

    if parent then
        self:removeSelf(parent.children)
    end

    for _, ancestor in self.ancestors do
        self:removeSelf(ancestor.descendants)
    end

    table.clear(self.children)
    table.clear(self.descendants)
    table.clear(self.ancestors)
    self.parent = nil
end

function Object:removeSelf(tbl)
    local index = table.find(tbl, self)

    if index then
        table.remove(tbl, index)
    end
end




function Object:findDescendantWithComponentOfClass(class)
    for _, descendant in self.descendants do
        local component = descendant:getComponentOfClass(class)

        if component then
            return descendant, component
        end
    end

    return nil
end

function Object:getDescendantsWithComponentOfClass(class)
    local descendantObjects = {}
    local descendantComponents = {}

    for _, descendant in self.descendants do
        local component = descendant:getComponentOfClass(class)

        if component then
            table.insert(descendantObjects, descendant)
            table.insert(descendantComponents, component)
        end
    end

    return descendantObjects, descendantComponents
end




return Object