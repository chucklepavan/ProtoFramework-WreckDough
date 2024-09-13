local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local ScreenCulling = Proto:clientModule({
    moduleName = "ScreenCulling"
})



local camera = workspace.CurrentCamera
local moveBackBuffer = 0


function ScreenCulling:init1()
	self:update()

    Proto.RunService.RenderStepped:Connect(function()
        self:update()
    end)
end

function ScreenCulling:update()
    local viewportSize = camera.ViewportSize
    local fieldOfView = camera.FieldOfView

	local aspectRatio = viewportSize.X / viewportSize.Y
    
    self.xFov = (math.pi - math.rad(fieldOfView * aspectRatio)) / 2
    self.yFov = (math.pi - math.rad(fieldOfView)) / 2
	self.x2Fov = math.pi - math.rad(fieldOfView) / 2
	self.y2Fov = math.pi - math.rad(fieldOfView * aspectRatio) / 2

	local camCFrame = camera.CFrame
	self.bufferedCamCFrame = camCFrame - camCFrame.LookVector * moveBackBuffer
    self.camDirection = camCFrame.LookVector
    self.camPosition = self.bufferedCamCFrame.Position
end

function ScreenCulling:isPointInScreen(position)
	local relative = self.bufferedCamCFrame:PointToObjectSpace(position)
	local x, y, z = relative.X, relative.Y, relative.Z

    local xAngle = math.abs(math.atan2(x, z))
    local yAngle = math.abs(math.atan2(y, z))

    if xAngle < self.xFov and yAngle < self.yFov then
        --completely outside of view
        --can only use this when testing the point that is closest to the camera on a surface
        return false
    end

    if xAngle >= self.x2Fov and yAngle >= self.y2Fov then
        return true
    end

	return nil
end


--based on test i made in workspace
--you want to use surface that will give you the corner/edge that will be closest the to center of the screen


function ScreenCulling:isBoundingInScreen(partCFrame, partHalfSize, partPosition)
    local closestPointToCam = self:closestPointOnBounding(partCFrame, partHalfSize, self.camPosition)
    local closestPointResult = self:isPointInScreen(closestPointToCam)
    if closestPointResult == false then return closestPointResult end

    local distanceToClosestPoint = (closestPointToCam - self.camPosition).Magnitude

    local dot = self.camDirection.Unit:Dot((closestPointToCam - self.camPosition).Unit)
    local projectDistance = distanceToClosestPoint / dot
    if projectDistance ~= projectDistance then projectDistance = 100000 end

    local projectDistance2 = projectDistance > 0 and projectDistance or 100000
    local projectedPoint = self.camPosition + self.camDirection * projectDistance2
    local projectedPointOnBounding = self:closestPointOnBounding(partCFrame, partHalfSize, projectedPoint)

    local test = self.camPosition + self.camDirection * math.abs(projectDistance)
    local test2 = self:closestPointOnBounding(partCFrame, partHalfSize, test)

    --Proto.Gizmo:sphere(projectedPoint, 1)
    --Proto.Gizmo:sphere(projectedPointOnBounding, 1)
    --Proto.Gizmo:sphere(test2, 1)
end

function ScreenCulling:getPointOnCameraLine(point)
    local direction = self.camDirection

    --https://math.stackexchange.com/questions/1521128/given-a-line-and-a-point-in-3d-how-to-find-the-closest-point-on-the-line
    local t = math.max(direction:Dot(point - self.camPosition) / (direction:Dot(direction)), 5)
    --print(t)
    return self.camPosition + t * direction
end

function ScreenCulling:closestPointOnBounding(cframe, halfSize, point)
    local relative = cframe:PointToObjectSpace(point)

    return cframe * Vector3.new(
        math.clamp(relative.X, -halfSize.X, halfSize.X),
        math.clamp(relative.Y, -halfSize.Y, halfSize.Y),
        math.clamp(relative.Z, -halfSize.Z, halfSize.Z)
    )
end


return ScreenCulling