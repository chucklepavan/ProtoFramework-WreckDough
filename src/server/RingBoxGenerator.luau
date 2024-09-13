local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local RingBoxGenerator = Proto:serverModule({
    moduleName = "RingBoxGenerator"
})


local PART_DENSITY = 5
local RESOLUTION = 4--inverse of this is grid size
local PART_WIDTH = 1

local RESOLUTION_DIVIDE_VECTOR = Vector3.new(RESOLUTION, 1, RESOLUTION)



function RingBoxGenerator:init1()
    --self:generate()
end

function RingBoxGenerator:generate()
    --local x = depth / (count - 1)
    --local mult = (math.sqrt(1 - x) * (count - 1))

    local ringsArrays = {}


    local ringFolders = Proto.ReplicatedStorage.RingFolders

    task.spawn(function()
        task.wait(1)

        for radius = 200, 200 do
            task.spawn(function()
                local rings = self:generateRingsOfRadiusAsync(radius, 5)
                ringsArrays[radius] = rings
    
                local radiusFolder = Instance.new("Folder")
                radiusFolder.Name = radius
                radiusFolder.Parent = ringFolders

                for index, ring in rings do
                    if radiusFolder:FindFirstChild(index) then
                        error("ring already exists "..index)
                    end

                    local ringFolder = Instance.new("Folder")
                    ringFolder.Name = index
                    ringFolder.Parent = radiusFolder

                    for _, partInfo in ring do
                        local part = Instance.new("Part")
                        part.Size = partInfo[2] / RESOLUTION_DIVIDE_VECTOR
                        part.Anchored = true
                        part.Position = partInfo[1] / RESOLUTION_DIVIDE_VECTOR
                        part.Parent = ringFolder
                    end
                end

                print("done")
            end) 
        end
    end)
    
    --[[
    local start = os.clock()
    for i = 1, 1 do
        table.insert(ringsArrays, self:generateRingsOfRadiusAsync(i, 5))
    end
    print("took", os.clock() - start)]]
end

function RingBoxGenerator.parallel:generateRingsOfRadiusAsync(radius, count)
    local rings = {}

    for _ = 1, count do
        parallelBreakpoint()
        table.insert(rings, self:generateRing(radius))
    end

    return rings
end

function RingBoxGenerator:generateRing(radius)
    local sizeMult = 3
    local radiusMult = sizeMult + 1.2

    radius /= radiusMult
    radius *= RESOLUTION

    local greedyMeshSize = math.ceil(radius * radiusMult)

    local greedyGrid = Proto.GreedyMeshGrid:new({
        size = Vector3.new(greedyMeshSize, 1, greedyMeshSize),
    })

    for _ = 1, math.max(math.round(radius * PART_DENSITY / RESOLUTION), 1) do
        local position = self:randomPositionInCircle() * radius
        local size = self:randomSize() * sizeMult * radius + Vector3.yAxis * PART_WIDTH

        greedyGrid:fillBox(position, size)
    end

    
    local parts = greedyGrid:getParts()

    return parts
end

function RingBoxGenerator:randomSize()
    while true do
        local vector = self:randomPositionInCircle()

        vector = Vector3.new(
            math.abs(vector.X),
            0,
            math.abs(vector.Z)
        )

        if math.min(vector.X, vector.Z) < 0.2 then
            continue
        end

        return vector
    end
end

function RingBoxGenerator:randomPositionInCircle()
    while true do
        local position = Vector3.new(
            math.random() * 2 - 1,
            0,
            math.random() * 2 - 1
        )

        if position.magnitude <= 1 then
            return position
        end
    end
end


return RingBoxGenerator