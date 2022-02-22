local Super = require(script.Parent)
local LevelService = Super:Extend()

local Configuration = require(Super.Storage.Configuration)

function LevelService:GetRequiredExperienceAtLevel(level)
	return 1000 + (3000 * (level - 1)) + (0.00025 * (level - 1) ^ 5)
end

function LevelService:AddExperience(player, experience)
	local dataService = self:GetService("DataService")
	local data = dataService:GetPlayerData(player)
	if not data then return end
	
	data.Experience += experience
	
	local didLevelUp = false
	
	while (data.Experience >= self:GetRequiredExperienceAtLevel(data.Level)) and (data.Level < Configuration.MaxLevel) do
		data.Experience -= self:GetRequiredExperienceAtLevel(data.Level)
		data.Level += 1
		didLevelUp = true
	end
	
	if data.Level >= Configuration.MaxLevel then
		data.Experience = 0
	end
	
	if didLevelUp then
		local legend = self:GetClass("Legend").GetLegendFromPlayer(player)
		if legend then
			legend:OnLeveledUp()
		end
	end
end

function LevelService:OnEnemyDefeated(enemy)
	if enemy.NoExperience then return end
	
	local experience = enemy.MaxHealth:Get() * 2.5
	
	for _, player in pairs(game:GetService("Players"):GetPlayers()) do
		self:AddExperience(player, experience)
	end
end

local Singleton = LevelService:Create()
return Singleton