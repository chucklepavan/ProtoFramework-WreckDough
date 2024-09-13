local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local ToolController = Proto:serverClass({
    moduleName = "ToolController"
})

function ToolController:init1()
    self.activateSignal = Proto.Signal.new()
    self.equipSignal = Proto.Signal.new()
    self.unequipSignal = Proto.Signal.new()

    self.toolConstraint = Instance.new("RigidConstraint")
    self.toolConstraint.Name = "ToolConstraint"
    self.toolConstraint.Parent = self.instance
end

function ToolController:activate()
    self.activateSignal:Fire()
end

function ToolController:equip(characterObject, isRightArm : boolean)
    print("Equip called!")
    local character = characterObject.instance
    local rightHand = character:WaitForChild("RightHand")
    local rightGrip = rightHand:WaitForChild("RightGripAttachment")

    local leftHand = character:WaitForChild("LeftHand")
    local leftGrip = leftHand:WaitForChild("LeftGripAttachment")

    self.instance.Parent = character
    local handleAttachment = self.instance:FindFirstChild("HandleAttachment", true)

    self.toolConstraint.Attachment0 = handleAttachment
    if isRightArm then
        self.toolConstraint.Attachment1 = rightGrip
    else
        self.toolConstraint.Attachment1 = leftGrip
    end

    self.equipSignal:Fire()
end

function ToolController:unequip(playerObject)
    local backpack = playerObject.instance:FindFirstChild("Backpack")

    self.toolConstraint.Attachment0 = nil
    self.toolConstraint.Attachment1 = nil

    self.instance.Parent = backpack
    self.unequipSignal:Fire()
end

return ToolController