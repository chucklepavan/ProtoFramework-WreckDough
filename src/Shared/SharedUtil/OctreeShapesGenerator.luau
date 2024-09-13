local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local OctreeShapesGenerator = Proto:sharedModule({
    moduleName = "OctreeShapesGenerator"
})


local offsets = {
    Vector3.new(-1, -1, -1) / 2,
    Vector3.new(-1, -1, 1) / 2,
    Vector3.new(-1, 1, -1) / 2,
    Vector3.new(-1, 1, 1) / 2,
    Vector3.new(1, -1, -1) / 2,
    Vector3.new(1, -1, 1) / 2,
    Vector3.new(1, 1, -1) / 2,
    Vector3.new(1, 1, 1) / 2,
}


local RADIUS = 2
local RADIUS_SQUARED = RADIUS * RADIUS
local MAX_DEPTH = 4

function OctreeShapesGenerator:generateSphere()
    local treeBase = self:createTree(Vector3.zero, Vector3.one * 4, 1)

    self:checkSplit(treeBase)

    local parts = {}

    --recursivley go through each tree and turn it into a part
    local function render(tree)
        if tree.children then
            for _, child in tree.children do
                render(child)
            end
        else
            table.insert(parts, tree)
            --self:turnTreeInToPart(tree)
        end
    end

    render(treeBase)

    return parts
end

function OctreeShapesGenerator:checkSplit(tree)
    local state = Proto.Math:sphereTouchingBox(tree.position, tree.halfSize, Vector3.zero, RADIUS_SQUARED)
    if state == 0 then return false end

    if state == 2 then
        self:split(tree)
    end

    return true
end

function OctreeShapesGenerator:split(tree)
    if tree.depth == MAX_DEPTH then return end

    tree.children = {}

    for _, offset in offsets do
        local child = self:createTree(tree.position + tree.halfSize * offset, tree.halfSize, tree.depth + 1)

        local shouldAddChild = self:checkSplit(child)

        if shouldAddChild then
            table.insert(tree.children, child)
        end
    end

    self:checkMerge(tree)
end

function OctreeShapesGenerator:checkMerge(tree)
    if #tree.children == 0 then
        tree.children = nil

        return
    end

    if not tree.children or #tree.children ~= 8 then return end

    for _, child in tree.children do
        if child.children then return end
    end

    tree.children = nil
end

function OctreeShapesGenerator:createTree(position, size, depth)
    return {
        position = position,
        size = size,
        halfSize = size / 2,
        depth = depth
    }
end

function OctreeShapesGenerator:turnTreeInToPart(tree)
    local part = Instance.new("Part")
    part.Size = tree.size
    part.Position = tree.position
    part.Anchored = true
    part.BrickColor = BrickColor.random()
    part.Parent = workspace
end


return OctreeShapesGenerator