local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local Spring = Proto:sharedClass({
    moduleName = "Spring",

    classSettings = {
        enabled = true,

        target = nil,
        value = nil,

        damping = 1,
        speed = 1,




        targets = {},
        positions = {},
        velocities = {},

        startDisplacements = {},
        startVelocities = {},

        startTime = 0,

        isMoving = false,
    },
})


local BASE_SPEED = 60


function Spring:init1()
    Proto:declare(self, function(self, Proto)
        self(function(self, Proto, ...) self:targetChanged(...) end, function(self, Proto) return self.target, self.enabled end)

        self(function(self, Proto, ...) self:update(...) end, function(self, Proto)
            if not self.enabled then return doNothing end
            if self.value ~= nil and typeof(self.target) ~= typeof(self.value) then return doNothing end

            return if self.isMoving then Proto.heartbeatTime else doNothing 
        end)

        self.active = function(self, Proto)
            return self.isMoving and self.enabled
        end
    end)
end

function Spring:setValue(value)
    assert(value, "value is nil")

    self.positions = Proto.TypePacker:unpackType(value)
    self:targetChanged(self.target)
end

function Spring:targetChanged(targetValue)
    self.targets = Proto.TypePacker:unpackType(targetValue)

    if typeof(targetValue) ~= typeof(self.lastTarget) then
        self.positions = table.clone(self.targets)
        self.velocities = table.create(#self.targets, 0)
    end

    self.startDisplacements = {}
    self.startVelocities = {}
    for index, target in self.targets do
        self.startDisplacements[index] = self.positions[index] - target
        self.startVelocities[index] = self.velocities[index]
    end

    self.startTime = Proto.heartbeatTime

    self.isMoving = true
    self.lastTarget = targetValue
end

function Spring:update(heartbeatTime)
    local timeSinceStart = heartbeatTime - self.startTime
    local posPos, posVel, velPos, velVel = self:getCoefficients(timeSinceStart, self.damping, self.speed * BASE_SPEED)
    local isMoving = false

    for index, startDisplacement in self.startDisplacements do
        local startVelocity = self.startVelocities[index]
        local target = self.targets[index]

        local newDisplacement = startDisplacement * posPos + startVelocity * posVel
        local newVelocity = startDisplacement * velPos + startVelocity * velVel

        if math.abs(newDisplacement) > 0.0001 or math.abs(newVelocity) > 0.0001 then
            isMoving = true
        end
        
        self.positions[index] = newDisplacement + target
        self.velocities[index] = newVelocity
    end

    local unpackArray = isMoving and self.positions or self.targets
    self.value = Proto.TypePacker:packType(unpackArray, typeof(self.target))

    self.isMoving = isMoving
end





--taken from fusion library
function Spring:getCoefficients(time, damping, speed)
    -- if time or speed is 0, then the spring won't move
    if time == 0 or speed == 0 then return 1, 0, 0, 1 end

    local posPos, posVel, velPos, velVel

    if damping > 1 then-- overdamped spring

        local scaledTime = time * speed
        local alpha = math.sqrt(damping^2 - 1)
        local scaledInvAlpha = -0.5 / alpha
        local z1 = -alpha - damping
        local z2 = 1 / z1
        local expZ1 = math.exp(scaledTime * z1)
        local expZ2 = math.exp(scaledTime * z2)

        posPos = (expZ2*z1 - expZ1*z2) * scaledInvAlpha
        posVel = (expZ1 - expZ2) * scaledInvAlpha / speed
        velPos = (expZ2 - expZ1) * scaledInvAlpha * speed
        velVel = (expZ1*z1 - expZ2*z2) * scaledInvAlpha

    elseif damping == 1 then-- critically damped spring

        local scaledTime = time * speed
        local expTerm = math.exp(-scaledTime)

        posPos = expTerm * (1 + scaledTime)
        posVel = expTerm * time
        velPos = expTerm * (-scaledTime*speed)
        velVel = expTerm * (1 - scaledTime)

    else-- underdamped spring

        local scaledTime = time * speed
        local alpha = math.sqrt(1 - damping^2)
        local invAlpha = 1 / alpha
        local alphaTime = alpha * scaledTime
        local expTerm = math.exp(-scaledTime*damping)
        local sinTerm = expTerm * math.sin(alphaTime)
        local cosTerm = expTerm * math.cos(alphaTime)
        local sinInvAlpha = sinTerm*invAlpha
        local sinInvAlphaDamp = sinInvAlpha*damping

        posPos = sinInvAlphaDamp + cosTerm
        posVel = sinInvAlpha
        velPos = -(sinInvAlphaDamp*damping + sinTerm*alpha)
        velVel = cosTerm - sinInvAlphaDamp

    end

    return posPos, posVel, velPos, velVel
end

return Spring