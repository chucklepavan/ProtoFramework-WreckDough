local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local ProfileVersionUpdates = Proto:serverModule({
	moduleName = "ProfileVersionUpdates",
})

local updates = {}

--[[
updates[1] = function(player, profile)
	profile.pets.elephant = revampedElephant
end
]]

function ProfileVersionUpdates:init1()
	self.currentVersion = #updates
end

function ProfileVersionUpdates:updateVersion(profile)
	local lastVersion = profile.Data.dataVersion
	if not lastVersion or lastVersion == self.currentVersion then return end
	
	for index = lastVersion + 1, self.currentVersion do
		updates[index](profile)
	end
	
	profile.Data.dataVersion = self.currentVersion
end


return ProfileVersionUpdates