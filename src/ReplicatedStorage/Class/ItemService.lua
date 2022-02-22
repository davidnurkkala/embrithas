local Super = require(script.Parent)
local ItemService = Super:Extend()

local ItemData = require(game.ReplicatedStorage.ItemData)

function ItemService:GetItemData(category, slotData)
	local itemData
	if category == "Weapons" then
		itemData = self:GetService("WeaponService"):GetWeaponData(slotData)
	elseif category == "Abilities" then
		itemData = self:GetService("AbilityService"):GetAbilityData(slotData.Id, slotData.Level)
	elseif category == "Materials" then
		itemData = self:GetService("MaterialService"):GetMaterialData(slotData.Id)
	elseif category == "Trinkets" then
		itemData = {}
		for key, val in pairs(ItemData.Trinkets[slotData.Id]) do
			itemData[key] = val
		end
		for key, val in pairs(slotData) do
			itemData[key] = val
		end
	end
	return itemData
end

function ItemService:GetItemName(category, slotData)
	return self:GetItemNameByItemData(self:GetItemData(category, slotData))
end

function ItemService:GetItemNameByItemData(itemData)
	local name = itemData.Name
	
	if itemData.Modifiers then
		name = table.concat(itemData.Modifiers, " ").." "..name
	end
	if itemData.Upgrades then
		name ..= " +"..itemData.Upgrades
	end
	
	return name
end

local Singleton = ItemService:Create()
return Singleton