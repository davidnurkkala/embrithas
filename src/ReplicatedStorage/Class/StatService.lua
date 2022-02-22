local RunService = game:GetService("RunService")

local Super = require(script.Parent)
local StatService = Super:Extend()

StatService.StatPointsPerLevel = 5

function StatService:OnCreated()
	if RunService:IsServer() then
		self:ConnectRemote("StatUpgraded", self.OnStatUpgraded, true)
	end
end

function StatService:GetAverageStatInvestment()
	local statCount = 6
	return self.StatPointsPerLevel / statCount
end

function StatService:GetRemainingStatPoints(player)
	local data = self:GetData(player)

	local statPointsPerLevel = self.StatPointsPerLevel
	local totalStatPoints = statPointsPerLevel * data.Level

	for _, value in pairs(data.Stats) do
		totalStatPoints -= value
	end

	return totalStatPoints
end

function StatService:GetLegend(player)
	return self:GetClass("Legend").GetLegendFromPlayer(player)
end

function StatService:WithLegend(player, callback)
	local legend = self:GetLegend(player)
	if legend then
		callback(legend)
	end
end

function StatService:GetData(player)
	return self:GetService("DataService"):GetPlayerData(player)
end

function StatService:GetStat(player, statName)
	return self:GetData(player).Stats[statName]
end

function StatService:ResetStats(player)
	local data = self:GetData(player)
	for statName, value in pairs(data.Stats) do
		data.Stats[statName] = 0
	end
	
	self:WithLegend(player, function(legend)
		for statName, value in pairs(data.Stats) do
			legend[statName].Base = value
		end
	end)
	
	self:CheckStatTalents(player)
end

function StatService:OnStatUpgraded(player, statName)
	local remainingStatPoints = self:GetRemainingStatPoints(player)
	if remainingStatPoints < 1 then return end

	local data = self:GetData(player)
	if not data.Stats[statName] then return end

	data.Stats[statName] += 1

	self:WithLegend(player, function(legend)
		for statName, value in pairs(data.Stats) do
			legend[statName].Base = value
		end
	end)
	
	self:CheckStatTalents(player)
end

function StatService:CheckStatTalents(player)
	self:GetService("TalentService"):CheckStatTalents(player)
end

function StatService:GetPower(level, statValue)
	return 10 + (level * 1.5) + (statValue * 0.75)
end

local Singleton = StatService:Create()
return Singleton