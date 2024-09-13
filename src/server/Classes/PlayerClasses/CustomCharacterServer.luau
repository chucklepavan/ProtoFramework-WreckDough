local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local CustomCharacterServer = Proto:serverClass({
    moduleName = "CustomCharacterServer",

    classSettings = {
        characterModel = nil,
    },
})


local charactersLookup = {}


function CustomCharacterServer.static.RemoteFunction:requestAllCharacters()
    return charactersLookup
end

function CustomCharacterServer:init1()
    local character = self.characterModel:Clone()

    character.Parent = workspace

    for _, part in character:GetDescendants() do
        if not part:IsA("BasePart") then continue end
        
        part:SetNetworkOwner(self.player)
    end

    charactersLookup[self.player] = character

    Proto.ClassCharacterManager:characterAdded(self.player, character, true)
    Proto.network.CustomCharacterClient.RemoteEvent:characterAdded("all", self.player, character)
end


return CustomCharacterServer