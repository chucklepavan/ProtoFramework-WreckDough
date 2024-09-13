local runService = game:GetService("RunService")

local ProtoNetwork = {
    isClient = runService:IsClient(),
    isServer = runService:IsServer(),
}

local instanceTypes = {
    RemoteEvent = true,
    UnreliableRemoteEvent = true,
    RemoteFunction = true,
}
ProtoNetwork.instanceTypes = instanceTypes


local Proto = _G.Proto


function ProtoNetwork:start()
    Proto.network = {}

    if self.isServer then
        self.serverEventsFolder = Instance.new("Folder")
        self.serverEventsFolder.Name = "ServerEvents"

        self.clientEventsFolder = Instance.new("Folder")
        self.clientEventsFolder.Name = "ClientEvents"
    else
        self.serverEventsFolder = script:WaitForChild("ServerEvents")
        self.clientEventsFolder = script:WaitForChild("ClientEvents")
    end

    --client events (client --> server):
    if self.isServer then--create client event instances on server and listen for them being fired
        for _, module in Proto.modules do
            self:connectServerFunctions(module)
        end
    else--listen for client events being created and create event objects
        for _, instance in self.clientEventsFolder:GetDescendants() do
            self:clientEventAdded(instance)
        end

        self.clientEventsFolder.DescendantAdded:Connect(function(instance)
            self:clientEventAdded(instance)
        end)
    end


    --server events (server --> client):
    if self.isServer then--server events don't exist yet because we don't know what the client is listening for, so create event based on what the server indexed
        --the client will then listen for events being created and listen to them immediately
        setmetatable(Proto.network, {
            __index = function(_, moduleName)
                local module = {}
                ProtoNetwork:setupModule(module)

                for className, table in module do
                    setmetatable(table, {
                        __index = function(_, functionName)
                            --shoudl give className where it says nil, but how is the server supposed to know if the className is only defined on client
                            local instance = self:getInstance(moduleName, functionName, className, true)
                            local eventObject = self:newEventObject(moduleName, instance)
    
                            return eventObject
                        end
                    })
                end

                Proto.network[moduleName] = module

                return module
            end
        })
    else--listen for server event being added on client, connect to it
        for _, instance in self.serverEventsFolder:GetDescendants() do
            self:serverEventAdded(instance)
        end

        self.serverEventsFolder.DescendantAdded:Connect(function(instance)
            self:serverEventAdded(instance)
        end)
    end

    self.serverEventsFolder.Parent = script
    self.clientEventsFolder.Parent = script
end

function ProtoNetwork:setupModule(module)
    for className in instanceTypes do
        module[className] = {}
    end

    if Proto:isClass(module) then
        for className in instanceTypes do
            module.static[className] = {}
        end
    end
end



function ProtoNetwork:connectServerFunctions(module)
    for className in instanceTypes do
        local isClass = Proto:isClass(module)

        if module[className] then
            for functionName, func in module[className] do
                local instance = self:getInstance(module.moduleName, functionName, className, false)

                self:connectFunction(module, func, instance, isClass)
            end
        end

        if isClass then
            for functionName, func in module.static[className] do
                local instance = self:getInstance(module.moduleName, functionName, className, false)

                self:connectFunction(module, func, instance, false)
            end
        end
    end
end

function ProtoNetwork:clientEventAdded(instance)
    if not instanceTypes[instance.ClassName] then return end

    local moduleName = instance.Parent.Name
    self:newEventObject(moduleName, instance)
end


function ProtoNetwork:serverEventAdded(instance)
    if not instanceTypes[instance.ClassName] then return end

    local moduleName = instance.Parent.Name
    local module = Proto.modules[moduleName]

    if not module then warn("server tried calling method but module doesn't exist"); return end

    local functionName = instance.Name
    local isClass = Proto:isClass(module)

    if module[instance.ClassName][functionName] then
        self:connectFunction(module, module[instance.ClassName][functionName], instance, isClass)
    end

    if isClass and module.static[instance.ClassName][functionName] then
        self:connectFunction(module, module.static[instance.ClassName][functionName], instance, false)
    end
end




function ProtoNetwork:newEventObject(moduleName, instance)
    local module = Proto.network[moduleName]
    if not module then
        module = {}
        self:setupModule(module)

        Proto.network[moduleName] = module
    end

    local networkTable = module[instance.ClassName]

    local eventObject

    local callFunction
    if self.isServer then
        callFunction = function(passedTable, player, ...)
            if passedTable ~= networkTable then
                error("Network methods must be called with : not .")
            end

            if player == "all" then
                ProtoNetwork.FireAll(eventObject, ...)
                return nil

            elseif typeof(player) == "Instance" and player.ClassName == "Player" then
                return ProtoNetwork.Fire(eventObject, player, ...)--could be remote function so need to return

            elseif typeof(player) == "table" then
                ProtoNetwork.FireTable(eventObject, player, ...)

            else
                error(`Tried calling network method {instance.Name} invalid player argument {typeof(moduleName)}`)
            end
        end
    else
        callFunction = function(...)
            return ProtoNetwork.Fire(eventObject, ...)--could be remote function so need to return
        end
    end

    eventObject = setmetatable({
        instance = instance,
        isRemoteFunction = instance.ClassName == "RemoteFunction",
    }, {
        __call = function(_, passedTable, ...)
            return callFunction(passedTable, ...)
        end
    })

    eventObject.propertyName = eventObject.isRemoteFunction and (self.isServer and "InvokeClient" or "InvokeServer")
    or (self.isServer and "FireClient" or "FireServer")

    networkTable[instance.Name] = eventObject

    return eventObject
end

function ProtoNetwork:connectFunction(module, func, instance, callForComponents)
    local callback

    if callForComponents then
        callback = function(...)--will never be a remote function bc of setupModule, so doesn't have to return anything
            for _, component in module.components do
                func(component, ...)
            end
        end
    else
        callback = function(...)
            return func(module, ...)--returning even if its remote event bc it doesn't matter
        end
    end

    if instance.ClassName == "RemoteFunction" then--need timeout and error handling for server > client > server
        local propertyName = self.isServer and "OnServerInvoke" or "OnClientInvoke"

        instance[propertyName] = callback
    else
        local eventName = self.isServer and "OnServerEvent" or "OnClientEvent"

        instance[eventName]:Connect(callback)
    end
end


function ProtoNetwork:getInstance(moduleName, functionName, className, isServerEvent)--might be able to define two methods: one in networking table and one in normla module/static, should fix
    local eventFolder = isServerEvent and self.serverEventsFolder or self.clientEventsFolder

    local moduleFolder = eventFolder:FindFirstChild(moduleName)
    if not moduleFolder then
        moduleFolder = Instance.new("Folder")
        moduleFolder.Name = moduleName
        moduleFolder.Parent = eventFolder
    end

    local instance = moduleFolder:FindFirstChild(functionName)
    if not instance and className then
        instance = Instance.new(className)
        instance.Name = functionName
        instance.Parent = moduleFolder
    end

    return instance
end





function ProtoNetwork.Fire(eventObject, ...)--all events can't have same name, and should be called like methods
    return eventObject.instance[eventObject.propertyName](eventObject.instance, ...)
end

function ProtoNetwork.FireAll(eventObject, ...)
    if eventObject.isRemoteFunction then
        error("Cannot call FireAll on a RemoteFunction!")
    end

    if eventObject.isClient then
        error("Cannot call FireAll from the client!")
    end
    print(...)
    eventObject.instance.FireAllClients(eventObject.instance, ...)
end

function ProtoNetwork.FireTable(eventObject, players, ...)
    if eventObject.isRemoteFunction then
        error("Cannot call FireTable on a RemoteFunction!")
    end

    if eventObject.isClient then
        error("Cannot call FireTable from the client!")
    end

    for player1, player2 in players do
        local player = (((typeof(player1) == "Instance" and player1.ClassName == "Player") and player1)
        or ((typeof(player2) == "Instance" and player2.ClassName == "Player") and player2))

        if not player then continue end

        eventObject.instance.FireClient(eventObject.instance, ...)
    end
end



return ProtoNetwork