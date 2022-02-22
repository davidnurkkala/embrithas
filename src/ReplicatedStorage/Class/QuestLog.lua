local Super = require(script.Parent)
local QuestLog = Super:Extend()

function QuestLog:CreateFromData(data)
	local object = self:Create()
	object:LoadData(data)
	return object
end

function QuestLog:OnCreated()
	self.Quests = {}
end

function QuestLog:GetSaveData()
	local data = {
		Quests = {}
	}
	
	for _, quest in ipairs(self.Quests) do
		table.insert(data.Quests, quest:GetSaveData())
	end
	
	return data
end

function QuestLog:LoadData(data)
	for _, questData in ipairs(data.Quests) do
		table.insert(self.Quests, self:GetClass("Quest"):CreateFromData(questData))
	end
	
	self:Replicate()
	self:Save()
end

function QuestLog:GiveRewards(rewards)
	for _, reward in pairs(rewards) do
		self:GiveReward(reward)
	end
end
function QuestLog:GiveReward(reward)
	if reward.Type == "Item" then
		self:GetService("InventoryService"):AddItem(self.Player, reward.Category, reward.Data)
		
	elseif reward.Type == "Gold" then
		local amount = reward.Amount
		
		self:GetService("InventoryService"):AddGold(self.Player, amount)
		
		self:FireRemote("NotificationRequested", self.Player, {
			Title = "Gold acquired!",
			Content = amount,
			Image = "rbxassetid://5272914329",
		})
		
	elseif reward.Type == "Quest" then
		local questData = require(self.Storage.QuestData)[reward.QuestId]
		self:AddQuest(self:GetClass("Quest"):CreateFromData(questData))
	end
end

function QuestLog:ProcessGameplayEvent(event)
	for index = #self.Quests, 1, -1 do
		local quest = self.Quests[index]
		
		quest:ProcessGameplayEvent(event)
		
		if quest:IsCompleted() then
			table.remove(self.Quests, index)
			self:GiveRewards(quest.Rewards)
		end
	end
	
	self:Replicate()
	self:Save()
end

function QuestLog:AddQuest(quest)
	table.insert(self.Quests, quest)
	
	self:Replicate()
	self:Save()
	
	-- ensure that the quest log is shown when a new quest is added
	self:GetService("OptionsService"):ChangePlayerOption(self.Player, "QuestLogHidden", false)
end

function QuestLog:Clear()
	self.Quests = {}
	
	self:Replicate()
	self:Save()
end

function QuestLog:Save()
	self:GetService("DataService"):GetPlayerData(self.Player).QuestLogData = self:GetSaveData()
end

function QuestLog:Replicate()
	self:FireRemote("QuestsUpdated", self.Player, self:GetSaveData())
end

return QuestLog