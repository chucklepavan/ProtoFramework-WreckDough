local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local CustomCharacterClient = Proto:clientClass({
    moduleName = "CustomCharacterClient"
})


local playerLookup = {}


function CustomCharacterClient.static:init2()
    local characters = Proto.network.CustomCharacterServer.RemoteFunction:requestAllCharacters()

    for player, character in characters do
        local customCharacter = playerLookup[player]
        if not customCharacter then continue end

        customCharacter:initCharacter(character)
    end
end

function CustomCharacterClient.static.RemoteEvent:sendCharacter(player, character)
    print("character added", player, character)
end

function CustomCharacterClient:init1()
    playerLookup[self.player] = self
end

function CustomCharacterClient:characterAdded(character)
    --detect character destroy and call characterRemoving
end

function CustomCharacterClient:characterRemoving(character)

end


return CustomCharacterClient