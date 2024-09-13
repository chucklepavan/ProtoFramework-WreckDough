local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local PlayerManager = Proto:serverModule({
    moduleName = "PlayerManager",

    profiles = {},
})


local yieldedRequests = {}
local requested = {}


local storeKey = "Data_2"


function PlayerManager:init1()
	self.profileLoadedSignal = Proto.Signal.new()

	Proto:playerAddedCallback(self.playerAdded, self)
	Proto:playerRemovingCallback(self.playerRemoving, self)

    self.profileStore = Proto.ProfileService.GetProfileStore(storeKey, Proto.DataTemplate.template)
end

function PlayerManager:saveDataLoadedCallback(method, module)
	assert(method, "Missing argument: method")
	assert(module, "Missing argument: module")

	self.profileLoadedSignal:Connect(function(player, profile)
		method(module, player, profile.Data)
	end)

	for player, profile in pairs(self.profiles) do
		task.spawn(method, module, player, profile.Data)
	end
end

function PlayerManager:playerAdded(player)
	if self.profiles[player] then return end
	
	if Proto.BanList:hasPlayer(player) then
		player:Kick("Something went wrong, please rejoin")
		return
	end

	local profile = self.profileStore:LoadProfileAsync(tostring(player.UserId), "ForceLoad")
	if not profile then
		self:dataFail(player, "Data failed to load")
		return
	end
	
	profile:AddUserId(player.UserId)
	profile:Reconcile()
	
	profile:ListenToRelease(function()
		self:dataFail(player, "Data loaded on another server [ALL DATA HAS BEEN SAVED]")
	end)
	
	self:addProfile(player, profile)
end

function PlayerManager:playerRemoving(player)
    self:resumeRequest(player)

	local profile = self.profiles[player]
	if not profile then return end

	self.profiles[player] = nil
    requested[player] = nil

	profile:Release()
end

function PlayerManager:addProfile(player, profile)
	Proto.ProfileVersionUpdates:updateVersion(profile)

	self.profiles[player] = profile

	Proto.LeaderStatsManager:addPlayer(player, profile)

	self.profileLoadedSignal:Fire(player, profile)
	self:resumeRequest(player, profile)
end

function PlayerManager.RemoteFunction:requestData(player)
    if requested[player] or not self:isInGame(player) then return end
    requested[player] = true

	local profile = self.profiles[player]
	if not profile then
		profile = self:yieldUntilLoaded(player)

		if not profile then return end--data failed to load alr kicked player
	end

	if not self:isInGame(player) then return end--could have left while waiting for data

	local playerObject = Proto:getObjectFromInstance(player)

	if playerObject.CharacterLoader then
		playerObject.CharacterLoader:load()
	else
		warn("no CharacterLoader on player object")
	end

	return profile.Data, Proto.GameDataManager:getGameData(player, profile)
end

function PlayerManager:yieldUntilLoaded(player)
	yieldedRequests[player] = coroutine.running()
	return coroutine.yield()
end

function PlayerManager:resumeRequest(player, profile)
	local thread = yieldedRequests[player]
	if not thread then return end

	yieldedRequests[player] = nil
	local success, err = coroutine.resume(thread, profile)

	if not success then
		error(err)
	end
end

function PlayerManager:dataFail(player, reason)
	if self:isInGame(player) then
		player:Kick(reason..", please rejoin")
	end
end

function PlayerManager:isInGame(player)
	return player.Parent == Proto.Players
end

function PlayerManager:getSaveData(player)
	local profile = self.profiles[player]
	if not profile then return end

	return profile.Data
end


return PlayerManager