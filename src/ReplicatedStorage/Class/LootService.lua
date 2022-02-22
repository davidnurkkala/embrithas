local Super = require(script.Parent)
local LootService = Super:Extend()

local ModifierData = require(Super.Storage.ModifierData)

LootService.WeightScalar = 100000
LootService.NoneChance = 0.25

function LootService:OnCreated()
	if self:IsServer() then
		self.Storage.Remotes.ReforgeWeapon.OnServerInvoke = function(...)
			return self:ReforgeWeapon(...)
		end
		
		self.Storage.Remotes.GetModifierWeightTable.OnServerInvoke = function(player, slotData)
			local weaponData = self:GetService("WeaponService"):GetWeaponData(slotData)
			return self:GetModifierWeightTable(weaponData)
		end
	end
end

function LootService:IsWeaponIncluded(weaponData, inclusions)
	local weaponClass = self:GetClass(weaponData.Class)
	for _, inclusion in pairs(inclusions) do
		local inclusionClass = self:GetClass("Weapon"..inclusion)
		if weaponClass:IsA(inclusionClass) then
			return true
		end
	end
	return false
end

function LootService:GetModifierWeightTable(weaponData)
	local possibleModifiers = {}
	
	-- check type exclusions and inclusions
	for _, modifier in pairs(ModifierData) do
		local passes = false
		
		if modifier.TypeInclusions then
			if self:IsWeaponIncluded(weaponData, modifier.TypeInclusions) then
				passes = true
			end
			
		elseif modifier.TypeExclusions then
			if not self:IsWeaponIncluded(weaponData, modifier.TypeExclusions) then
				passes = true
			end
			
		else
			passes = true
		end
		
		if modifier.IdExclusions then
			if table.find(modifier.IdExclusions, weaponData.Id) then
				passes = false
			end
		end
		
		if modifier.IdInclusions then
			if table.find(modifier.IdInclusions, weaponData.Id) then
				passes = true
			end
		end
		
		if passes then
			table.insert(possibleModifiers, modifier)
		end
	end
	
	local weightTable = {}
	
	local subtotal = 0
	for _, modifier in pairs(possibleModifiers) do
		local weight = math.floor(self.WeightScalar / modifier.Rarity)
		weightTable[modifier.Name] = weight
		subtotal += weight
	end
	
	weightTable.None = subtotal * self.NoneChance / (1 - self.NoneChance)
	
	return weightTable
end

function LootService:GenerateWeapon(slotDataIn)
	local slotData = {}
	for key, val in pairs(slotDataIn) do
		slotData[key] = val
	end
	
	assert(slotData.Id)
	local weaponData = self:GetService("WeaponService"):GetWeaponData(slotData)
	local weightTable = self:GetModifierWeightTable(weaponData)
	
	local modifier = self:GetWeightedResult(weightTable)
	if modifier == "None" then
		slotData.Modifiers = nil
	else
		slotData.Modifiers = {modifier}
	end
	
	return slotData
end

function LootService:GetReforgeCost(slotData)
	if not slotData then return 0 end
	
	local reforges = slotData.Reforges or 0
	
	return math.min(2000, 100 + math.floor(25 * reforges ^ 1.25))
end

-- Firespell9812 was here 7/6/2021
function LootService:ReforgeWeapon(player, index)
	local inventoryService = self:GetService("InventoryService")
	local inventory = inventoryService:GetInventory(player)
	local weapons = inventory.Weapons
	
	local slotData = weapons[index]
	if not slotData then
		return false, inventory
	end
	
	local reforgeCost = self:GetReforgeCost(slotData)
	if inventory.Gold < reforgeCost then
		return false, inventory
	end
	
	inventoryService:RemoveGold(player, reforgeCost)
	slotData = self:GenerateWeapon(slotData)
	slotData.Reforges = (slotData.Reforges or 0) + 1
	weapons[index] = slotData
	
	local itemData = self:GetService("ItemService"):GetItemData("Weapons", slotData)
	self:FireRemote("NotificationRequested", player, {
		Title = "Reforge complete!",
		Content = "New modifiers: "..((slotData.Modifiers == nil) and ("None") or (table.concat(slotData.Modifiers, " ")))..".",
		Image = itemData.Image,
	})
	
	if index == inventory.EquippedWeaponIndex then
		local legend = self:GetClass("Legend").GetLegendFromPlayer(player)
		if legend then
			legend:EquipWeapon(weapons[index])
		end
	end
	
	inventoryService:UpdateInventory(player)
	return true, inventory
end

local Singleton = LootService:Create()
return Singleton