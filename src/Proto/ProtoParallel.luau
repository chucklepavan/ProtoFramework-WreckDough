local ProtoParallel = {}

local SharedTableRegistry = game:GetService("SharedTableRegistry")

local Proto = _G.Proto


local PARALLEL_WORKER_COUNT = 12

local TASK_QUEUE
local COMPLETED_TASKS

local YIELDED_THREADS = {}

local ACTOR_ID_LOOKUP = {}


-- TODO: static actor methods and static init functions

function ProtoParallel:setupModule(module)
    module.parallel = {}
    module.actor = {}
end

function ProtoParallel:start()
    for _, module in Proto.modules do
        self:setupParallelMethods(module, module.moduleName)
    end

    --want this to run first heartbeat

    Proto.RunService.Heartbeat:Connect(function()
        self:processTasks()
    end)

    self.parallelWorkersFolder = Instance.new("Folder")
    self.parallelWorkersFolder.Name = "ParallelWorkers"
    self.parallelWorkersFolder.Parent = if Proto.isServer then Proto.ServerScriptService else Proto.player.PlayerScripts

    -- TODO: test how many threads there are and delete #worker actors down to that
    -- or continually change bc avaialable cores might change?
    for _ = 1, PARALLEL_WORKER_COUNT do--can test how many thread by seeing how long it takes to compute when change # of actors
        --but i don't care to do that rn
        self:createParallelWorker()
    end

    TASK_QUEUE = SharedTable.new()
    SharedTableRegistry:SetSharedTable("ParallelTaskQueue", TASK_QUEUE)

    COMPLETED_TASKS = SharedTable.new()
    SharedTableRegistry:SetSharedTable("ParallelCompletedTasks", COMPLETED_TASKS)

    local FRAME_START_TABLE = SharedTable.new()
    FRAME_START_TABLE.frameStart = os.clock() - 10
    SharedTableRegistry:SetSharedTable("FrameStart", FRAME_START_TABLE)

    if Proto.isServer then--on the client its done in InputManager
        self:updateFrameStartOnStepped(FRAME_START_TABLE)
    end
end

function ProtoParallel:updateFrameStartOnStepped(frameStartTable)
    Proto.RunService.Stepped:Connect(function()
        frameStartTable.frameStart = os.clock()
    end)
end

function ProtoParallel:setupParallelMethods(module, moduleName)--need to setup parallel init methods too
    for functionName, func in module.parallel do
        if typeof(func) ~= "function" then continue end

        assert(string.find(functionName, "Async"), "Parallel/Actor function names must have 'Async' in them.")

        module[functionName] = ProtoParallel:getParallelFunction(moduleName, functionName)
    end

    module.parallel = nil

    for functionName, func in module.actor do
        if typeof(func) ~= "function" then continue end

        assert(string.find(functionName, "Async"), "Parallel/Actor function names must have 'Async' in them.")

        module[functionName] = ProtoParallel:getActorFunction(moduleName, functionName)
    end

    module.actor = nil
end

function ProtoParallel:getParallelFunction(moduleName, functionName)
    return function(_, ...)
        return self:callParallelFunction(moduleName, functionName, ...)
    end
end

function ProtoParallel:getActorFunction(moduleName, functionName)
    return function(callingTable, ...)
        local actor = self:getActorInfo(callingTable, moduleName)
        assert(actor, "Calling table is not a module or component.")

        return self:callActorFunction(actor, functionName, ...)
    end
end

function ProtoParallel:getActorInfo(table, moduleName)
    local isModule = Proto:isModule(table)
    local isComponent = Proto:isComponent(table)

    if not isModule and not isComponent then return nil end

    local actor = ACTOR_ID_LOOKUP[table]

    if not actor then
        actor = self:createActorWorker(moduleName, isModule)

        ACTOR_ID_LOOKUP[table] = actor

        assert(table.maid, "Table must have a trove.")
        table.maid:add(function()
            actor:Destroy()
            ACTOR_ID_LOOKUP[table] = nil
        end)
    end

    return actor
end

function ProtoParallel:createParallelWorker()
    local actor = Proto:actor("ParallelWorkerRunner")
    actor:SetAttribute("IsActorWorker", false)
    actor.Parent = self.parallelWorkersFolder

    return actor
end

function ProtoParallel:createActorWorker(moduleName, isStatic)
    local actor = Proto:actor("ParallelWorkerRunner")
    actor:SetAttribute("IsActorWorker", true)
    actor:SetAttribute("ModuleName", moduleName)
    actor:SetAttribute("IsStatic", isStatic)
    actor.Parent = self.parallelWorkersFolder

    return actor
end





local currentTaskId = 0


function ProtoParallel:callActorFunction(actor, functionName, ...)--this is for actor functions
    currentTaskId += 1
    
    local taskData = {...}

    task.defer(function()
        actor:SendMessage("StartTask", {
            taskId = currentTaskId,
            functionName = functionName,
            taskData = taskData,
        })
    end)
    

    table.insert(YIELDED_THREADS, {
        thread = coroutine.running(),
        taskId = currentTaskId
    })

    return coroutine.yield()
end

function ProtoParallel:callParallelFunction(moduleName, functionName, ...)
    currentTaskId += 1

    self:writeTask(currentTaskId, moduleName, functionName, {...})

    table.insert(YIELDED_THREADS, {
        thread = coroutine.running(),
        taskId = currentTaskId
    })

    return coroutine.yield()
end

function ProtoParallel:writeTask(taskId, moduleName, functionName, taskData)
    local metadata = {
        taskId,
        moduleName,
        functionName
    }

    table.insert(taskData, 1, metadata)

    Proto.BufferUtil:writeElementToQueue(TASK_QUEUE, taskData)
end


function ProtoParallel:processTasks()
    local completedTaskBuffer = COMPLETED_TASKS[1]
    if not completedTaskBuffer then return end

    COMPLETED_TASKS[1] = nil

    local tasksData = Proto.BufferUtil:readBuffer(completedTaskBuffer)

    for _, results in tasksData do
        local taskId = results[1]
        local thread = self:findAndRemoveYieldedThread(taskId)

        local success, err = coroutine.resume(thread, table.unpack(results, 2))

        if not success then
            error(err)
        end
    end
end

function ProtoParallel:findAndRemoveYieldedThread(taskId)
    for index, threadInfo in YIELDED_THREADS do
        if threadInfo.taskId == taskId then
            table.remove(YIELDED_THREADS, index)

            return threadInfo.thread
        end
    end

    error("Thread not found for taskId: " .. taskId)
end


return ProtoParallel