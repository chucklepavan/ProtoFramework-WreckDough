local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local CharacterCollisionGroup = Proto:serverClass({
    moduleName = "CharacterCollisionGroup"
})


local CHARACTER_COLLISION_GROUP = "Characters"
CharacterCollisionGroup.CHARACTER_COLLISION_GROUP = CHARACTER_COLLISION_GROUP


function CharacterCollisionGroup.static:init1()
    Proto.PhysicsService:RegisterCollisionGroup(CHARACTER_COLLISION_GROUP)
end


function CharacterCollisionGroup:init1()
    for _, descendant in self.instance:GetDescendants() do
        self:addToCollisionGroup(descendant)
    end

    self.instance.DescendantAdded:Connect(function(descendant)
        self:addToCollisionGroup(descendant)
    end)
end

function CharacterCollisionGroup:addToCollisionGroup(part)
    if not part:IsA("BasePart") then return end

    part.CollisionGroup = CHARACTER_COLLISION_GROUP
end


return CharacterCollisionGroup