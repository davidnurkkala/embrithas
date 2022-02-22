local Players = game:GetService("Players")

local StatTalents = {
	Strength = {1, 2, 3, 4},
	Agility = {5, 6, 7, 8},
	Constitution = {9, 10, 11, 12},
	Perseverance = {13, 14, 15, 16},
	Dominance = {17, 18, 19, 20},
	Compassion = {21, 22, 23, 24},
}

local Super = require(script.Parent)
local TalentService = Super:Extend()

function TalentService:OnCreated()
	self:ConnectRemote("TalentsUpdated", self.OnTalentsUpdated, true)
	
	Players.PlayerAdded:Connect(function(...)
		self:OnPlayerAdded(...)
	end)
end

function TalentService:OnPlayerAdded(player)
	self:UpdatePlayer(player)
end

function TalentService:GetData(player)
	return self:GetService("DataService"):GetPlayerData(player)
end

function TalentService:GetLegend(player)
	return self:GetClass("Legend").GetLegendFromPlayer(player)
end

function TalentService:WithLegend(player, callback)
	local legend = self:GetLegend(player)
	if legend then
		callback(legend)
	end
end

function TalentService:OnTalentsUpdated(player, action, ...)
	self["OnTalent"..action](self, player, ...)
end

function TalentService:GetTalentData(talentId)
	return require(self.Storage.TalentData)[talentId]
end

function TalentService:GetAvailableSlots(player)
	local data = self:GetData(player)
	return math.floor((data.Level - 3) / 12)
end

function TalentService:GetTalentInfo(player)
	local data = self:GetData(player)
	
	local info = {
		AvailableSlots = self:GetAvailableSlots(player),
		Equipped = data.EquippedTalents,
		Unlocked = data.UnlockedTalents,
	}
	
	return info
end

function TalentService:UpdatePlayer(player)
	self:FireRemote("TalentsUpdated", player, self:GetTalentInfo(player))
end

function TalentService:OnTalentEquipped(player, talentId)
	local data = self:GetData(player)
	
	-- check that we don't have it equipped and that it's unlocked
	if table.find(data.EquippedTalents, talentId) then return end
	if table.find(data.UnlockedTalents, talentId) == nil then return end
	
	-- check that you don't have too many talents
	if #data.EquippedTalents >= self:GetAvailableSlots(player) then return end
	
	-- check for exclusive talents
	local talentData = self:GetTalentData(talentId)
	if talentData.Exclusions then
		for _, exclusion in pairs(talentData.Exclusions) do
			if table.find(data.EquippedTalents, exclusion) then
				return
			end
		end
	end
	
	table.insert(data.EquippedTalents, talentId)
	
	self:WithLegend(player, function(legend)
		legend:EquipTalent(talentId)
	end)
	
	self:UpdatePlayer(player)
end

function TalentService:OnTalentUnequipped(player, talentId)
	local data = self:GetData(player)
	
	local index = table.find(data.EquippedTalents, talentId)
	if index == nil then return end
	
	table.remove(data.EquippedTalents, index)
	
	self:WithLegend(player, function(legend)
		legend:UnequipTalent(talentId)
	end)
	
	self:UpdatePlayer(player)
end

function TalentService:LockTalent(player, talentId)
	local data = self:GetData(player)
	
	local index = table.find(data.UnlockedTalents, talentId)
	if index == nil then return end
	
	table.remove(data.UnlockedTalents, index)
	self:OnTalentUnequipped(player, talentId)
	
	self:UpdatePlayer(player)
end

function TalentService:UnlockTalent(player, talentId)
	local data = self:GetData(player)
	
	if table.find(data.UnlockedTalents, talentId) then return end
	
	table.insert(data.UnlockedTalents, talentId)
	
	self:UpdatePlayer(player)
end

function TalentService:CheckStatTalents(player)
	local data = self:GetData(player)
	local statService = self:GetService("StatService")
	
	for statName, talentIdsByTier in pairs(StatTalents) do
		for tier, talentId in pairs(talentIdsByTier) do
			local requirement = 70 + (tier - 1) * 60
			if tier == 1 then
				requirement -= 10
			end
			
			local stat = statService:GetStat(player, statName)
			
			if stat >= requirement then
				self:UnlockTalent(player, talentId)
			else
				self:LockTalent(player, talentId)
			end
		end
	end
end

local Singleton = TalentService:Create()
return Singleton