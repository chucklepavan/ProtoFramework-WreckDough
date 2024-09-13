local Proto, doNothing, parallelBreakpoint = _G.Proto, _G.doNothing, _G.parallelBreakpoint
local LoadingController = Proto:clientModule({
    moduleName = "LoadingController",
})




local minLoadingTime = 0
local maxLoadingTime = 0

local totalLoaded = 0


local loadingScreen = Proto.ReplicatedFirst:FindFirstChild("LoadingScreen")
if loadingScreen or not Proto.RunService:IsStudio() then
	loadingScreen.Parent = Proto.playerGui
	Proto.ReplicatedFirst:RemoveDefaultLoadingScreen()
end

if not loadingScreen then
	warn("no loading screen found")
end



function LoadingController:init1000()
	local timeLoaded = Proto.t - self.startLoad
	if timeLoaded < minLoadingTime then
		task.wait(minLoadingTime - timeLoaded)
	end

	self:loadingFinished()
end

function LoadingController:load()
	self.dataLoadedSignal = Proto.Signal.new()

	self:requestData()

	self.startLoad = Proto.t

	Proto.ContentProvider:PreloadAsync(Proto.StarterGui:GetDescendants(), self.elementLoaded)
	Proto.ContentProvider:PreloadAsync(Proto.SoundService:GetDescendants(), self.elementLoaded)
	Proto.ContentProvider:PreloadAsync(Proto.ReplicatedStorage:GetDescendants(), self.elementLoaded)
	Proto.ContentProvider:PreloadAsync(workspace:GetDescendants(), self.elementLoaded)

	if not game:IsLoaded() then
		game.Loaded:Wait()
	end

	self:yieldForData()
end

function LoadingController:yieldForData()
	if self.profileData then
		return self.profileData, self.gameData
	end

	self.dataLoadedSignal:Wait()
	return self.profileData, self.gameData
end

function LoadingController:requestData()
	task.spawn(function()
		self.profileData, self.gameData = Proto.network.PlayerManager.RemoteFunction:requestData()

		self.dataLoadedSignal:Fire(self.profileData, self.gameData)
	end)
end


function LoadingController:loadingFinished()
	--print("Total loaded elements: ", totalLoaded)

	if loadingScreen then
		loadingScreen:Destroy()
	end
end

function LoadingController.elementLoaded()
	totalLoaded += 1

	--local percentLoaded = totalLoaded / n
end

return LoadingController