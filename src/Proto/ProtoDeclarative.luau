--!nocheck

local ProtoDeclarative = {}

local doNothing = newproxy(false)
local proxyNil = newproxy(false)
local proxyAbbreviation = "___ProtoDeclarativeProxy___"
local proxySignalAbbreviation = "___ProtoDeclarativeProxySignal___"
local proxySignalTableChanged = "____ProtoDeclarativeProxySignalTableChanged"
local proxyIsAdded = proxyAbbreviation.."Proto___ProxyIsAdded"
local metaMethodsAreSet = proxyAbbreviation.."Proto___MetaMethodsAreSet"
local inheritFromTableIndex = proxyAbbreviation.."Proto___InheritFrom"
local declareSubstitudeIndicesIndex = proxyAbbreviation.."Proto___DeclareSubstitudeIndicesIndex"
local declareSignalSubstitudeIndicesIndex = proxyAbbreviation.."Proto___DeclareSignalSubstitudeIndicesIndex"

_G.doNothing = doNothing
local Proto = _G.Proto

local signalPriorityCounter = 0


local cleanupTableLookup = {}


function ProtoDeclarative:declare(callingSelf, declare)
    local selfProxy = self:updatorProxy(callingSelf, callingSelf)
    local protoProxy = self:updatorProxy(callingSelf, Proto)

    declare(selfProxy, protoProxy)
end


function ProtoDeclarative:getCleanupTable(object)
    if cleanupTableLookup[object] then
        return cleanupTableLookup[object]
    end

    local declareCleanupTable = {}
    cleanupTableLookup[object] = declareCleanupTable

    return declareCleanupTable
end


function ProtoDeclarative:undeclareAll(object)
    local connectionsArray = cleanupTableLookup[object]
    if not connectionsArray then return end

    for _, connections in connectionsArray do
        self:disconnectConnections(connections)
    end

    table.clear(cleanupTableLookup[object])
    cleanupTableLookup[object] = nil
end



function ProtoDeclarative:setDeclarativeMetatable(object, metatable)
    if object then
        if rawget(object, proxyIsAdded) then return object end
        rawset(object, proxyIsAdded, true)
    end

    metatable = metatable or (object and getmetatable(object)) or {}

    if object and not getmetatable(object) then
        setmetatable(object, metatable)
    end

    if Proto.config.declarativeDisabled then
        return object
    end

    if rawget(metatable, metaMethodsAreSet) then return object end

    rawset(metatable, metaMethodsAreSet, true)

    self:setIndexMetaMethod(metatable)
    self:setNewIndexMetaMethod(metatable)
    self:setIteratorMetaMethod(metatable)

    return object
end






function ProtoDeclarative:setIndexMetaMethod(metatable)
    local previousIndexMetaMethod = metatable.__index
    local previousType = typeof(previousIndexMetaMethod)

    if previousType == "table" and not rawget(metatable, inheritFromTableIndex) then
        rawset(metatable, inheritFromTableIndex, previousIndexMetaMethod)
    end
    
    local function invokeMetamethod(tbl, index)
        if previousType == "table" then
            return previousIndexMetaMethod[index]
        else
            return previousIndexMetaMethod(tbl, index)
        end
    end


    metatable.__index = function(tbl, index)
        local proxyIndex = self:getProxyIndex(tbl, index)
        local proxyValue = rawget(tbl, proxyIndex)

        if proxyValue ~= nil and proxyValue ~= proxyNil then
            return proxyValue
        end

        if previousIndexMetaMethod then
            return invokeMetamethod(tbl, index)
        end

        return nil
    end
end

function ProtoDeclarative:setNewIndexMetaMethod(metatable)
    local previousNewIndexMetamethod = metatable.__newindex
    local previousType = typeof(previousNewIndexMetamethod)


    local function invokeMetamethod(tbl, index, value)
        if previousType == "table" then
            previousNewIndexMetamethod[index] = value
        else
            previousNewIndexMetamethod(tbl, index, value)
        end
    end


    metatable.__newindex = function(tbl, index, value)
        local tableChangedSignal = rawget(tbl, proxySignalTableChanged)
        local proxyIndex = self:getProxyIndex(tbl, index)
        local proxyValue = if typeof(index) == "string" then rawget(tbl, proxyIndex) else nil


        if proxyValue ~= nil then
            if proxyValue == proxyNil and previousNewIndexMetamethod then
                invokeMetamethod(tbl, index, value)

                local setValue = rawget(tbl, index)--the raw tbl[index] may have changed after invoking metamethod
                if setValue ~= nil then
                    rawset(tbl, index, nil)
                    value = setValue
                end
            end
            
            local fixedValue = value == nil and proxyNil or value

            if proxyValue ~= fixedValue then
                local proxySignalIndex = self:getProxySignalIndex(tbl, index)

                tbl[proxyIndex] = fixedValue
                tbl[proxySignalIndex]:Fire()

                if tableChangedSignal then
                    tableChangedSignal:Fire()
                end
            end

            return
        end

        if previousNewIndexMetamethod then
            local beforeValue = tbl[index]

            invokeMetamethod(tbl, index, value)

            if beforeValue ~= previousNewIndexMetamethod[index] then
                if tableChangedSignal then
                    tableChangedSignal:Fire()
                end
            end
        else
            if rawget(tbl, index) ~= value then
                rawset(tbl, index, value)

                if tableChangedSignal then
                    tableChangedSignal:Fire()
                end
            end
        end
    end
end

function ProtoDeclarative:setIteratorMetaMethod(metatable)
    metatable.__iter = function(tbl)
        return self:getCleanIterator(tbl)
    end
end





function ProtoDeclarative:getProxyIndex(object, index)
    if typeof(index) == "string" then
        return proxyAbbreviation..index
    end

    local substitudeIndices = rawget(object, declareSubstitudeIndicesIndex)
    if not substitudeIndices then
        substitudeIndices = {}
        rawset(object, declareSubstitudeIndicesIndex, substitudeIndices)
    end

    local proxyIndex = substitudeIndices[index]
    if not proxyIndex then
        proxyIndex = newproxy(false)
        substitudeIndices[index] = proxyIndex
    end

    return proxyIndex
end

function ProtoDeclarative:getProxySignalIndex(object, index)
    if typeof(index) == "string" then
        return proxySignalAbbreviation..index
    end

    local signalSubstitudeIndices = rawget(object, declareSignalSubstitudeIndicesIndex)
    if not signalSubstitudeIndices then
        signalSubstitudeIndices = {}
        rawset(object, declareSignalSubstitudeIndicesIndex, signalSubstitudeIndices)
    end

    local proxyIndex = signalSubstitudeIndices[index]
    if not proxyIndex then
        proxyIndex = newproxy(false)
        signalSubstitudeIndices[index] = proxyIndex
    end

    return proxyIndex
end



function ProtoDeclarative:updatorProxy(callingSelf, object)
    local metatable = {}
    local proxy = setmetatable({}, metatable)

    metatable.__index = function(_, index)
        local childObject = object[index]
        if childObject == nil then return nil end

        assert(typeof(childObject) == "table" or typeof(childObject) == "Instance", `Can only index for a table or Instance declare main body, index: {index}, value: {childObject}`)

        local childProxy = self:updatorProxy(callingSelf, childObject)
        rawset(proxy, index, childProxy)

        return childProxy
    end

    metatable.__newindex = function(_, index, evaluator)--setting a value
        assert(typeof(evaluator) == "function", "newindex must be set to an evaluator")

        local updatorInfo = {
            callingSelf = callingSelf,
            settingObject = object,
            settingIndex = index,
            priority = self:getPriority(),
        }

        local connections = self:connectUpdator_variable(updatorInfo, function(value)
            object[index] = value
        end, evaluator)

        table.insert(self:getCleanupTable(callingSelf), connections)
        table.insert(self:getCleanupTable(object), connections)
    end

    metatable.__call = function(_, updator, evaluator)
        assert(typeof(updator) == "function", "updator must be function")
        assert(typeof(evaluator) == "function", "evaluator must be function")
        
        local updatorInfo = {
            callingSelf = callingSelf,
            settingObject = object,
            priority = self:getPriority(),
        }

        local connections = self:connectUpdator_function(updatorInfo, updator, evaluator, true)

        table.insert(self:getCleanupTable(callingSelf), connections)
        --table.insert(self:getCleanupTable(object), connections)--object is the function and its never going to be cleaned up
    end

    return proxy
end



--evaluator is the function wrapped around the logic that returns the state

--example 1: self.instance.Visible = function() return self.visible end
--the function is the evaluator

--example 2: self({function(...) self:changeSomething(...) end, evaluator})
--the second index in the table is the evaluator because it returns a state that is fed to the updator



--updator is just the function that sets the variable or calls the function (called when return value (state) of the evaluator changes)

--example 1: self({function(...) self:changeSomething(...) end, evaluator})
--the first index in the table is the updator and it's called to update something after the evaluator changes the state

function ProtoDeclarative:connectUpdator_variable(updatorInfo, updator, evaluator)
    local previousEvaluated

    local variableSignals = {}
    local variableConnections = {}

    updatorInfo.variableSignals = variableSignals

    local function variableChanged()
        self:disconnectConnections(variableConnections)

        local selfProxy = self:evaluatorProxy(updatorInfo, updatorInfo.callingSelf)--this is a proxy for self that monitors any variables that are indexed
        local protoProxy = self:evaluatorProxy(updatorInfo, Proto)
        local evaluated = evaluator(selfProxy, protoProxy)

        local shouldUpdate = self:shouldUpdate_single(evaluated, previousEvaluated)
        previousEvaluated = evaluated

        if shouldUpdate then
            task.spawn(updator, evaluated)
        end

        self:connectSignals(variableSignals, variableConnections, variableChanged, updatorInfo.priority)
    end

    variableChanged()

    return variableConnections
end

function ProtoDeclarative:connectUpdator_function(updatorInfo, updator, evaluator)
    local previousEvaluated = {}

    local variableSignals = {}
    local variableConnections = {}

    updatorInfo.variableSignals = variableSignals

    local function variableChanged()
        self:disconnectConnections(variableConnections)

        local selfProxy = self:evaluatorProxy(updatorInfo, updatorInfo.callingSelf)--this is a proxy for self that monitors any variables that are indexed
        local protoProxy = self:evaluatorProxy(updatorInfo, Proto)

        local evaluated = {evaluator(selfProxy, protoProxy)}

        local shouldUpdate = self:shouldUpdate_tuple(evaluated, previousEvaluated)
        previousEvaluated = evaluated

        if shouldUpdate then
            task.spawn(updator, updatorInfo.callingSelf, Proto, table.unpack(evaluated))
        end

        self:connectSignals(variableSignals, variableConnections, variableChanged, updatorInfo.priority)
    end

    variableChanged()

    return variableConnections
end

function ProtoDeclarative:evaluatorProxy(updatorInfo, object, callingFirstArg)
    local metatable = {}
    local proxy = setmetatable({}, metatable)
    local children = {}

    local objectType = typeof(object)
    local objectIsTable = objectType == "table"
    local objectIsInstance = objectType == "Instance"
    local objectIsFunction = objectType == "function"

    metatable.__index = function(_, index)
        assert(objectIsTable or objectIsInstance, "tried to index something that's not a table or Instance")

        local childObject = object[index]
        local childObjectType = typeof(childObject)

        if objectIsTable then
            self:setProxyVariable(updatorInfo, object, index, childObject)
        elseif objectIsInstance then
            self:listenForPropertyChanged(updatorInfo, object, index, childObject)
        end
        

        local canContinueProxy = childObjectType == "table" or childObjectType == "Instance" or childObjectType == "function"
        if canContinueProxy then
            if not children[index] then
                local childCallingFirstArg = objectIsTable and proxy or object
                local newChild = self:evaluatorProxy(updatorInfo, childObject, childCallingFirstArg)
                children[index] = newChild
            end

            return children[index]
        end

        return childObject
    end

    metatable.__call = function(_, _, ...)
        --can call a table, will just error if it doesn't have __call metamethod
        assert(callingFirstArg and (objectIsFunction or objectIsTable), "cant call this")

        return object(callingFirstArg, ...)
    end

    --need to make mode to detect if a table is index added/removed (shallow)
    metatable.__iter = function()
        assert(objectIsTable, "can't iterate this")

        self:listenForTableChanged(updatorInfo, object)

        return self:getCleanIterator(object)
    end

    metatable.__len = function()
        assert(objectIsTable, "can't get length of this")

        self:listenForTableChanged(updatorInfo, object)

        return #object
    end

    return proxy
end

--all of this breaks if metatables change after this
--setup proxy for object[index] and listen for if it changes by also setting a signal for the index
function ProtoDeclarative:setProxyVariable(updatorInfo, object, index, childObject, setProxyValueFromCurrentValue)
    self:setDeclarativeMetatable(object)

    local metatable = getmetatable(object)
    local inheritFrom = rawget(metatable, inheritFromTableIndex)
    assert(inheritFromTableIndex ~= "function", "__index meta method cannot be a function")

    if inheritFrom then
        self:setProxyVariable(updatorInfo, inheritFrom, index, nil, true)
    end

    local proxyIndex = self:getProxyIndex(object, index)
    local signalIndex = self:getProxySignalIndex(object, index)
    local signal = rawget(object, signalIndex)

    local variableSignals = updatorInfo.variableSignals

    if signal then
        if not table.find(variableSignals, signal) then
            table.insert(variableSignals, signal)
        end

        return
    end

    local proxyValue

    if setProxyValueFromCurrentValue then
        proxyValue = rawget(object, index)
    else
        proxyValue = childObject
    end

    proxyValue = if proxyValue == nil then proxyNil else proxyValue

    rawset(object, proxyIndex, proxyValue)
    rawset(object, index, nil)

    signal = Proto.PrioritySignal:new()
    table.insert(variableSignals, signal)
    rawset(object, signalIndex, signal)
end

function ProtoDeclarative:listenForPropertyChanged(updatorInfo, instance, index, value)
    if typeof(value) == "function" then
        return--might be method so just do nothing
    end

    if index == "GetAttribute" then
        error("can't do this yet")
        return
    end

    --could add system to check if same property is indexed more than once
    --and if so only do :GetPropertyChangedSignal once, overkill..

    local rbxSignal = instance:GetPropertyChangedSignal(index)
    local signal = Proto.PrioritySignal:wrapRbxSignal(rbxSignal)

    table.insert(updatorInfo.variableSignals, signal)
end

function ProtoDeclarative:listenForTableChanged(updatorInfo, object)
    self:setDeclarativeMetatable(object)

    local tableChangedSignal = rawget(object, proxySignalTableChanged)
    local variableSignals = updatorInfo.variableSignals

    if tableChangedSignal then
        if not table.find(variableSignals, tableChangedSignal) then
            table.insert(variableSignals, tableChangedSignal)
        end

        return
    end

    tableChangedSignal = Proto.PrioritySignal:new()
    rawset(object, proxySignalTableChanged, tableChangedSignal)

    table.insert(variableSignals, tableChangedSignal)
end

function ProtoDeclarative:getCleanIterator(tbl)
    local index, value

    return function()
        while true do
            index, value = next(tbl, index)

            if index == proxySignalTableChanged then continue end
            if index == proxyIsAdded then continue end

            return index, value
        end
    end
end

function ProtoDeclarative:shouldUpdate_single(evaluation, previousEvaluation, asTuple)--see if evaluations are different
    if evaluation == doNothing or previousEvaluation == doNothing then return false end

    return evaluation ~= previousEvaluation
end

function ProtoDeclarative:shouldUpdate_tuple(evaluation, previousEvaluation)
    if typeof(evaluation) ~= "table" or typeof(previousEvaluation) ~= "table" then return true end

    for index, value in evaluation do
        if value == doNothing then return false end

        if value ~= previousEvaluation[index] then
            return true
        end
    end

    return false
end

function ProtoDeclarative:getPriority()
    signalPriorityCounter += 1
    return signalPriorityCounter
end

function ProtoDeclarative:connectSignals(signals, connections, connectionCallback, priority)
    for _, signal in signals do
        table.insert(connections, signal:Connect(connectionCallback, priority))
    end

    table.clear(signals)
end

function ProtoDeclarative:disconnectConnections(connections)
    for _, connection in connections do
        connection:Disconnect()
    end

    table.clear(connections)
end

return ProtoDeclarative