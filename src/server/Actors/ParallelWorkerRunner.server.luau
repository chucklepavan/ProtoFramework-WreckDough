local actor = script.Parent
if not actor:IsA("Actor") then return end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Worker = require(ReplicatedStorage.Proto.ProtoWorker)

Worker:start(actor)