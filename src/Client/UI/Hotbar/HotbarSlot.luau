local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local HotbarSlot = Proto:clientClass({
    moduleName = "HotbarSlot",

    classSettings = {
        equippedScale = 1.2,
        hoveringScale = 1.1,
    }
})


local keyCodes = {
    "One",
    "Two",
    "Three",
    "Four",
    "Five",
    "Six",
    "Seven",
    "Eight",
    "Nine"
}


local equippedIndex = 0


function HotbarSlot.static:updateOrder(slots)
    self.slots = slots

    for index, slot in slots do
        slot:setSlotIndex(index)

        if slot.equipped then
            equippedIndex = index
        end
    end
end

function HotbarSlot.static:gamepadNext(indexOffset)
    if #self.slots == 0 then
        equippedIndex = 0
        return
    end

    equippedIndex = (equippedIndex % #self.slots) + indexOffset

    if equippedIndex ~= 0 then
        self:equipIndex(equippedIndex)
    end
end

function HotbarSlot.static:equipIndex(index)
    local slot = self.slots[index]

    slot:equip()
end

function HotbarSlot.static:init1()
    Proto.InputManager:getInputSignal("Began", false, "ButtonR1"):Connect(function()
        self:gamepadNext(1)
    end)

    Proto.InputManager:getInputSignal("Began", false, "ButtonL1"):Connect(function()
        self:gamepadNext(-1)
    end)
end


function HotbarSlot:init1()
    self.equipped = false
    self.hovering = false

    self.baseImage = self.instance.Image
    self.uiScale = self.instance:WaitForChild("UIScale")

    self.spring = Proto.Spring:new({
        speed = 2
    })

    Proto:declare(self, function(self, Proto)
        self.instance.Image = function(self, Proto)
            return self.UIButton.isHovering and self.equippedImage or self.baseImage
        end
        
        self.spring.target = function(self, Proto)
            if self.UIButton.isHovering and self.equipped then return self.hoveringScale * self.equippedScale end
            if self.UIButton.isHovering then return self.hoveringScale end
            if self.equipped then return self.equippedScale end

            return 1
        end

        self.uiScale.Scale = function(self, Proto)
            return self.spring.value
        end
    end)

    self.inputMaid = self.maid:extend()

    self.UIButton:Connect(function()
        self:activate()
    end)
end

function HotbarSlot:activate()
    if self.equipped then
        self:unequip()
    else
        self:equip()
    end
end

function HotbarSlot:equip()
    if self.equipped then return end

    HotbarSlot:unequip()
    self.equipped = true

    equippedIndex = self.index
end

function HotbarSlot:unequip()
    if not self.equipped then return end

    self.equipped = false
end

function HotbarSlot:setSlotIndex(slotIndex)
    self.inputMaid:clean()

    local keyCode = keyCodes[slotIndex]

    self.inputMaid:add(
        Proto.InputManager:getInputSignal("Began", false, keyCode, "TouchTap"):Connect(function()
            self:activate()
        end)
    )
end

return HotbarSlot