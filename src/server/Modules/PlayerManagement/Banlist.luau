local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local BanList = Proto:serverModule({
    moduleName = "BanList",
})


local list = {
    --[[
    [UserId],
    [UserId],
    ]]
}


function BanList:hasPlayer(player)
    return table.find(list, player.UserId)
end


return BanList