local Players = game:GetService("Players")

local Super = require(script.Parent)
local QuestService = Super:Extend()

function QuestService:OnCreated()
	self.QuestLogsByPlayer = {}
	
	Players.PlayerAdded:Connect(function(...)
		self:OnPlayerAdded(...)
	end)
	
	Players.PlayerRemoving:Connect(function(...)
		self:OnPlayerRemoved(...)
	end)
end

function QuestService:ProcessGameplayEvent(player, event)
	local questLog = self.QuestLogsByPlayer[player]
	if not questLog then return end
	
	questLog:ProcessGameplayEvent(event)
end

function QuestService:ProcessGameplayEventAll(event)
	for _, player in pairs(game.Players:GetPlayers()) do
		self:ProcessGameplayEvent(player, event)
	end
end

function QuestService:LoadQuestLog(player)
	local dataService = self:GetService("DataService")
	local data = dataService:GetPlayerData(player)
	if not data then return end
	
	local questLog = self:CreateNew"QuestLog"{
		Player = player,
	}
	questLog:LoadData(data.QuestLogData)
	
	return questLog
end

function QuestService:AddQuestToPlayer(player, quest)
	local questLog = self.QuestLogsByPlayer[player]
	if not questLog then return end
	
	questLog:AddQuest(quest)
end

function QuestService:ClearPlayerQuests(player)
	local questLog = self.QuestLogsByPlayer[player]
	if not questLog then return end
	
	questLog:Clear()
end

function QuestService:OnPlayerAdded(player)
	self.QuestLogsByPlayer[player] = self:LoadQuestLog(player)
end

function QuestService:OnPlayerRemoved(player)
	self.QuestLogsByPlayer[player] = nil
end

local Singleton = QuestService:Create()
return Singleton