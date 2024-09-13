local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local TempToolbar = Proto:serverClass({
    moduleName = "TempToolbar"
})

function TempToolbar:init2()
    Proto.ToolController:equip(self, true)
end

return TempToolbar