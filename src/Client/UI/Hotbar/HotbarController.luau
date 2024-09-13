local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local HotbarController = Proto:clientClass({
    moduleName = "HotbarController",

    classSettings = {
        slotTemplateName = "",
    },

    slots = {}
})


--[[
function HotbarController.static:init100()
    task.delay(3, function()
        for i = 1, 9 do
            self:toolAdded({
                toolIconId = "rbxassetid://0"
            })
        end
    end)
end]]

function HotbarController:toolAdded(toolController)
    local object = Proto:cloneFromTemplate(self.slotTemplateName, self.instance)

    local slot = object.HotbarSlot
    slot.instance.ToolIcon.Image = toolController.toolIconId
    slot.toolController = toolController

    table.insert(self.slots, slot)
    slot:updateOrder(self.slots)
end

function HotbarController:toolRemoved(toolController)
    for index, slot in (self.slots) do
        if slot.toolController == toolController then
            table.remove(self.slots, index)
            slot:updateOrder(self.slots)
            slot.object:destroy()
        end    
    end
end

return HotbarController