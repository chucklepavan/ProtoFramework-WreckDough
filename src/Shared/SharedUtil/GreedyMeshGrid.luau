local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local GreedyMeshGrid = Proto:sharedClass({
    moduleName = "GreedyMeshGrid",

    classSettings = {
        size = Vector3.one,
        center = Vector3.zero,
    },
})

function GreedyMeshGrid:init1()
    self.sizeX = self.size.X
    self.sizeY = self.size.Y
    self.sizeZ = self.size.Z

    assert(self.sizeX > 0 and self.sizeY > 0 and self.sizeZ > 0, "size must be greater than 0")
    assert(self.sizeX % 1 == 0 and self.sizeY % 1 == 0 and self.sizeZ % 1 == 0, "size must be an integer")


    self.grid = self:create3DArray(false)

    self.offsetVector = Vector3.new(
        (self.sizeX + 1) / 2,
        (self.sizeY + 1) / 2,
        (self.sizeZ + 1) / 2
    ) - self.center
end

function GreedyMeshGrid:getVoxels()
    local parts = {}  

    for x = 1, self.sizeX do
        for y = 1, self.sizeY do
            for z = 1, self.sizeZ do
                if self.grid[x][y][z] then
                    table.insert(parts, {
                        Vector3.new(x, y, z) - self.offsetVector,
                        Vector3.one,
                    })
                end
            end
        end
    end

    return parts
end

function GreedyMeshGrid:getParts()
    local visited = self:create3DArray(false)
    local parts = {}

    for x = 1, self.sizeX do
        for y = 1, self.sizeY do
            for z = 1, self.sizeZ do
                if self.grid[x][y][z] and not visited[x][y][z] then
                    local chunkInfo = self:getChunk(x, y, z, visited)
                    
                    table.insert(parts, chunkInfo)
                end
            end
        end
    end

    return parts
end

function GreedyMeshGrid:getChunk(x, y, z, visited)
    local ex, ey, ez = x, y, z

    while ex + 1 <= self.sizeX and self.grid[ex + 1][y][z] and not visited[ex + 1][y][z] do
        ex += 1
    end

    while ey + 1 <= self.sizeY and self:isRowClear(x, ex, ey + 1, z, visited) do
        ey += 1
    end

    while ez + 1 <= self.sizeZ and self:isPlaneClear(x, ex, y, ey, ez + 1, visited) do
        ez += 1
    end

    for i = x, ex do
        for j = y, ey do
            for k = z, ez do
                visited[i][j][k] = true
            end
        end
    end

    local lower = Vector3.new(x, y, z)
    local upper = Vector3.new(ex, ey, ez)

    return {
        (lower + upper) / 2 - self.offsetVector,
        upper - lower + Vector3.one,
    }
end

function GreedyMeshGrid:isRowClear(sx, ex, y, z, visited)
    for x = sx, ex do
        if not self.grid[x][y][z] or visited[x][y][z] then
            return false
        end
    end

    return true
end

function GreedyMeshGrid:isPlaneClear(sx, ex, sy, ey, z, visited)
    for x = sx, ex do
        for y = sy, ey do
            if not self.grid[x][y][z] or visited[x][y][z] then
                return false
            end
        end
    end

    return true
end



function GreedyMeshGrid:fillBox(position, size)
    local lowerBound = position - size / 2
    local upperBound = position + size / 2

    self:fillBounds(lowerBound, upperBound)
end

function GreedyMeshGrid:fillBounds(lowerBound, upperBound)
    lowerBound = self:fixPosition(lowerBound)
    upperBound = self:fixPosition(upperBound)

    for x = lowerBound.X, upperBound.X do
        for z = lowerBound.Z, upperBound.Z do
            for y = lowerBound.Y, upperBound.Y do
                self:fillXYZ(x, y, z)
            end
        end
    end
end


function GreedyMeshGrid:getXYZ(x, y, z)
    return self.grid[x][z][y]
end

function GreedyMeshGrid:getPosition(position)
    position = self:fixPosition(position)
    
    return self.grid[position.X][position.Y][position.Z]
end


function GreedyMeshGrid:fillXYZ(x, y, z)
    assert(x <= self.sizeX and y <= self.sizeY and z <= self.sizeZ, "position out of bounds")

    self.grid[x][y][z] = true
end

function GreedyMeshGrid:fillPosition(position)
    position = self:fixPosition(position)

    self.grid[position.X][position.Y][position.Z] = true
end

function GreedyMeshGrid:fixPosition(position)
    position += self.offsetVector

    return Vector3.new(
        math.clamp(math.round(position.X), 1, self.sizeX),
        math.clamp(math.round(position.Y), 1, self.sizeY),
        math.clamp(math.round(position.Z), 1, self.sizeZ)
    )
end

function GreedyMeshGrid:create3DArray(defaultValue)
    local array = table.create(self.sizeX)

    for x = 1, self.sizeX do
        array[x] = table.create(self.sizeY)

        for y = 1, self.sizeY do
            array[x][y] = table.create(self.sizeZ)

            for z = 1, self.sizeZ do
                array[x][y][z] = defaultValue
            end
        end
    end

    return array
end


return GreedyMeshGrid