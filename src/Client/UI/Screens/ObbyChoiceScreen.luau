local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local ObbyChoiceScreen = Proto:clientClass({
    moduleName = "ObbyChoiceScreen"
})


--TODO: make method type .spawn for running function on diff thread


function ObbyChoiceScreen:init2()
    task.delay(2.5, function()
        self.screen:open()
    end)
end



return ObbyChoiceScreen