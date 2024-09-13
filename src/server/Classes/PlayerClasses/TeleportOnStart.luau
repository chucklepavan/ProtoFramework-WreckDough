local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local TeleportOnStart = Proto:serverClass({
    moduleName = "TeleportOnStart",

    classSettings = {
        teleportCategory = nil,
    },
})


function TeleportOnStart:init1()
    assert(self.teleportCategory, "TeleportOnStart: No teleport category specified")
    print("runnign")
    Proto.TeleportPoint:moveCharacter(self.teleportCategory, self)
end


return TeleportOnStart