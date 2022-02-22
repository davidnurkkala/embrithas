local Super = require(script.Parent)
local InventoryService = Super:Extend()

local Configuration = require(game.ReplicatedStorage.Configuration)

function InventoryService:OnCreated()
	self.SwitchCooldownsByPlayer = {}
	
	local function onPlayerAdded(...)
		self:OnPlayerAdded(...)
	end
	game:GetService("Players").PlayerAdded:Connect(onPlayerAdded)
	
	self:ConnectRemote("WeaponEquipped", self.OnWeaponEquipped, true)
	self:ConnectRemote("WeaponDiscarded", self.OnWeaponDiscarded, true)
	self:ConnectRemote("AbilityEquipped", self.OnAbilityEquipped, true)
	self:ConnectRemote("AbilityDiscarded", self.OnAbilityDiscarded, true)
	self:ConnectRemote("TrinketEquipped", self.OnTrinketEquipped, true)
	self:ConnectRemote("TrinketDiscarded", self.OnTrinketDiscarded, true)
	self:ConnectRemote("MaterialDiscarded", self.OnMaterialDiscarded, true)
	self:ConnectRemote("ItemUpgraded", self.OnItemUpgraded, true)
	self:ConnectRemote("ItemSalvaged", self.OnItemSalvaged, true)
	self:ConnectRemote("ItemFavorited", self.OnItemFavorited, true)
	self:ConnectRemote("WeaponOffhanded", self.OnWeaponOffhanded, true)
	self:ConnectRemote("WeaponSwitched", self.OnWeaponSwitched, true)
	self:ConnectRemote("Celebrated", self.OnCelebrated, true)
end

function InventoryService:GetData(player)
	return self:GetService("DataService"):GetPlayerData(player)
end

function InventoryService:GetInventory(player)
	return self:GetData(player).Inventory
end

function InventoryService:GetLegend(player)
	return self:GetClass("Legend").GetLegendFromPlayer(player)
end

function InventoryService:WithLegend(player, callback)
	local legend = self:GetLegend(player)
	if legend then
		callback(legend)
	end
end

function InventoryService:OnPlayerAdded(player)
	self:FireRemote("InventoryUpdated", player, self:GetInventory(player))
end

function InventoryService:UpdateInventory(player)
	self:FireRemote("InventoryUpdated", player, self:GetInventory(player))
end

function InventoryService:AddGold(player, amount)
	local inventory = self:GetInventory(player)
	
	inventory.Gold = inventory.Gold + amount
	self:FireRemote("InventoryUpdated", player, inventory)
end

function InventoryService:RemoveGold(player, amount)
	local inventory = self:GetInventory(player)
	
	if inventory.Gold < amount then
		return false
	end
	
	inventory.Gold = inventory.Gold - amount
	self:FireRemote("InventoryUpdated", player, inventory)

	return true
end

function InventoryService:RemoveMaterial(player, id, amount)
	local inventory = self:GetInventory(player)

	local index, material
	for i, m in pairs(inventory.Materials) do
		if m.Id == id then
			index = i
			material = m
			break
		end
	end

	if not material then
		return false
	end

	if material.Amount < amount then
		return false
	end

	material.Amount -= amount
	if material.Amount == 0 then
		table.remove(inventory.Materials, index)
	end

	self:FireRemote("InventoryUpdated", player, inventory)

	return true
end

function InventoryService:PromptAddItem(player, category, itemData)
	local inventory = self:GetInventory(player)
	local playerData = self:GetService("DataService"):GetPlayerData(player)
	
	local text, image, canSalvage
	if category == "Weapons" then
		local weaponData = self:GetService("WeaponService"):GetWeaponData(itemData)
		
		local name = weaponData.Name
		if weaponData.Modifiers then
			name = table.concat(weaponData.Modifiers, " ").." "..name
		end
		
		text = string.format("Would you like to pick up this %s?", name)
		image = weaponData.Image
		canSalvage = weaponData.UpgradeMaterials ~= nil
	elseif category == "Abilities" then
		local abilityData = self:GetService("AbilityService"):GetAbilityData(itemData.Id, 1)
		text = string.format("Would you like to learn the ability %s?", abilityData.Name)
		image = abilityData.Image
		canSalvage = abilityData.UpgradeMaterials ~= nil
	elseif category == "Trinkets" then
		local trinketData = self:GetService("ItemService"):GetItemData("Trinkets", itemData)
		text = string.format("Would you like to pick up this %s?", trinketData.Name)
		image = trinketData.Image
		canSalvage = trinketData.UpgradeMaterials ~= nil
	elseif category == "Materials" then
		self:AddItem(player, category, itemData)
		return
	end
	
	local promptRemote = self.Storage.Remotes.PromptWeaponPickup
	spawn(function()
		local cancelMessage = "Pass"
		
		local willSalvage = canSalvage and playerData.Options.AutoSalvage
		if willSalvage then
			cancelMessage = "Salvage"
		end
		
		local success, result = pcall(function()
			return promptRemote:InvokeClient(player, text, image, "Pick Up", cancelMessage)
		end) 
		if success and result then
			local index = self:AddItem(player, category, itemData)
		else
			if willSalvage then
				self:TryAutoSalvage(player, category, itemData)
			end
		end
	end)
end

function InventoryService:TryAutoSalvage(player, category, itemData)
	local index = self:AddItem(player, category, itemData, false)
	self:OnItemSalvaged(player, category, index)
end

function InventoryService:AddItem(player, category, itemData, doNotification)
	local inventory = self:GetInventory(player)
	
	if doNotification == nil then
		doNotification = true
	end
	
	local note = {
		Title = "New item!",
	}
	
	local newItemIndex
	if category == "Materials" then
		for index, material in pairs(inventory.Materials) do
			if material.Id == itemData.Id then
				material.Amount = material.Amount + itemData.Amount
				newItemIndex = index
				break
			end
		end
		
		if not newItemIndex then
			table.insert(inventory.Materials, itemData)
			newItemIndex = #inventory.Materials
		end
	else
		table.insert(inventory[category], itemData)
		newItemIndex = #inventory[category]
	end
	
	local ItemData = require(self.Storage.ItemData)
	local baseData = ItemData[category][itemData.Id]
	note.Content = baseData.Name
	
	if category == "Weapons" and itemData.Modifiers then
		note.Content = table.concat(itemData.Modifiers, " ").." "..baseData.Name
	end
	
	note.Image = baseData.Image
	if itemData.Amount then
		note.Content = note.Content.." x"..itemData.Amount
	end
	
	self:FireRemote("InventoryUpdated", player, inventory)
	
	if doNotification then
		self:FireRemote("NotificationRequested", player, note)
	end
	
	return newItemIndex
end

function InventoryService:OnWeaponOffhanded(player, index)
	local inventory = self:GetInventory(player)
	
	if index > #inventory.Weapons then return end
	if index < 1 then return end
	if index == inventory.EquippedWeaponIndex then return end
	
	inventory.OffhandWeaponIndex = index
	self:FireRemote("InventoryUpdated", player, inventory)
end

function InventoryService:OnWeaponSwitched(player)
	if self.SwitchCooldownsByPlayer[player] then return end
	self.SwitchCooldownsByPlayer[player] = true
	delay(0.75, function()
		self.SwitchCooldownsByPlayer[player] = nil
	end)
	
	local inventory = self:GetInventory(player)
	if inventory.OffhandWeaponIndex == 0 then return end
	
	local temp = inventory.EquippedWeaponIndex
	inventory.EquippedWeaponIndex = inventory.OffhandWeaponIndex
	inventory.OffhandWeaponIndex = temp
	
	local temp = inventory.EquippedAbilityIndices
	inventory.EquippedAbilityIndices = inventory.OffhandAbilityIndices
	inventory.OffhandAbilityIndices = temp
	
	self:FireRemote("InventoryUpdated", player, inventory)
	
	self:WithLegend(player, function(legend)
		local offhandCooldownSaves = legend.OffhandCooldownSaves
		
		legend.OffhandCooldownSaves = {
			WeaponLight = legend.Weapon.CooldownLight:Save(),
			WeaponHeavy = legend.Weapon.CooldownHeavy:Save(),
		}
		
		legend:EquipWeapon(inventory.Weapons[inventory.EquippedWeaponIndex])
		
		if offhandCooldownSaves then
			if offhandCooldownSaves.WeaponLight then
				legend.Weapon.CooldownLight:Load(offhandCooldownSaves.WeaponLight)
			end
			if offhandCooldownSaves.WeaponHeavy then
				legend.Weapon.CooldownHeavy:Load(offhandCooldownSaves.WeaponHeavy)
			end
		end
		
		-- save ability cooldowns by id so that we can load them later
		local abilityCooldownsById = {}
		for _, ability in pairs(legend.Abilities) do
			abilityCooldownsById[ability.Data.Id] = ability.Cooldown:Save()
		end
		
		-- save out offhand cooldowns and then load in the old ones
		for slotNumberNumber = 1, 10 do
			local slotNumber = tostring(slotNumberNumber)
			
			local ability = legend.Abilities[slotNumber]
			if ability then
				legend.OffhandCooldownSaves["Ability"..slotNumber] = ability.Cooldown:Save()
			end
			
			legend:EquipAbility(slotNumber, inventory.Abilities[inventory.EquippedAbilityIndices[slotNumber]])
			
			ability = legend.Abilities[slotNumber]
			if ability and offhandCooldownSaves then
				local cooldownSave = offhandCooldownSaves["Ability"..slotNumber]
				if cooldownSave then
					ability.Cooldown:Load(cooldownSave)
				end
			end
		end
		
		-- if we have a hotbar that shares abilities with previous hotbar, load in the cooldowns
		for _, ability in pairs(legend.Abilities) do
			local cooldown = abilityCooldownsById[ability.Data.Id]
			if cooldown then
				ability.Cooldown:Load(cooldown)
			end
		end
	end)
end

function InventoryService:OnWeaponEquipped(player, index)
	local inventory = self:GetInventory(player)
	
	if index > #inventory.Weapons then return end
	if index < 1 then return end
	if index == inventory.OffhandWeaponIndex then return end
	
	inventory.EquippedWeaponIndex = index
	self:FireRemote("InventoryUpdated", player, inventory)
	
	self:WithLegend(player, function(legend)
		legend:EquipWeapon(inventory.Weapons[inventory.EquippedWeaponIndex])
	end)
end

function InventoryService:OnWeaponDiscarded(player, index)
	local inventory = self:GetInventory(player)
	
	if index == inventory.EquippedWeaponIndex then return end
	if index == inventory.OffhandWeaponindex then return end
	
	table.remove(inventory.Weapons, index)
	
	if index < inventory.EquippedWeaponIndex then
		inventory.EquippedWeaponIndex -= 1
	end
	if index < inventory.OffhandWeaponIndex then
		inventory.OffhandWeaponIndex -= 1
	end
	
	self:FireRemote("InventoryUpdated", player, inventory)
end

function InventoryService:OnTrinketEquipped(player, index, slotNumber)
	if typeof(slotNumber) ~= "number" then return end
	if slotNumber ~= slotNumber then return end
	slotNumber = math.floor(slotNumber)
	if slotNumber < 1 then return end
	if slotNumber > 3 then return end
	
	local inventory = self:GetInventory(player)
	
	if table.find(inventory.EquippedTrinketIndices, index) then return end
	if inventory.Trinkets[index] == nil then return end
	
	inventory.EquippedTrinketIndices[slotNumber] = index
	self:FireRemote("InventoryUpdated", player, inventory)
	
	self:WithLegend(player, function(legend)
		legend:EquipTrinket(slotNumber, inventory.Trinkets[inventory.EquippedTrinketIndices[slotNumber]])
	end)
end

function InventoryService:OnTrinketDiscarded(player, index)
	local inventory = self:GetInventory(player)

	if table.find(inventory.EquippedTrinketIndices, index) then return end
	table.remove(inventory.Trinkets, index)

	for slotNumber, equippedIndex in pairs(inventory.EquippedTrinketIndices) do
		if index < equippedIndex then
			inventory.EquippedTrinketIndices[slotNumber] = equippedIndex - 1
		end
	end

	self:FireRemote("InventoryUpdated", player, inventory)
end

function InventoryService:OnAbilityEquipped(player, index, slotNumber)
	if typeof(slotNumber) ~= "number" then return end
	if slotNumber ~= slotNumber then return end
	slotNumber = math.floor(slotNumber)
	if slotNumber < 1 then return end
	if slotNumber > 10 then return end
	
	slotNumber = tostring(slotNumber)
	
	local inventory = self:GetInventory(player)
	
	if index == inventory.EquippedAbilityIndices[slotNumber] then return end
	if index < 1 then return end
	
	local abilitySlotData = inventory.Abilities[index]
	if not abilitySlotData then return end
	
	local cooldownRemaining = nil
	
	-- ensure this ability is unique
	for otherSlotNumber, otherIndex in pairs(inventory.EquippedAbilityIndices) do
		local otherSlotData = inventory.Abilities[otherIndex]
		if otherSlotData and otherSlotData.Id == abilitySlotData.Id then
			inventory.EquippedAbilityIndices[otherSlotNumber] = nil
			
			self:WithLegend(player, function(legend)
				local ability = legend.Abilities[otherSlotNumber]
				if ability then
					cooldownRemaining = ability.Cooldown:GetRemaining()
				end
				legend:EquipAbility(otherSlotNumber, nil)
			end)
		end
	end
	
	inventory.EquippedAbilityIndices[slotNumber] = index
	
	self:FireRemote("InventoryUpdated", player, inventory)
	
	self:WithLegend(player, function(legend)
		legend:EquipAbility(slotNumber, inventory.Abilities[inventory.EquippedAbilityIndices[slotNumber]])
		
		if cooldownRemaining then
			local ability = legend.Abilities[slotNumber]
			if ability then
				ability.Cooldown:Use(cooldownRemaining)
			end
		end
	end)
end

function InventoryService:OnAbilityDiscarded(player, index)
	local inventory = self:GetInventory(player)
	
	if table.find(inventory.EquippedAbilityIndices, index) then return end
	if table.find(inventory.OffhandAbilityIndices, index) then return end
	
	table.remove(inventory.Abilities, index)
	
	for slotNumber, equippedIndex in pairs(inventory.EquippedAbilityIndices) do
		if index < equippedIndex then
			inventory.EquippedAbilityIndices[slotNumber] = equippedIndex - 1
		end
	end
	
	for slotNumber, equippedIndex in pairs(inventory.OffhandAbilityIndices) do
		if index < equippedIndex then
			inventory.OffhandAbilityIndices[slotNumber] = equippedIndex - 1
		end
	end
	
	self:FireRemote("InventoryUpdated", player, inventory)
end

function InventoryService:OnMaterialDiscarded(player, index, amount)
	if typeof(amount) ~= "number" then return end
	
	-- detect NaN
	if amount ~= amount then return end
	
	if amount < 1 then return end
	amount = math.floor(amount)
	
	local inventory = self:GetInventory(player)
	
	local slotData = inventory.Materials[index]
	if not slotData then return end
	
	slotData.Amount = slotData.Amount - amount
	if slotData.Amount <= 0 then
		table.remove(inventory.Materials, index)
	end
	
	self:FireRemote("InventoryUpdated", player, inventory)
end

function InventoryService:OnItemUpgraded(player, categoryName, index)
	local inventory = self:GetInventory(player)
	
	local category = inventory[categoryName]
	if not category then return end
	
	local slotData = category[index]
	if not slotData then return end
	
	-- acquire item data
	local itemData = {}
	local rawData
	if categoryName == "Weapons" then
		rawData = self:GetService("WeaponService"):GetWeaponData(slotData)
	elseif categoryName == "Abilities" then
		rawData = self:GetService("AbilityService"):GetAbilityData(slotData.Id, self:GetService("DataService"):GetPlayerLevel(player))
	elseif categoryName == "Trinkets" then
		rawData = self:GetService("ItemService"):GetItemData("Trinkets", slotData)
	end
	for key, val in pairs(rawData) do
		itemData[key] = val
	end
	for key, val in pairs(slotData) do
		itemData[key] = val
	end
	
	-- check if we're surpassing max upgrades
	local upgrades = slotData.Upgrades or 0
	local maxUpgrades = itemData.MaxUpgrades or Configuration.MaxUpgrades
	if upgrades >= maxUpgrades then return end
	
	if not itemData.UpgradeMaterials then return end
	
	-- acquire upgrade data
	local upgradeData = self:GetService("WeaponService"):GetUpgradeData(itemData, inventory)
	local amountByMaterialId = {}
	for _, req in pairs(upgradeData) do
		if req.Held < req.Amount then
			return
		end
		amountByMaterialId[req.Material.Id] = req.Amount
	end
	
	-- if we made it this far, we have enough, TAKE THEM
	for materialId, amount in pairs(amountByMaterialId) do
		for index, slotData in pairs(inventory.Materials) do
			if slotData.Id == materialId then
				slotData.Amount = slotData.Amount - amount
				if slotData.Amount == 0 then
					table.remove(inventory.Materials, index)
				end
				break
			end
		end
	end
	
	slotData.Upgrades = (slotData.Upgrades or 0) + 1
	
	self:FireRemote("InventoryUpdated", player, inventory)
	
	self:WithLegend(player, function(legend)
		if categoryName == "Weapons" and index == inventory.EquippedWeaponIndex then
			legend:EquipWeapon(slotData)
		elseif categoryName == "Abilities" then
			local slotNumber = table.find(inventory.EquippedAbilityIndices, index)
			if slotNumber then
				legend:EquipAbility(slotNumber, slotData)
			end
		elseif categoryName == "Trinkets" then
			local slotNumber = table.find(inventory.EquippedTrinketIndices, index)
			if slotNumber then
				legend:EquipTrinket(slotNumber, slotData)
			end
		end
	end)
end

function InventoryService:OnCelebrated(player)
	self:WithLegend(player, function(legend)
		legend:DoCelebration()
	end)
end

InventoryService.SalvageCooldown = {}
function InventoryService:OnItemSalvaged(player, categoryName, index)
	if self.SalvageCooldown[player] then return end
	self.SalvageCooldown[player] = true
	delay(1, function() self.SalvageCooldown[player] = false end)
	
	local inventory = self:GetInventory(player)
	
	local category = inventory[categoryName]
	if not category then return end
	
	local slotData = category[index]
	if not slotData then return end
	
	-- acquire item data
	local itemData = {}
	local rawData
	if categoryName == "Weapons" then
		rawData = self:GetService("WeaponService"):GetWeaponData(slotData)
	elseif categoryName == "Abilities" then
		rawData = self:GetService("AbilityService"):GetAbilityData(slotData.Id, slotData.Level)
	elseif categoryName == "Trinkets" then
		rawData = self:GetService("ItemService"):GetItemData("Trinkets", slotData)
	end
	for key, val in pairs(rawData) do
		itemData[key] = val
	end
	for key, val in pairs(slotData) do
		itemData[key] = val
	end
	
	if not itemData.UpgradeMaterials then return end
	if itemData.SalvageDisabled then return end
	
	local salvageData = self:GetService("WeaponService"):GetSalvageData(itemData)
	for _, salvage in pairs(salvageData) do
		self:AddItem(player, "Materials", {Id = salvage.Material.Id, Amount = salvage.Amount})
	end
	
	if categoryName == "Weapons" then
		self:OnWeaponDiscarded(player, index)
	elseif categoryName == "Abilities" then
		self:OnAbilityDiscarded(player, index)
	elseif categoryName == "Trinkets" then
		self:OnTrinketDiscarded(player, index)
	end
end

function InventoryService:OnItemFavorited(player, categoryName, index)
	local inventory = self:GetInventory(player)
	
	local category = inventory[categoryName]
	if not category then return end
	
	local slotData = category[index]
	if not slotData then return end
	
	if slotData.Favorited then
		slotData.Favorited = nil
	else
		slotData.Favorited = true
	end
	
	self:FireRemote("InventoryUpdated", player, inventory)
end

local Singleton = InventoryService:Create()
return Singleton