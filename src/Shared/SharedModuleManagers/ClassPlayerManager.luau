local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local ClassPlayerManager = Proto:sharedModule({
    moduleName = "ClassPlayerManager"
})


local sharedTemplateNames = {
    "AllPlayers_Shared"
}
local serverTemplateNames = {
    "AllPlayers_Server",
}
local clientTemplateNames = {
    "AllPlayers_Client",
    "OtherPlayers_Client",
    "LocalPlayer_Client",
}

local templateNames = {}

local objectLookup = {}


function ClassPlayerManager:init2()
    for _, templateName in sharedTemplateNames do
        table.insert(templateNames, templateName)
    end

    local templateFolder = Proto.isServer and serverTemplateNames or clientTemplateNames
    for _, templateName in templateFolder do
        table.insert(templateNames, templateName)
    end

    if Proto.isServer then
        Proto.PlayerManager:saveDataLoadedCallback(self.saveDataLoaded, self)
    else
        Proto:playerAddedCallback(self.playerAdded, self)
    end

    
    Proto:playerRemovingCallback(self.playerRemoving, self)
end

function ClassPlayerManager:saveDataLoaded(player, saveData)--will only run on the server
    local object = self:createPlayerObject(player)

    object:setComponentValue("saveData", saveData)

    object:init()
end

function ClassPlayerManager:playerAdded(player)--will only run on the client
    local object = self:createPlayerObject(player)

    object:init()
end

function ClassPlayerManager:createPlayerObject(player)
    local object = Proto:newObject(player)
    objectLookup[player] = object

    for _, templateName in templateNames do
        Proto:addTemplateComponentsToObject(object, templateName)
    end

    object:setComponentValue("player", player)

    return object
end

function ClassPlayerManager:playerRemoving(player)
    objectLookup[player] = nil
end

function ClassPlayerManager:getPlayerObject(player)
    return objectLookup[player]
end


return ClassPlayerManager