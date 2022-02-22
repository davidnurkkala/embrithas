local RunService = game:GetService("RunService")

local Super = require(script.Parent)
local Ability = Super:Extend()

Ability.Type = "Utility"
Ability.ClientCooldown = 0.05

function Ability:OnCreated()
	self.Cooldown = self:CreateNew"Cooldown"{Time = 1}
	self.Targeting = self:GetService("TargetingService")
end

function Ability:IsType(abilityType)
	if typeof(self.Type) == "string" then
		return self.Type == abilityType
	else
		return table.find(self.Type, abilityType) ~= nil
	end
end

function Ability:GetUpgrades()
	return self.Data.Upgrades or 0
end

function Ability:GetTypeString()
	if typeof(self.Type == "string") then
		return self.Type
	else
		return table.concat(self.Type, " ")
	end
end

function Ability:HasSameType(ability)
	if typeof(self.Type) == "string" then
		return ability:IsType(self.Type)
	else
		for _, abilityType in pairs(self.Type) do
			if ability:IsType(abilityType) then
				return true
			end
		end
		return false
	end
end

function Ability:GetDescription()
	return "This is the base ability description. If you're seeing this, report it to the developer."
end

function Ability:GetNearestEnemyInRange(range, visionRequired)
	if visionRequired == nil then visionRequired = true end
	local enemies = self:GetService("TargetingService"):GetEnemies()
	local best = nil
	local bestDistanceSq = range ^ 2
	for _, enemy in pairs(enemies) do
		local distanceSq = self.Legend:DistanceToSquared(enemy:GetPosition())
		if distanceSq <= bestDistanceSq then
			local canSee = self.Legend:CanSeePoint(enemy:GetPosition()) or (not visionRequired) 
			if canSee then
				best = enemy
				bestDistanceSq = distanceSq
			end
		end
	end
	return best
end

function Ability:GetLevel()
	if RunService:IsServer() then
		return self.Legend.Level
	else
		return self:GetService("GuiClient").Level
	end
end

function Ability:GetStatValue(statName)
	if RunService:IsServer() then
		return self.Legend[statName]:Get()
		
	elseif RunService:IsClient() then
		return self:GetService("CharacterScreenClient"):GetStatValue(statName)
	end
end

function Ability:IsTalentEquipped(talentId)
	if RunService:IsServer() then
		return self.Legend:IsTalentEquipped(talentId)
		
	elseif RunService:IsClient() then
		local equippedTalents = self:GetService("CharacterScreenClient").EquippedTalents
		return table.find(equippedTalents, talentId) ~= nil
	end
end

function Ability:GetWeaponClassName()
	if RunService:IsServer() then
		return self.Legend.Weapon.Data.Class
	else
		local inventory = self:GetService("InventoryClient").Inventory
		if not inventory then return end

		local index = inventory.EquippedWeaponIndex
		if not inventory then return end

		local slotData = inventory.Weapons[index]
		if not slotData then return end

		local itemData = require(self.Storage.ItemData).Weapons[slotData.Id]
		if not itemData then return end

		return itemData.Class
	end
end

function Ability:GetWeaponProperty(propertyName)
	if RunService:IsServer() then
		return self.Legend.Weapon[propertyName]
	else
		local className = self:GetWeaponClassName()
		if not className then return "Strength" end
		
		local class = self:GetClass(className)
		if not (class and class.PrimaryStatName) then return "Strength" end
		
		return class[propertyName]
	end
end

function Ability:GetPowerHelper(statName)
	return self:GetService("StatService"):GetPower(self:GetLevel(), self:GetStatValue(statName))
end

function Ability:Equip()
	
end

function Ability:Unequip()
	
end

function Ability:GetInfo()

end

return Ability