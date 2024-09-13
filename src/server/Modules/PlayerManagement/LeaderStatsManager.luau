local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local LeaderStatsManager = Proto:serverModule({
    moduleName = "LeaderStatsManager",
})


local statsConfig = {
    --[[cash = {
        moduleName = "Cash",
        instanceType = "IntValue",
    }]]
}


function LeaderStatsManager:addPlayer(player, saveData)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    for statName, statData in statsConfig do
        local stat = Instance.new(statData.instanceType)
        stat.Name = statName
        stat.Value = saveData[statName]
        stat.Parent = leaderstats
    end
end

function LeaderStatsManager:update(player)--this is mid
    local playerObject = Proto.ClassPlayerManager:getPlayerObject(player)
    local saveData = playerObject.saveData

    for statName, _ in statsConfig do
        local stat = player.leaderstats[statName]
        if not stat then continue end

        stat.Value = saveData[statName]
    end
end


return LeaderStatsManager