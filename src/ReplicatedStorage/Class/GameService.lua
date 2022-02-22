local Super = require(script.Parent)
local GameService = Super:Extend()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

GameService.IsLobby = false

GameService.Colors = {
	ReturnSystem = Color3.fromRGB(138, 200, 230),
	ChallengeSystem = Color3.fromRGB(255, 128, 128),
}

GameService.LobbyRunData = {
	Name = "City of Peace",
	Description = "",
	Level = math.huge,
	PartySize = 999,
	
	Floors = {
		[1] = {
			Name = "Slayer Alliance Headquarters",
			Type = "Lobby",
			Args = {}
		},
	},
}

function GameService:OnCreated()
	self.Challenges = {}
	
	self:GetService("AnalyticsService")
	self:GetService("OptionsService")
	self:GetService("PurchaseService")
	self:GetService("ChatService")
	self:GetService("MusicService")
	self:GetService("PlayerListService")
	self:GetService("InventoryService")
	self:GetService("TalentService")
	self:GetService("StatService")
	self:GetService("QuestService")
	self:GetService("LootService")
	self:GetService("DebugService")
	
	self:ConnectRemote("ReturnedToBase", self.OnPlayerReturned, true)
	
	-- just to prevent invocation queue exhaustion
	self:ConnectRemote("AimPositionUpdated", function() end, true)
	
	local function onPlayerAdded(player)
		self:OnPlayerAdded(player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	
	for _, missionModule in pairs(self.Storage.Missions:GetChildren()) do
		require(missionModule).MissionId = missionModule.Name
	end
	
	if RunService:IsStudio() then
		self.RunData = self:GetTestRunData()
	else
		local player = Players:GetPlayers()[1]
		if not player then
			player = Players.PlayerAdded:Wait()
		end
		
		local teleportData = player:GetJoinData().TeleportData
		if teleportData and teleportData.MissionId then
			local missionId = player:GetJoinData().TeleportData.MissionId
			
			if missionId == "lobby" then
				self.RunData = self.LobbyRunData
				self.IsLobby = true
			else
				local missionModule = self.Storage.Missions:FindFirstChild(missionId)
				self.RunData = require(missionModule)
			end
			
			if teleportData.MaxPlayerLevel then
				self.RunData.MaxPlayerLevel = teleportData.MaxPlayerLevel
			end
			if teleportData.Difficulty then
				self.RunData.Difficulty = teleportData.Difficulty
			end
			if teleportData.Args then
				for key, val in pairs(teleportData.Args) do
					self.RunData[key] = val
				end
			end
		else
			self.RunData = self.LobbyRunData
			self.IsLobby = true
		end
	end
	
	self:StartNewRun()
end

function GameService:OnPlayerAdded(player)
	local function onPlayerChatted(message)
		self:OnPlayerChatted(player, message)
	end
	player.Chatted:Connect(onPlayerChatted)
	
	if self.IsLobby then
		self:GetService("EffectsService"):RequestEffect(player, "ChatMessage", {
			Text = [[Type "/challenge [username]" to challenge a player to a Contest of Slayers.]],
			Color = self.Colors.ChallengeSystem,
			TextSize = 14,
		})
	else
		self:GetService("EffectsService"):RequestEffect(player, "ChatMessage", {
			Text = "Type \"/return\" to return to base.",
			Color = self.Colors.ReturnSystem,
			TextSize = 14,
		})
		self:GetService("EffectsService"):RequestEffect(player, "ChatMessage", {
			Text = "Type \"/unstuck\" if you happen to get someplace you're not supposed to.",
			Color = self.Colors.ReturnSystem,
			TextSize = 14,
		})
	end
end

function GameService:OnPlayerChatted(player, message)
	message = string.lower(message)
	
	if (message == "/return") or (message == "/r") then
		self:OnPlayerReturned(player)
	elseif (message == "/unstuck") then
		self:OnPlayerUnstuck(player)
	elseif (string.sub(message, 1, 10) == "/challenge") then
		if not self.IsLobby then return end
		local username = string.sub(message, 12)
		self:OnPlayerChallenged(player, username)
		
	elseif message == "/defaultoptions" then
		self:GetService("OptionsService"):ResetPlayerOptions(player)
	elseif message == "/pts" then
		game:GetService("TeleportService"):Teleport(2039079715, player)
	end
end

function GameService:OnChallengeAccepted(challenge)
	-- clear challenges involving these players
	for index = #self.Challenges, 1, -1 do
		local otherChallenge = self.Challenges[index]
		if	(otherChallenge.Challenger == challenge.Challenger) or
			(otherChallenge.Challenged == challenge.Challenger) or
			(otherChallenge.Challenger == challenge.Challenged) or
			(otherChallenge.Challenged == challenge.Challenged)
		then
			table.remove(self.Challenges, index)
		end
	end
	
	-- teleport 'em
	local teleportGui = self.Storage.UI.LoadingGui:Clone()
	teleportGui.TitleLabel.Text = "The Contest of Slayers"
	teleportGui.TipLabel.Text = "Prepare yourselves for combat, slayers!"

	local teleportData = {
		MissionId = "contestOfSlayers",
		Difficulty = "Rookie",

		Args = {
			Teams = {
				Red = {challenge.Challenger.UserId},
				Blue = {challenge.Challenged.UserId},
			},
		},
	}

	local players = {challenge.Challenger, challenge.Challenged}
	self:GetService("DataService"):SaveGroupDataAsync(players)

	pcall(function()
		teleportData = self:GetService("AnalyticsService"):AddTeleportData(players, teleportData)
	end)

	for _, player in pairs(players) do
		teleportGui:Clone().Parent = player:FindFirstChild("PlayerGui")
	end

	local placeId = game.PlaceId
	local serverId = TeleportService:ReserveServer(placeId)
	TeleportService:TeleportToPrivateServer(placeId, serverId, players, nil, teleportData, teleportGui)
end

function GameService:OnPlayerChallenged(challenger, username)
	local challenged
	for _, player in pairs(Players:GetPlayers()) do
		local name = string.lower(player.Name)
		if username == name then
			challenged = player
			break
		end
		if string.find(name, username) then
			challenged = player
		end
	end
	
	if not challenged then return end
	if challenged == challenger then return end
	
	for _, challenge in pairs(self.Challenges) do
		if (challenge.Challenged == challenger) and (challenge.Challenged == challenger) then
			return self:OnChallengeAccepted(challenge)
			
		elseif (challenge.Challenger == challenger) and (challenge.Challenged == challenged) then
			challenge.Time = 30
			return
		end
	end
	
	local challenge = {
		Challenger = challenger,
		Challenged = challenged,
		Time = 30,
	}
	table.insert(self.Challenges, challenge)
	spawn(function()
		while challenge.Time > 0 do
			challenge.Time -= wait(1)
		end
		table.remove(self.Challenges, table.find(self.Challenges, challenge))
	end)
	
	delay(0.25, function()
		self:GetService("EffectsService"):RequestEffect(challenged, "ChatMessage", {
			Text = string.format([[%s has challenged you to a Contest of Slayers. Type "/challenge %s" to accept the challenge.]], challenger.Name, challenger.Name),
			Color = self.Colors.ChallengeSystem,
			TextSize = 14,
		})
	end)
end

function GameService:OnPlayerUnstuck(player)
	if self.IsLobby then return end
	
	local legend = self:GetClass("Legend").GetLegendFromPlayer(player)
	if not legend then return end
	
	if legend:Channel(10, "Unstuck", "Sensitive") then
		local position = self:GetRun().Dungeon:GetRespawnPosition(legend:GetPosition())
		legend.Root.CFrame = CFrame.new(position)
	end
end

function GameService:OnPlayerReturned(player)
	if self.IsLobby then return end
	
	if self.OngoingReturn then
		if table.find(self.OngoingReturn.Players, player) then return end
		
		table.insert(self.OngoingReturn.Players, player)
	else
		self.OngoingReturn = {
			TimeRemaining = 20,
			Players = {player},
		}
		
		spawn(function()
			while self.OngoingReturn.TimeRemaining > 0 do
				self.OngoingReturn.TimeRemaining = self.OngoingReturn.TimeRemaining - wait(0.1)
				
				if #self.OngoingReturn.Players == #Players:GetPlayers() then
					break
				end
			end
			
			local teleportGui = self.Storage.UI.LoadingGui:Clone()
			teleportGui.TitleLabel.Text = "Slayer Alliance Headquarters"
			teleportGui.TipLabel.Text = ""
			
			local players = self.OngoingReturn.Players
			self.OngoingReturn = nil
			
			local teleportData = {}
			teleportData = self:GetService("AnalyticsService"):AddTeleportData(players, teleportData)
			
			for _, player in pairs(players) do
				teleportGui:Clone().Parent = player.PlayerGui
			end
			
			game:GetService("TeleportService"):TeleportPartyAsync(game.PlaceId, players, teleportData, teleportGui)
		end)
	end
	
	local timeRemaining = self.OngoingReturn.TimeRemaining
	delay(0.05, function()
		self:GetService("EffectsService"):RequestEffectAll("ChatMessage", {
			Text = string.format(
				"%s has decided to return to base. Type \"/return\" to join them. The group will depart in %d seconds...",
				player.Name,
				timeRemaining
			),
			Color = self.Colors.ReturnSystem,
			TextSize = 14,
		})
	end)
end

function GameService:StartNewRun()
	local runType = self.RunData.Type or "Run"
	
	local run = self:CreateNew(runType){
		RunData = self:DeepCopy(self.RunData),
	}
	run.Finished:Connect(function()
		self:OnRunFinished()
	end)
	self.CurrentRun = run
end

function GameService:OnRunFinished()
	self:GetWorld():Clear()
	wait(5)
	self:StartNewRun()
end

function GameService:GetTestRunData()
	local data = require(self.Storage.Missions.testMission)
	
	if data.Floors and data.Floors[1] and (data.Floors[1].Type == "Lobby") then
		self.IsLobby = true
	end
	
	return data
end

local Singleton = GameService:Create()
return Singleton