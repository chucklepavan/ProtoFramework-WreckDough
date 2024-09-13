local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local Laser = Proto:clientClass({
    moduleName = "Laser"
})


local BEAM_ROTATE_OFFSET = CFrame.Angles(0, math.rad(90), 0)
local MAX_REFLECTIONS = 5


function Laser.static:init1()--should create version of static that only runs if there's at least one component
    self.pool = Proto.PartPool:new({
        --clonePart = Proto.assets.Laser.Beam,
    })
end

function Laser.static:init2()
    Proto.RunService.Heartbeat:Connect(function()
        self:heartbeat()

        self.pool:moveHolding()
    end)
end

function Laser:init1()
    self.source = self.instance:WaitForChild("Source")

    self.endBeam = Proto.assets.Laser.EndBeam:Clone()
    self.endBeam.Parent = self.instance
    self.particleAttachment = self.endBeam:WaitForChild("ParticleAttachment")

    self.beamWidth = self.endBeam.Size.Y
    self.sourceOffset = self.source.Size.X / 2

    self.beams = {}
end

function Laser:heartbeat()
    self:cleanBeams()

    local sourcePosition = self.source.Position
    local laserDirection = -self.source.CFrame.RightVector

    self:newBeam(sourcePosition, laserDirection, 0)
end

function Laser:newBeam(beamPosition, beamDirection, reflectCount)
    local isLastBeam = reflectCount == MAX_REFLECTIONS

    local hitPlayer, hitDistance, hitInstance, hitPosition, hitNormal = self:raycastAsync(beamPosition, beamDirection)
    
    local beamSize = Vector3.new(hitDistance, self.beamWidth, self.beamWidth)

    local beamCFrame = CFrame.lookAlong(beamPosition, beamDirection) * BEAM_ROTATE_OFFSET
    beamCFrame += beamDirection * hitDistance / 2

    if reflectCount == 0 then
        hitDistance -= self.sourceOffset
        beamCFrame += beamDirection * self.sourceOffset
    end


    
    local shouldReflect, reflectionDirection = self:shouldReflect(hitInstance, beamDirection, hitNormal)

    if shouldReflect and not isLastBeam then
        self:moveRegularBeam(beamCFrame, beamSize)

        self:newBeam(hitPosition, reflectionDirection, reflectCount + 1)
    else
        self.particleAttachment.CFrame = CFrame.new(hitDistance / 2, 0, 0)

        self.endBeam.Size = beamSize
        Proto.BulkMove:cframeTo(self.endBeam, beamCFrame)
    end

    if hitPlayer then
        --warn("hit player")

        return
    end
end

function Laser:moveRegularBeam(cframe, size)
    local beam = self.pool:getPart()

    beam.Size = size
    Proto.BulkMove:cframeTo(beam, cframe)

    table.insert(self.beams, beam)
end

function Laser:shouldReflect(hitInstance, beamDirection, hitNormal)
    local object = Proto:getObjectFromInstance(hitInstance)
    if not object then return false end

    local shouldReflect = object:hasComponentOfClass("LaserReflectionPart")
    if not shouldReflect then return false end

    local reflectionDirection = Proto.Math:getReflectionAcrossNormal(beamDirection, hitNormal)
    return true, reflectionDirection
end

function Laser:cleanBeams()
    for _, beam in self.beams do
        self.pool:releasePart(beam)
    end

    table.clear(self.beams)
end


function Laser:raycastAsync(position, direction)
    local result = workspace:Raycast(position, direction * 100)
    if not result then return false, 100 end

    if result.Instance.Parent == Proto.player.Character then
        return true, result.Distance
    else
        return false, result.Distance, result.Instance, result.Position, result.Normal
    end
end



return Laser