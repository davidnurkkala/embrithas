local Configuration = require(game:GetService("ReplicatedStorage"):WaitForChild("Configuration"))

local Super = require(script.Parent)
local WeaponService = Super:Extend()

WeaponService.WeaponData = require(Super.Storage.ItemData).Weapons

WeaponService.GenericWeaponIds = {2, 3, 4, 5, 6, 9, 12}
WeaponService.UpgradeMultiplier = 20

function WeaponService:GetWeaponData(slotData)
	local id = slotData.Id
	
	assert(id)
	
	local data = {}
	for key, val in pairs(slotData) do
		data[key] = val
	end
	
	for key, val in pairs(self.WeaponData[id]) do
		data[key] = val
	end
	
	return data
end

function WeaponService:GetUpgrades(itemData)
	return (itemData.Upgrades or 0) + 1
end

function WeaponService:GetUpgradeData(itemData, inventory)
	local upgradeData = {}
	for internalName, amountPerLevel in pairs(itemData.UpgradeMaterials) do
		local materialData = self:GetService("MaterialService"):GetMaterialDataByInternalName(internalName)
		local amount = 0
		for upgrades = 1, self:GetUpgrades(itemData) do
			amount += math.floor(upgrades * self.UpgradeMultiplier * amountPerLevel)
		end
		amount = math.max(1, amount)
		
		local held = 0
		for _, material in pairs(inventory.Materials) do
			if material.Id == materialData.Id then
				held = material.Amount
				break
			end
		end
		
		table.insert(upgradeData, {Material = materialData, Amount = amount, Held = held})
	end
	return upgradeData
end

function WeaponService:GetSalvageData(itemData)
	local function getTotalCostUpgrade(amountPerLevel, upgrade)
		local total = 0
		for upgrades = 1, upgrade do
			total += math.max(1, math.floor(upgrades * self.UpgradeMultiplier * amountPerLevel))
		end
		return total
	end
	
	local salvageData = {}
	for internalName, amountPerLevel in pairs(itemData.UpgradeMaterials) do
		local materialData = self:GetService("MaterialService"):GetMaterialDataByInternalName(internalName)
		local amount = getTotalCostUpgrade(amountPerLevel, self:GetUpgrades(itemData) - 1) + 1
		table.insert(salvageData, {Material = materialData, Amount = amount})
	end
	
	return salvageData
end

local Singleton = WeaponService:Create()
return Singleton