-- created on July 26th, 2024 @TritiusDumorix
--!nolint LocalUnused
local RunService = game:GetService("RunService")
local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local RoundState = Proto:serverClass({
    moduleName = "RoundState",
    classSettings={
        inboundPlayers={}, -- inital pool of players to join,
        -- called at round end; cant use Signal as no way to controll init methods; would need
        -- to fetch signal after init1 before later init functions called; but because framework calls all inits, this is not possible
        -- this is because roundEnded would be destroyed before the signal connection would call due to it living in a different coroutine
        -- later convert to a promise
        roundEndCallback = function() end 
    }
})

local TableUtil = nil

function RoundState.static:init1()
    TableUtil = Proto.TableUtil
end

--[[
    ALL ROUND COMPONENTS MUST NOT INCLUDE init1
    ALL ROUND COMPONENTS, IF INITALIZATION IS REQUIRED, MUST USE init2

    init1 -> initalize round state (create round data)
    init2-3 -> initalize round components
    init4 -> have all provided players join round
    init5-6 -> start round components (after all inbound players joined)
    init7 -> start round thread and heartbeat
    once round ends
    kill heartbeat conn (not in maid; must be disconnected before destroy)
    reard players
    destroy
--]]
function RoundState:init1()

    -- fail safe for future devs who accidently define invalid inits for round components
    for i, v in pairs(self.object.components) do
        if (v["init1"] or v["init4"] or v["init7"]) and v ~= self then
            error('A round component has either init1, init4 or init4 defined, change to init2-3 or init 5-6!')
        end
    end

    self.roundData = {playerRoundData={}, currentPlayers={}}    
    self.roundThread = coroutine.create(function()
        while not TableUtil:orAll(self.object:invokeComponentMethod("endCondition")) do
            task.wait()
        end
        self.object:callComponentMethod("roundEnded")
        self.roundEndCallback()
    end)
end

function RoundState:init4()
    for i, v in ipairs(self.inboundPlayers) do
        self:joinRound(v)
    end
end

function RoundState:init7()
    coroutine.resume(self.roundThread)
    self.heartbeatConn = RunService.Heartbeat:Connect(function(deltaTime)
        self.object:callComponentMethod("heartbeat", deltaTime)
    end)
end

function RoundState:getRoundData()
    return self.roundData
end

function RoundState:inRound(playerObject)
    return self.roundData.currentPlayers[playerObject] ~= nil
end


--[[------------------------------------------------------------
				 player management
--]]------------------------------------------------------------
function RoundState:joinRound(playerObject)
    if not TableUtil:andAll(self.object:invokeComponentMethod("canJoin", playerObject)) then
        return
    end
    -- possible player is simply rejoining round
    self.roundData.playerRoundData[playerObject] = if self.removeDataOnLeave then 
        self.roundData.playerRoundData[playerObject] else {}
    self.object:callComponentMethod("playerJoinedRound", playerObject)
    self.roundData.currentPlayers[playerObject]= true
end

function RoundState:leaveRound(playerObject)
    self.object:callComponentMethod("playerLeftRound", playerObject)
    if self.removeDataOnLeave then 
        self.roundData.playerRoundData[playerObject] = nil
    end
    self.roundData.currentPlayers[playerObject] = nil
end

function RoundState:rewardPlayersInRound()
    for playerObject, _ in pairs(self.roundData.currentPlayers) do
        local playerData = nil --TODO fetch player data
        self.object:callComponentMethod("rewardPlayer", playerObject, playerData)
    end
end


return RoundState