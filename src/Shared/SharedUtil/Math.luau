local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local Math = Proto:sharedModule({
    moduleName = "Math",
})


function Math:raycastInMouseDirection(raycastParams, maxDistance)
    local mouseLocation = Proto.UserInputService:GetMouseLocation()
    local screenToWorldRay = workspace.CurrentCamera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
    local directionVector = screenToWorldRay.Direction * (maxDistance or 1000)  -- Multiply by a maximum distance

    return workspace:Raycast(screenToWorldRay.Origin, directionVector, raycastParams)
end

function Math:lerp(s, e, alpha)
    local typeString = typeof(s)
    assert(typeString == typeof(e), "tried to lerp two different types")

    if typeString == "number" then
        return (e - s) * alpha + s

    elseif typeString == "CFrame" then
        return s:Lerp(e, alpha)

    elseif typeString == "Color3" then
        local fromLab = Proto.Oklab:fromSRGB(s)
        local toLab = Proto.Oklab:fromSRGB(e)
        return Proto.Oklab:toSRGB(
            fromLab:Lerp(toLab, alpha),
            false
        )

    elseif typeString == "ColorSequenceKeypoint" then
        local fromLab = Proto.Oklab:fromSRGB(s.Value)
        local toLab = Proto.Oklab:fromSRGB(e.Value)
        return ColorSequenceKeypoint.new(
            (e.Time - s.Time) * alpha + s.Time,
            Proto.Oklab:toSRGB(
                fromLab:Lerp(toLab, alpha),
                false
            )
        )

    elseif typeString == "DateTime" then
        return DateTime.fromUnixTimestampMillis(
            (e.UnixTimestampMillis - s.UnixTimestampMillis) * alpha + s.UnixTimestampMillis
        )

    elseif typeString == "NumberRange" then
        return NumberRange.new(
            (e.Min - s.Min) * alpha + s.Min,
            (e.Max - s.Max) * alpha + s.Max
        )

    elseif typeString == "NumberSequenceKeypoint" then
        return NumberSequenceKeypoint.new(
            (e.Time - s.Time) * alpha + s.Time,
            (e.Value - s.Value) * alpha + s.Value,
            (e.Envelope - s.Envelope) * alpha + s.Envelope
        )

    elseif typeString == "PhysicalProperties" then
        return PhysicalProperties.new(
            (e.Density - s.Density) * alpha + s.Density,
            (e.Friction - s.Friction) * alpha + s.Friction,
            (e.Elasticity - s.Elasticity) * alpha + s.Elasticity,
            (e.FrictionWeight - s.FrictionWeight) * alpha + s.FrictionWeight,
            (e.ElasticityWeight - s.ElasticityWeight) * alpha + s.ElasticityWeight
        )

    elseif typeString == "Ray" then
        return Ray.new(
            s.Origin:Lerp(e.Origin, alpha),
            s.Direction:Lerp(e.Direction, alpha)
        )

    elseif typeString == "Rect" then
        return Rect.new(
            s.Min:Lerp(e.Min, alpha),
            s.Max:Lerp(e.Max, alpha)
        )

    elseif typeString == "Region3" then
        -- FUTURE: support rotated Region3s if/when they become constructable
        local position = s.CFrame.Position:Lerp(e.CFrame.Position, alpha)
        local halfSize = s.Size:Lerp(e.Size, alpha) / 2
        return Region3.new(position - halfSize, position + halfSize)

    elseif typeString == "Region3int16" then
        return Region3int16.new(
            Vector3int16.new(
                (e.Min.X - s.Min.X) * alpha + s.Min.X,
                (e.Min.Y - s.Min.Y) * alpha + s.Min.Y,
                (e.Min.Z - s.Min.Z) * alpha + s.Min.Z
            ),
            Vector3int16.new(
                (e.Max.X - s.Max.X) * alpha + s.Max.X,
                (e.Max.Y - s.Max.Y) * alpha + s.Max.Y,
                (e.Max.Z - s.Max.Z) * alpha + s.Max.Z
            )
        )

    elseif typeString == "UDim" then
        return UDim.new(
            (e.Scale - s.Scale) * alpha + s.Scale,
            (e.Offset - s.Offset) * alpha + s.Offset
        )

    elseif typeString == "UDim2" then
        return s:Lerp(e, alpha)

    elseif typeString == "Vector2" then
        return s:Lerp(e, alpha)

    elseif typeString == "Vector2int16" then
        return Vector2int16.new(
            (e.X - s.X) * alpha + s.X,
            (e.Y - s.Y) * alpha + s.Y
        )

    elseif typeString == "Vector3" then
        return s:Lerp(e, alpha)

    elseif typeString == "Vector3int16" then
        return Vector3int16.new(
            (e.X - s.X) * alpha + s.X,
            (e.Y - s.Y) * alpha + s.Y,
            (e.Z - s.Z) * alpha + s.Z
        )
    end

    return nil
end

function Math:lerpWithDeltaTime(s, e, alpha, dt)
    return self:lerp(s, e, 1 - alpha ^ dt)
end

function Math:getInstancePosition(instance)
    if instance:IsA("Part") then
		return instance.Position
	elseif instance:IsA("Model") then
		local cframe = instance:GetBoundingBox()
		return cframe.Position
	end

	error(`Unsupported instance type: {instance.ClassName}`)
end

function Math:getInstanceCFrame(instance)
    if instance:IsA("Part") then
		return instance.CFrame
	elseif instance:IsA("Model") then
		local cframe = instance:GetBoundingBox()
		return cframe
	end

	error(`Unsupported instance type: {instance.ClassName}`)
end

function Math:circleFunction(radius, x)
    return math.sqrt(radius * radius - x * x)
end

function Math:sphereTouchingBox(boxPosition, halfBoxSize, spherePosition, radiusSquared)
    local dp = spherePosition - boxPosition
    local dpx, dpy, dpz = dp.X, dp.Y, dp.Z

    local sx, sy, sz = halfBoxSize.X, halfBoxSize.Y, halfBoxSize.Z
    local nsx, nsy, nsz = -sx, -sy, -sz

    local v1 = dp - Vector3.new(
        (dpx > sx and sx) or (dpx < nsx and nsx) or dpx,
        (dpy > sy and sy) or (dpy < nsy and nsy) or dpy,
        (dpz > sz and sz) or (dpz < nsz and nsz) or dpz
    )
    local v1x, v1y, v1z = v1.X, v1.Y, v1.Z

    if v1x * v1x + v1y * v1y + v1z * v1z > radiusSquared then
        return 0--out
    end

    local v2 = dp + Vector3.new(
        sx * (dpx >= 0 and 1 or -1),
        sy * (dpy >= 0 and 1 or -1),
        sz * (dpz >= 0 and 1 or -1)
    )
    local v2x, v2y, v2z = v2.X, v2.Y, v2.Z

    if v2x * v2x + v2y * v2y + v2z * v2z < radiusSquared then
        return 1--in
    else
        return 2--partial
    end
end

function Math:getClosestNormalOnBoxToNormalRotated(boxCFrame, boxSize, normal)
    local relativeNormal = boxCFrame:VectorToObjectSpace(normal)
    local closestNormal, axis = self:getClosestNormalOnBoxToNormal(Vector3.zero, boxSize, relativeNormal)

    return boxCFrame:VectorToWorldSpace(closestNormal), axis
end

function Math:getClosestNormalOnBoxToNormal(boxPosition, boxSize, normal)
    local absX = math.abs(normal.X)
    local absY = math.abs(normal.Y)
    local absZ = math.abs(normal.Z)

    local max = math.max(absX, absY, absZ)

    if max == absX then
        return Vector3.new(math.sign(normal.X), 0, 0), "X"
    elseif max == absY then
        return Vector3.new(0, math.sign(normal.Y), 0), "Y"
    else
        return Vector3.new(0, 0, math.sign(normal.Z)), "Z"
    end
end

function Math:getNormalOfPointOnBoxRotated(boxCFrame, boxSize, point)
    local relativePosition = boxCFrame:PointToObjectSpace(point)
    local normal = self:getNormalOfPointOnBox(Vector3.zero, boxSize, relativePosition)

    return boxCFrame:VectorToWorldSpace(normal)
end

function Math:getNormalOfPointOnBox(boxPosition, boxSize, point)
    local relativePosition = (point - boxPosition) / boxSize

    local absX = math.abs(relativePosition.X)
    local absY = math.abs(relativePosition.Y)
    local absZ = math.abs(relativePosition.Z)

    local maxAxis = math.max(absX, absY, absZ)

    if maxAxis == absX then
        return Vector3.new(math.sign(relativePosition.X), 0, 0)
    elseif maxAxis == absY then
        return Vector3.new(0, math.sign(relativePosition.Y), 0)
    else
        return Vector3.new(0, 0, math.sign(relativePosition.Z))
    end
end

function Math:projectPointToPlane(planePosition, planeNormal, point)
    local direction = point - planePosition
    local distance = direction:Dot(planeNormal)
    return point - planeNormal * distance
end

function Math:closestPointToBoxRotated(boxCFrame, boxSize, point)
    local relativePoint = boxCFrame:PointToObjectSpace(point)
    local closestPoint = self:closestPointToBox(Vector3.zero, boxSize, relativePoint)

    return boxCFrame:PointToWorldSpace(closestPoint)
end

function Math:closestPointToBox(boxPosition, boxSize, point)
    local halfSize = boxSize / 2

    local clampedPoint = Vector3.new(
        math.clamp(point.X, boxPosition.X - halfSize.X, boxPosition.X + halfSize.X),
        math.clamp(point.Y, boxPosition.Y - halfSize.Y, boxPosition.Y + halfSize.Y),
        math.clamp(point.Z, boxPosition.Z - halfSize.Z, boxPosition.Z + halfSize.Z)
    )

    return clampedPoint
end

function Math:lineSegmentSphereIntersection(startPoint, endPoint, spherePosition, radius)
    local direction = endPoint - startPoint
    local sphereToStart = startPoint - spherePosition

    local a = direction:Dot(direction)
    local b = 2 * direction:Dot(sphereToStart)
    local c = sphereToStart:Dot(sphereToStart) - radius * radius

    local discriminant = b * b - 4 * a * c

    if discriminant < 0 then
        return nil -- no intersection
    elseif discriminant == 0 then
        local t = -b / (2 * a)
        if t >= 0 and t <= 1 then
            return startPoint + direction * t -- intersection at a single point
        else
            return nil -- no intersection within the line segment
        end
    else
        local t1 = (-b + math.sqrt(discriminant)) / (2 * a)
        local t2 = (-b - math.sqrt(discriminant)) / (2 * a)

        if (t1 >= 0 and t1 <= 1) and (t2 >= 0 and t2 <= 1) then
            return startPoint + direction * math.min(t1, t2) -- intersection at two points, return the closest one
        elseif t1 >= 0 and t1 <= 1 then
            return startPoint + direction * t1 -- intersection at one point
        elseif t2 >= 0 and t2 <= 1 then
            return startPoint + direction * t2 -- intersection at one point
        elseif direction.Magnitude <= radius then
            return startPoint -- line segment is completely inside the sphere
        else
            return nil -- no intersection within the line segment
        end
    end
end

function Math:clampPointToSphere(spherePosition, radius, point)
    --if the point is outside the sphere, move it so it's on the edge of the sphere

    local direction = point - spherePosition

    if direction.Magnitude <= radius then
        return point
    end

    local clampedPoint = spherePosition + direction.Unit * radius
    return clampedPoint
end

function Math:getReflectionAcrossNormal(direction, normal)
    return direction - 2 * direction:Dot(normal) * normal
end


return Math