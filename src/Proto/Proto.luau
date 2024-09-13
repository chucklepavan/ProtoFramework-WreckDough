local RunService = game:GetService("RunService")

local Proto = {
    modules = {},
    actorScripts = {},
    config = {},
}
_G.Proto = Proto

local ProtoValues = require(script.ProtoValues)
local ProtoDeclarative = require(script.ProtoDeclarative)
local ProtoNetwork = require(script.ProtoNetwork)
local ProtoParallel = require(script.ProtoParallel)
local ProtoClasses = require(script.ProtoClasses)
local ProtoPlayerUtil = require(script.ProtoPlayerUtil)

Proto.classes = ProtoClasses.classes


local SHARED_MODULES_LOCATION
local SERVER_MODULES_LOCATION
local CLIENT_MODULES_LOCATION

local IS_MODULE = newproxy()



function Proto:safeStart(config)
    if self.started then return end
    self.started = true

    self.isSafeMode = true

    self.config = config
    self:setup()

    assert(config.safeDirectories, "config.safeDirectories missing")
    self:requireDirectories(config.safeDirectories)
    self.didRequireModules = true

    self:createMaid()

    if config.initProtoValues then
        ProtoValues:safeStart()
    end

    self:collectInitFunctions()
    self:validateMethods()

    ProtoClasses:safeStart(config.classInstanceBase)

    self:safeInit()
end

function Proto:start()
    if self.started then return end
    self.started = true

    self:setup()
    
    if self.isServer then
        self:requireDescendants(SERVER_MODULES_LOCATION)
    else
        self:requireDescendants(CLIENT_MODULES_LOCATION)
    end
    self:requireDescendants(SHARED_MODULES_LOCATION)
    self.didRequireModules = true

    self:createMaid()

    ProtoValues:start()
    
    

    self:collectInitFunctions()
    self:validateMethods()

    ProtoParallel:start()
    ProtoNetwork:start()
    
    if self.isClient then
        self.LoadingController:load()
    end

    ProtoClasses:start()

    self:init()
end

function Proto:setup()--make maid and add connections to it so hoarcekat doesn't keep connections
    self:takeMethods(ProtoDeclarative)
    self:takeMethods(ProtoPlayerUtil)
    self:takeMethods(ProtoClasses)

    for _, service in game:GetChildren() do
        self[service.Name] = service
    end

    self.RunService = self["Run Service"]

    self.player = self.Players.LocalPlayer

    self.isServer = self.RunService:IsServer()
    self.isClient = self.RunService:IsClient()

    SHARED_MODULES_LOCATION = self.ReplicatedStorage.Shared

    if self.isServer then
        SERVER_MODULES_LOCATION = self.ServerScriptService.Server
    else
        CLIENT_MODULES_LOCATION = self.Players.LocalPlayer.PlayerScripts.Client
    end
end

function Proto:createMaid()
    self.maid = self.Maid:new()
    script.Destroying:Connect(function()
        self.maid:clean()
    end)
end

function Proto:takeMethods(module)
    for name, func in module do
        if typeof(func) ~= "function" or name == "start" or name == "safeStart" then continue end

        self[name] = function(_, ...)
            return func(module, ...)
        end
    end
end



function Proto:clientClass(class)
    assert(RunService:IsClient(), "Cannot create client class from the server!")

    self:module(class)
    ProtoClasses:newClass(class)
    ProtoNetwork:setupModule(class)
    ProtoParallel:setupModule(class)

    return class
end

function Proto:serverClass(class)
    assert(RunService:IsServer(), "Cannot create server class from the client!")

    self:module(class)
    ProtoClasses:newClass(class)
    ProtoNetwork:setupModule(class)
    ProtoParallel:setupModule(class)

    return class
end

function Proto:sharedClass(class)
    self:module(class)
    ProtoClasses:newClass(class)
    ProtoNetwork:setupModule(class)
    ProtoParallel:setupModule(class)

    return class
end

function Proto:clientModule(module)
    assert(RunService:IsClient(), "Cannot create client module from the server! ")

    self:module(module)
    ProtoNetwork:setupModule(module)
    ProtoParallel:setupModule(module)

    return module
end

function Proto:serverModule(module)
    assert(RunService:IsServer(), "Cannot create server class from the client!")

    self:module(module)
    ProtoNetwork:setupModule(module)
    ProtoParallel:setupModule(module)

    return module
end

function Proto:sharedModule(module)
    self:module(module)
    ProtoNetwork:setupModule(module)
    ProtoParallel:setupModule(module)

    return module
end

function Proto:module(module)
    assert(module, "module missing config")
    assert(module.moduleName, "module missing name")

    if self[module.moduleName] then
        error(`module cannot use name "{module.moduleName}" because its already in use`)
    end

    self[module.moduleName] = module
    self.modules[module.moduleName] = module

    module[IS_MODULE] = true
end

function Proto:external(external, name)
    if self[name] then
        error(`external cannot use name "{name}" because its already in use`)
    end

    self[name] = external
    return external
end

function Proto:actor(scriptName)
    local actor = Instance.new("Actor")
    actor.Name = scriptName

    local script = self.actorScripts[scriptName]:Clone()
    script.Parent = actor

    script.Enabled = true

    return actor
end

function Proto:actLikeSignal(class)
    assert(self:isClass(class), "actLikeSignal can only be used on classes")

    class.actLikeSignal = true

    function class:Connect(func)
        --print(self)
        return self.signal:Connect(func)
    end

    function class:Fire(...)
        self.lastFired = os.clock()
        return self.signal:Fire(...)
    end
end

function Proto:isModule(module)
    return module[IS_MODULE]
end




function Proto:collectInitFunctions()
    self.nonStaticInitQueue = {}
    self.initQueue = {}
    self.componentsToInit = {}
    self.initIndex = 0

    for _, module in self.modules do
        local locations = {
            module = module,

            static = module.static,--if its a module, this will be nil

            actor = module.actor,
        }

        for locationName, location in locations do
            for name, func in location do
                if typeof(func) ~= "function" then continue end

                local index = tonumber(string.match(name, "^init(%d+)$"))
                if not index or index < 1 or index > 1000 then continue end

                location[name] = nil

                if locationName == "actor" then continue end

                local isStatic = not (self:isClass(module) and locationName == "module")

                local functionInfo = {
                    module = module,
                    func = func,

                    index = index,
                    isStatic = isStatic,
                }

                table.insert(self.initQueue, functionInfo)

                if not isStatic then
                    self.nonStaticInitQueue[module] = self.nonStaticInitQueue[module] or {}
                    table.insert(self.nonStaticInitQueue[module], functionInfo)
                end
            end
        end
    end

    table.sort(self.initQueue, function(a, b)--can still sort if functionInfo is static/not
        local priorityA = a.index * 1000 + (a.isStatic and 0 or 1)
        local priorityB = b.index * 1000 + (b.isStatic and 0 or 1)

        return priorityA < priorityB
    end)

    for _, queue in self.nonStaticInitQueue do
        table.sort(queue, function(a, b)
            return a.index < b.index
        end)
    end
end

function Proto:collectInitFunction_actor(module, object, locations)
    local initQueue = {}

    for locationName, location in locations do
        for name, func in location do
            if typeof(func) ~= "function" then continue end

            local index = tonumber(string.match(name, "^init(%d+)$"))
            if not index or index < 1 or index > 1000 then continue end

            location[name] = nil

            local functionInfo = {
                func = func,
                index = index,
            }

            table.insert(initQueue, functionInfo)
        end
    end

    table.sort(initQueue, function(a, b)
        return a.index < b.index
    end)

    for _, functionInfo in initQueue do
        functionInfo.func(object)
    end
end

function Proto:init()
    for _, functionInfo in self.initQueue do
        self.initIndex = functionInfo.index

        if functionInfo.isStatic then
            functionInfo.func(functionInfo.module)
        else
            local components = self.componentsToInit[functionInfo.module]
            if not components then continue end

            for component in components do
                if component.initIndex and component.initIndex >= self.initIndex then continue end

                component.initIndex = self.initIndex
                
                functionInfo.func(component)
            end
        end
    end

    self.componentsToInit = nil
    self.finishedInit = true
end

function Proto:safeInit()
    self.initIndex = 1000
    self.componentsToInit = nil
    self.finishedInit = true
end

function Proto:objectInit(object)
    if self.safeMode then return end

    local objectComponentQueue = {}

    for _, component in object.components do
        if not self.finishedInit then
            self.componentsToInit[component.class] = self.componentsToInit[component.class] or {}
            self.componentsToInit[component.class][component] = true
        end

        local queue = self.nonStaticInitQueue[component.class]
        if self.initIndex <= 0 or not queue then continue end

        for _, functionInfo in queue do
            if functionInfo.index > self.initIndex then return end

            table.insert(objectComponentQueue, {
                index = functionInfo.index,
                func = functionInfo.func,
                component = component,
            })
        end
    end

    table.sort(objectComponentQueue, function(a, b)
        return a.index < b.index
    end)

    for _, functionInfo in objectComponentQueue do
        functionInfo.component.initIndex = functionInfo.index
        functionInfo.func(functionInfo.component, true)
    end
end

function Proto:componentInit(component)
    if not self.finishedInit then
        self.componentsToInit[component.class] = self.componentsToInit[component.class] or {}
        self.componentsToInit[component.class][component] = true
    end

    local queue = self.nonStaticInitQueue[component.class]
    if self.initIndex <= 0 or not queue then return end

    for _, functionInfo in queue do
        if functionInfo.index > self.initIndex then return end

        component.initIndex = functionInfo.index
        functionInfo.func(component, true)
    end
end

function Proto:validateMethods()--collect init functions would have removed all init methods so don't gotta worry bout that
    for _, class in self.classes do
        assert(not class.new, `Cannot have non-static custom new method in class, "{class.moduleName}"`)

        local newFunction = function(_, config)
            return self:newComponent(class, config, true)
        end

        local customNewFunction = class.static.new
        if customNewFunction and typeof(customNewFunction) == "function" then
            class.new = function(callingTable, config)
                return customNewFunction(callingTable, newFunction, config)
            end

            class.static.new = nil
        else
            class.new = newFunction
        end

        assert(not class.static.destroy, `Cannot have static custom destroy method in class, "{class.moduleName}"`)

        local destroyFunction = function(component)
            assert(component ~= class, "attempt to destroy class")

            self:componentDestroyLogic(component)
        end

        local customDestroyFunction = class.destroy
        if customDestroyFunction then
            class.destroy = function(callingTable)
                customDestroyFunction(callingTable, destroyFunction)
            end
        else
            class.destroy = destroyFunction
        end

        assert(not class.static.destroying, `Cannot have static destroying method in class, "{class.moduleName}"`)

        for name in class.RemoteFunction do--check for non static RemoteFunction
            error(`Can't have non-static RemoteFunction method "{name}" in a class "{class.moduleName}"`)
        end

        for name, func in class do
            if typeof(func) ~= "function" or name == "new" or name == "destroy" then continue end

            class[name] = function(callingTable, ...)
                if callingTable.class == class then
                    return func(callingTable, ...)
                else
                    for _, component in class.components do
                        func(component, ...)
                    end

                    return nil
                end
            end
        end

        for name, func in class.static do
            if typeof(func) ~= "function" then continue end

            class[name] = function(_, ...)
                return func(class, ...)
            end
        end

        assert(not class.connect, `Cannot have method named "connect", must be uppercase "Connect", in class, "{class.moduleName}"`)
        assert(not class.fire, `Cannot have method named "fire", must be uppercase "Fire", in class, "{class.moduleName}"`)
        assert(not class.disconnect, `Cannot have method named "disconnect", must be uppercase "Disconnect", in class, "{class.moduleName}"`)
    end

    for _, module in self.modules do
        local locations = {
            module = module,
            static = module.static,--if its a module, this will be nil
        }

        for locationName, location in locations do
            for className in ProtoNetwork.instanceTypes do
                locations[className.."_"..locationName] = location[className]
            end
        end

        for locationName1, location1 in locations do
            locations[locationName1] = nil

            local networkName1 = string.match(locationName1, "^(%w+)_")

            for locationName2, location2 in locations do
                local networkName2 = string.match(locationName2, "^(%w+)_")

                if networkName1 == networkName2 then continue end --eg if RemoteEvent_static and RemoteEvent_module

                for functionName, func in location1 do
                    if typeof(func) ~= "function" then continue end

                    if location2[functionName] then
                        error(`Can't have two methods with the same name "{functionName}" unless: (its an init function) OR (its a static/non-static version of a (RemoteEvent or UnreliableRemoteEvent) for networking in a CLASS only)`)
                    end
                end
            end
        end

        if module.static then
            for functionName, func in module.static do
                if typeof(func) ~= "function" then continue end
    
                module[functionName] = func
            end
        end
    end
end


function Proto:requireDirectories(directories)
    if directories.shared then
        self:requireDirectoriesSpecific(directories.shared, SHARED_MODULES_LOCATION)
    end

    if directories.server then
        self:requireDirectoriesSpecific(directories.server, SERVER_MODULES_LOCATION)
    end

    if directories.client then
        self:requireDirectoriesSpecific(directories.client, CLIENT_MODULES_LOCATION)
    end
end

function Proto:requireDirectoriesSpecific(directories, instanceBase)
    for _, instanceName in directories do
        local instance = instanceBase:FindFirstChild(instanceName, true)
        if instance then
            self:requireDescendants(instance)
        end
    end
end

function Proto:requireModuleFromName(moduleName)
    local module = self[moduleName]
    if module then return module end

    local moduleScript = SHARED_MODULES_LOCATION:FindFirstChild(moduleName, true)
    if moduleScript then
        return require(moduleScript)
    end

    if self.isClient then
        moduleScript = CLIENT_MODULES_LOCATION:FindFirstChild(moduleName, true)
        if moduleScript then
            return require(moduleScript)
        end
    else
        moduleScript = SERVER_MODULES_LOCATION:FindFirstChild(moduleName, true)
        if moduleScript then
            return require(moduleScript)
        end
    end

    error(`Module "{moduleName}" not found`)
end

function Proto:requireDescendants(instance)
    local descendants = instance:GetDescendants()
    table.insert(descendants, instance)

    for _, script in descendants do
        if script:IsA("ModuleScript") then
            local success, warning = pcall(function()
                require(script)
            end)

            if not success then
                warn(`Module "{script.Name}" failed to require: {warning}`)
            end

        elseif script:IsA("BaseScript") and script.Parent.Name == "Actors" then
            self.actorScripts[script.Name] = script
            script.Enabled = false
        end
    end
end


return Proto