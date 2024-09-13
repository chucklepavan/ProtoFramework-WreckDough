local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local ClassCharacterManager = Proto:sharedModule({
    moduleName = "ClassCharacterManager",
})


local sharedTemplateNames = {
    "AllCharacters_Shared"
}
local serverTemplateNames = {
    "AllCharacters_Server",
}
local clientTemplateNames = {
    "AllCharacters_Client",
    "OtherCharacters_Client",
    "LocalCharacter_Client",
}

local templateNames = {}

local objectLookup = {}


function ClassCharacterManager:init3()
    for _, templateName in sharedTemplateNames do
        table.insert(templateNames, templateName)
    end

    local templateFolder = Proto.isServer and serverTemplateNames or clientTemplateNames
    for _, templateName in templateFolder do
        table.insert(templateNames, templateName)
    end

    Proto:characterAddedCallback(self.characterAdded, self)
    Proto:characterRemovingCallback(self.characterRemoving, self)
end

function ClassCharacterManager:characterAdded(player, character, isCustomCharacter)
    local playerObject = Proto.ClassPlayerManager:getPlayerObject(player)
    local characterObject = Proto:newObject(character)

    for _, templateName in templateNames do
        Proto:addTemplateComponentsToObject(characterObject, templateName)
    end

    characterObject:setComponentValue("player", player)
    characterObject:setComponentValue("playerObject", playerObject)
    characterObject:setComponentValue("saveData", playerObject.saveData)

    objectLookup[character] = characterObject

    characterObject.maid:add(task.spawn(function()
        if not isCustomCharacter then
            local humanoid = character:WaitForChild("Humanoid")
            local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
            characterObject:setComponentValue("humanoid", humanoid)
            characterObject:setComponentValue("rootPart", humanoidRootPart)
        end

        characterObject:init()
    end))
end

function ClassCharacterManager:characterRemoving(character)
    local characterObject = Proto:getObjectFromInstance(character)

    objectLookup[character] = nil

    if characterObject then
        characterObject:destroy()
    end
end

function ClassCharacterManager:getCharacterObject(character)
    return objectLookup[character]
end


return ClassCharacterManager