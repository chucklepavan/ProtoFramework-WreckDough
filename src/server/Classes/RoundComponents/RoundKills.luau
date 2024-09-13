-- created on July 25th, 2024 @TritiusDumorix
--!nolint LocalUnused
local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local RoundKills = Proto:serverClass({
    moduleName = "RoundKills",
    classSettings = {
        duration = 5 * 60
    }
})

function RoundKills:heartbeat(deltaTime: number)
    self.duration -= deltaTime
end

function RoundKills:endCondition()
    return self.duration <= 0
end

function RoundKills:playerJoinedRound(playerObject)
    self.roundData.playerRoundData[playerObject].kills = {}
end

-- store user ids instead of player objects as player can possibly leave server
function RoundKills:addKill(attackerObject, victimObject)
    local attackerData = self.roundData.playerRoundData[attackerObject]
    if not attackerData then return end
    table.insert(attackerData.kills, {victimUserId=victimObject.instance.UserId, killTime=os.clock()})
end

function RoundKills:getKillCount(playerObject)
    return #self.roundData.playerRoundData[playerObject].kills
end

-- cannot use player object as player may not even be in server
function RoundKills:rewardPlayer(playerObject, playerData)
    -- do nothing
end


return RoundKills