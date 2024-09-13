local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local DisableCharacterCollision = Proto:serverClass({
    moduleName = "DisableCharacterCollision"
})


local CHARACTER_COLLISION_GROUP



function DisableCharacterCollision.static:init1()
    CHARACTER_COLLISION_GROUP = Proto.CharacterCollisionGroup.CHARACTER_COLLISION_GROUP

    Proto.PhysicsService:CollisionGroupSetCollidable(CHARACTER_COLLISION_GROUP, CHARACTER_COLLISION_GROUP, false)
end



return DisableCharacterCollision