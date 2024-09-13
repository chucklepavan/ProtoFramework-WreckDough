--!nocheck

local Worker = {}
Worker.__index = Worker


local RunService = game:GetService("RunService")
local SharedTableRegistry = game:GetService("SharedTableRegistry")

local Proto = require(script.Parent)


local client_SafeDirectories = {
    shared = {
        "SharedUtil",
        "SharedClasses",
    },
}

local server_SafeDirectories = {
    shared = {
        "SharedUtil",
        "SharedClasses",
    },
}


local ACTOR

function Worker:start(actor)
    ACTOR = actor

    Proto:safeStart({
        safeDirectories = RunService:IsClient() and client_SafeDirectories or server_SafeDirectories,
    })

    self:getWorkerInfo()

    Proto.RunService.Heartbeat:Connect(function()
        self:heartbeat()
    end)
end



local IS_ACTOR_WORKER
local ACTOR_OBJECT
local IS_STATIC
local ACTOR_TASK_QUEUE = {}

function Worker:getWorkerInfo()
    IS_ACTOR_WORKER = ACTOR:GetAttribute("IsActorWorker")
    if not IS_ACTOR_WORKER then return end

    IS_STATIC = ACTOR:GetAttribute("IsStatic")

    local moduleName = ACTOR:GetAttribute("ModuleName")
    local module = Proto:requireModuleFromName(moduleName)

    ACTOR_OBJECT = if IS_STATIC then module else Proto:newComponent(module)

    Proto:collectInitFunction_actor(module, ACTOR_OBJECT, {
        actor = module.actor,
    })

    ACTOR:BindToMessageParallel("StartTask", function(taskInfo)
        self:receivedActorTask(taskInfo)
    end)
end

_G.parallelBreakpoint = function()
    Worker:parallelBreakpoint()
end






local FRAME_TIME_MAX = 0.015

local TASK_QUEUE = SharedTableRegistry:GetSharedTable("ParallelTaskQueue")
local COMPLETED_TASKS = SharedTableRegistry:GetSharedTable("ParallelCompletedTasks")

local FRAME_START_TABLE = SharedTableRegistry:GetSharedTable("FrameStart")
local frameStart = FRAME_START_TABLE.frameStart



local currentTaskThread




function Worker:heartbeat()
    frameStart = FRAME_START_TABLE.frameStart
    if not frameStart then return end

    if os.clock() - frameStart >= FRAME_TIME_MAX then
        return
    end

    if currentTaskThread then
        print("alr have task")
        task.desynchronize()

        if currentTaskThread then
            local success, err = coroutine.resume(currentTaskThread)

            if not success then
                error(err)
            end
        end

        return
    end

    self:checkTaskFromQueue()
end

function Worker:parallelBreakpoint()
    if os.clock() - frameStart >= FRAME_TIME_MAX then
        coroutine.yield()
    end
end

function Worker:startTask(taskId, object, func, ...)
    currentTaskThread = coroutine.running()

    local results = {taskId, func(object, ...)}

    currentTaskThread = nil

    Proto.BufferUtil:writeElementToQueue(COMPLETED_TASKS, results)

    if IS_ACTOR_WORKER then
        if #ACTOR_TASK_QUEUE > 0 then
            self:parallelBreakpoint()
            if os.clock() - frameStart < FRAME_TIME_MAX then
                self:receivedActorTask(table.remove(ACTOR_TASK_QUEUE, 1))
            end
            
        end
    else

    end
end

function Worker:checkTaskFromQueue()
    local queueElement = Proto.BufferUtil:readElementFromQueue(TASK_QUEUE)
    if not queueElement then return end

    local metadata = queueElement[1]

    local taskId = metadata[1]
    local moduleName = metadata[2]
    local functionName = metadata[3]

    local module = Proto:requireModuleFromName(moduleName)

    task.desynchronize()

    self:startTask(taskId, module, module.parallel[functionName], table.unpack(queueElement, 2))
end

function Worker:receivedActorTask(taskInfo)
    if currentTaskThread then
        table.insert(ACTOR_TASK_QUEUE, taskInfo)
        return
    end

    local taskId = taskInfo.taskId
    local functionName = taskInfo.functionName
    local taskData = taskInfo.taskData

    self:startTask(taskId, ACTOR_OBJECT, ACTOR_OBJECT.actor[functionName], table.unpack(taskData))
end


return Worker