local Super = require(script.Parent)
local DataService = Super:Extend()

local DSS = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Configuration = require(Super.Storage.Configuration)
local Players = game:GetService("Players")

local FactionData = require(Super.Storage.FactionData)
local LoreData = require(game:GetService("ServerStorage").LoreData)

DataService.Version = Configuration.DataStoreVersion
DataService.PurchasesVersion = Configuration.PurchasesDataStoreVersion
DataService.LeaderboardVersion = Configuration.LeaderboardVersion

DataService.Flags = {
	AbilityResetJune1 = 1,
	MissionLogJune23 = 2,
	GoldJuly2 = 3,
	AlignmentJuly2 = 4,
	LoreJuly21 = 5,
	BalanceFixJuly27 = 6,
	CraftingLevelJuly31 = 7,
	MaxLevelAugust10 = 8,
	MultipleAbilitiesAugust18 = 9,
	NoAbilityCopiesAugust28 = 10,
	FirstTimeRewardsAugust31 = 11,
	DoorkickAnimationsSeptember1 = 12,
	UnlockSecondAbilitySeptember4 = 13,
	LanternSeptember7 = 14,
	LanternSeptember15 = 15,
	EffectsSeptember22 = 16,
	QuickSwitchSeptember29 = 17,
	KillEffectsOctober11 = 18,
	PlayerLevelsOctober22 = 19,
	TrinketsNovember2 = 20,
	ProgressionRevampNovember6 = 21,
	CelebrationsNovember17 = 22,
	AbilityIndicesJanuary27 = 24,
	SwitchHotbarFebruary1 = 26,
	StatsMarch1 = 27,
	TalentsApril12 = 29,
	EmbrithasTransfer = 30,
	RefundStatsJune19 = 31,
	QuestsJune24 = 32,
	HasDoneIntroQuest = 33,
	NoDuplicateWeaponsJune29 = 34,
	FuckOffCheeseJuly5 = 35,
}

function DataService:OnCreated()
	self.PlayerDataStore = DSS:GetDataStore("PlayerData", self.Version)
	self.PlayerPurchasesDataStore = DSS:GetDataStore("PlayerPurchases", self.PurchasesVersion)
	self.PlayerDataCache = {}
	self.PlayerPurchasesCache = {}
	self.LeaderboardCache = {}
	self.DeletingPlayers = {}
	
	Players.PlayerAdded:Connect(function(player)
		local key = self:GetKeyFromPlayer(player)
		self.PlayerDataCache[key] = nil
		self.PlayerPurchasesCache[key] = nil
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		self:OnPlayerRemoving(player)
	end)
	
	spawn(function()
		local lastAutoSave = tick()
		while true do
			wait(30)
			self:Autosave()
			
			local since = tick() - lastAutoSave
			lastAutoSave = tick()
		end
	end)
	
	self.Storage.Remotes.GetPlayerLevel.OnServerInvoke = function(player)
		return self:GetPlayerLevel(player)
	end
	
	self.Storage.Remotes.GetMissionLog.OnServerInvoke = function(player)
		return self:GetPlayerData(player).MissionLog
	end
	
	self.Storage.Remotes.GetPlayerAlignment.OnServerInvoke = function(player)
		return self:GetPlayerData(player).Alignment
	end
	
	self.Storage.Remotes.GetPlayerCosmetics.OnServerInvoke = function(player)
		return self:GetPlayerCosmetics(player)
	end
	
	self.Storage.Remotes.GetPlayerQuests.OnServerInvoke = function(player)
		return self:GetPlayerData(player).Quests
	end
	
	self.Storage.Remotes.GetPlayerLore.OnServerInvoke = function(player)
		local unlockedIds = self:GetPlayerData(player).Lore
		local unlockedEntries = {}
		for id, entry in pairs(LoreData) do
			if table.find(unlockedIds, id) then
				table.insert(unlockedEntries, entry)
			end
		end
		return unlockedEntries
	end
	
	self.Storage.Remotes.GetMissionLeaderboard.OnServerInvoke = function(player, missionId, difficulty)
		return self:GetMissionLeaderboard(missionId, difficulty)
	end
	
	self:ConnectRemote("SaveFileDeleted", self.OnSaveFileDeleted, true)
	
	game:BindToClose(function()
		print("Saving all data...")
		self:SaveOnClose()
	end)
end

function DataService:OnSaveFileDeleted(player)
	local key = self:GetKeyFromPlayer(player)
	self.PlayerDataCache[key] = nil
	self.DeletingPlayers[player] = true
	player:Kick("Your data has been completely reset.")
	self.PlayerDataStore:RemoveAsync(key)
end

function DataService:GetTotalMissionCompletions(player, missionId)
	local data = self:GetPlayerData(player)
	if not data then return end
	if not data.MissionLog then return end
	
	local count = 0
	for _, entry in pairs(data.MissionLog) do
		if (entry.MissionId == missionId) and (entry.Difficulty ~= "Recruit") then
			count += entry.VictoryCount or 0
		end
	end
	
	return count
end

function DataService:GetMissionLeaderboard(missionId, difficulty)
	local key = missionId..difficulty
	
	if self.LeaderboardCache[key] and (tick() < self.LeaderboardCache[key].ExpirationTime) then
		return self.LeaderboardCache[key].Page
	end
	
	local mission = require(self.Storage.Missions[missionId])
	local store = DSS:GetOrderedDataStore(missionId..difficulty, self.LeaderboardVersion)
	
	local page
	if mission.RankingType == "MostFloors" then
		local pages = store:GetSortedAsync(false, 50)
		page = pages:GetCurrentPage()
	else
		local pages = store:GetSortedAsync(true, 50)
		page = pages:GetCurrentPage()
	end
	
	local expirationTime = tick() + (60 * 5)
	self.LeaderboardCache[key] = {
		Page = page,
		ExpirationTime = expirationTime,
	}
	
	return page
end

function DataService:OnPlayerRemoving(player)
	if self.DeletingPlayers[player] then
		-- don't save their data
		self.DeletingPlayers[player] = nil
	else
		self:SaveAllPlayerDataAsync(player)
	end
	
	local key = self:GetKeyFromPlayer(player)
	self.PlayerDataCache[key] = nil
	self.PlayerPurchasesCache[key] = nil
end

function DataService:GetKeyFromPlayer(player)
	return player.UserId
end

function DataService:GetNewPlayerData()
	return {
		Inventory = {
			EquippedWeaponIndex = 1,
			EquippedAbilityIndex = 0,
			Weapons = {
				{Id = 1, Level = 1},
			},
			Abilities = {
				["1"] = {Class = "CombatRoll", Level = 1}
			},
			Materials = {},
		}
	}
end

function DataService:GetNewPlayerPurchases()
	return {
		Products = {},
	}
end

function DataService:GetPlayerCosmetics(player)
	return {
		Equipped = self:GetPlayerData(player).Cosmetics,
		Purchased = self:GetPlayerPurchases(player).Products,
		IsUnlimited = MarketplaceService:UserOwnsGamePassAsync(player.UserId, 11776128),
	}
end

function DataService:HasFlag(data, flag)
	if not data.Flags then
		return false
	end
	
	return table.find(data.Flags, flag) ~= nil
end

function DataService:RemoveFlag(data, flag)
	warn(
		"\n"..string.rep("*", 32)..
		"\nREMOVING FLAG? REMOVE THIS BEFORE PUBLISHING.\n"..
		string.rep("*", 32).."\n"
	)
	
	if not data.Flags then return end
	
	table.remove(data.Flags, table.find(data.Flags, flag))
end

function DataService:AddFlag(data, flag)
	if not data.Flags then
		data.Flags = {}
	end
	
	table.insert(data.Flags, flag)
end

function DataService:CheckFlag(data, flag, func, testing)
	if testing == nil then
		testing = false
	end
	
	if not self:HasFlag(data, flag) then
		if not testing then
			self:AddFlag(data, flag)
		end
		
		func()
	end
end

function DataService:CheckFlags(player, data)
	self:CheckFlag(data, self.Flags.AbilityResetJune1, function()
		data.Inventory.Abilities = {
			{Id = 1, Level = 1},
		}
		data.Inventory.EquippedAbilityIndex = 1
	end)
	
	self:CheckFlag(data, self.Flags.MissionLogJune23, function()
		data.MissionLog = {}
	end)
	
	self:CheckFlag(data, self.Flags.GoldJuly2, function()
		data.Inventory.Gold = 0
	end)
	
	self:CheckFlag(data, self.Flags.AlignmentJuly2, function()
		data.Alignment = {
			Order = 0,
			College = 0,
			League = 0,
		}
	end)
	
	self:CheckFlag(data, self.Flags.LoreJuly21, function()
		data.Lore = {"worldHistoryAbridged"}
	end)
	
	self:CheckFlag(data, self.Flags.BalanceFixJuly27, function()
		for _, weapon in pairs(data.Inventory.Weapons) do
			weapon.Level = math.min(weapon.Level, 30)
		end
		for _, material in pairs(data.Inventory.Materials) do
			material.Amount = math.min(material.Amount, 50)
		end
	end)
	
	self:CheckFlag(data, self.Flags.CraftingLevelJuly31, function()
		local ids = {22, 18, 20}
		for _, weapon in pairs(data.Inventory.Weapons) do
			if table.find(ids, weapon.Id) then
				weapon.Level = weapon.Level + 25
			end
		end
	end)
	
	self:CheckFlag(data, self.Flags.MaxLevelAugust10, function()
		local ItemData = require(self.Storage.ItemData)
		local MaterialService = self:GetService("MaterialService")
		local InventoryService = self:GetService("InventoryService")
		
		local function getTotalCostAtLevel(id, level)
			local data = ItemData.Weapons[id]
			local amountByName = {}
			for name, costPerLevel in pairs(data.UpgradeMaterials) do
				amountByName[name] = 0
				for l = 1, level do
					amountByName[name] = amountByName[name] + math.max(1, math.floor(l * costPerLevel))
				end
			end
			local amountById = {}
			for name, amount in pairs(amountByName) do
				amountById[MaterialService:GetMaterialDataByInternalName(name).Id] = amount
			end
			return amountById
		end
		
		for _, weapon in pairs(data.Inventory.Weapons) do
			if weapon.Level > 75 then
				local itemData = ItemData.Weapons[weapon.Id]
				if itemData.UpgradeMaterials then
					local maxCost = getTotalCostAtLevel(weapon.Id, 75)
					local currentCost = getTotalCostAtLevel(weapon.Id, weapon.Level)
					
					for id, _ in pairs(maxCost) do
						local c = currentCost[id]
						local m = maxCost[id]
						local d = c - m
						
						local addMaterial = true
						for _, material in pairs(data.Inventory.Materials) do
							if material.Id == id then
								addMaterial = false
								material.Amount = material.Amount + d
								break
							end
						end
						if addMaterial then
							table.insert(data.Inventory.Materials, {Id = id, Amount = d})
						end
					end
				end
				
				weapon.Level = 75
			end
		end
		
		for _, material in pairs(data.Inventory.Materials) do
			if material.Id == 1 then
				material.Amount = math.min(10, material.Amount)
			end
		end
	end)
	
	self:CheckFlag(data, self.Flags.MultipleAbilitiesAugust18, function()
		local inventory = data.Inventory
		
		local equippedAbilityIndex = inventory.EquippedAbilityIndex
		inventory.EquippedAbilityIndex = nil
		
		inventory.EquippedAbilityIndices = {}
		
		if equippedAbilityIndex ~= 0 then
			inventory.EquippedAbilityIndices[1] = equippedAbilityIndex
		end
	end)
	
	self:CheckFlag(data, self.Flags.NoAbilityCopiesAugust28, function()
		data.Inventory.EquippedAbilityIndices[2] = nil
	end)
	
	self:CheckFlag(data, self.Flags.DoorkickAnimationsSeptember1, function()
		data.Cosmetics = {
			DoorkickAnimation = 1,
		}
	end)
	
	self:CheckFlag(data, self.Flags.UnlockSecondAbilitySeptember4, function()
		data.Inventory.EquippedAbilityIndices[2] = nil
		data.Quests = {}
	end)
	
	self:CheckFlag(data, self.Flags.LanternSeptember7, function()
		data.Cosmetics.Lantern = 1
	end)
	
	self:CheckFlag(data, self.Flags.LanternSeptember15, function()
		data.Cosmetics.Lantern = 1
	end)
	
	self:CheckFlag(data, self.Flags.EffectsSeptember22, function()
		data.Cosmetics.DoorEffect = 1
		data.Cosmetics.HitEffect = 1
	end)
	
	self:CheckFlag(data, self.Flags.QuickSwitchSeptember29, function()
		data.Inventory.OffhandWeaponIndex = 0
	end)
	
	self:CheckFlag(data, self.Flags.KillEffectsOctober11, function()
		data.Cosmetics.KillEffect = 1
	end)
	
	self:CheckFlag(data, self.Flags.PlayerLevelsOctober22, function()
		data.Level = 1
		data.Experience = 0
	end)
	
	self:CheckFlag(data, self.Flags.TrinketsNovember2, function()
		data.Inventory.Trinkets = {}
		data.Inventory.EquippedTrinketIndices = {} 
	end)
	
	self:CheckFlag(data, self.Flags.ProgressionRevampNovember6, function()
		local highestLevel = 0
		for _, weapon in pairs(data.Inventory.Weapons) do
			local level = weapon.Level
			if level then
				weapon.Level = nil
				
				highestLevel = math.max(highestLevel, level)
				
				local itemData = self:GetService("ItemService"):GetItemData("Weapons", weapon)
				
				local upgrades = math.floor(level / 10)
				if (upgrades > 0) and (itemData.UpgradeMaterials) then
					weapon.Upgrades = upgrades
				end
			end
		end
		
		for _, ability in pairs(data.Inventory.Abilities) do
			local level = ability.Level
			if level then
				ability.Level = nil
				
				local itemData = self:GetService("ItemService"):GetItemData("Abilities", ability)
				local maxUpgrades = itemData.MaxUpgrades or Configuration.MaxUpgrades
				
				local upgrades = math.floor(level / 100 * maxUpgrades)
				if (upgrades > 0) and (itemData.UpgradeMaterials) then
					ability.Upgrades = upgrades
				end
			end
		end
		
		local level = math.ceil(highestLevel / 2)
		data.Level = level
	end)
	
	self:CheckFlag(data, self.Flags.CelebrationsNovember17, function()
		data.Cosmetics.CelebrationAnimation = 1
		data.Cosmetics.CelebrationEmote = 1
	end)
	
	self:CheckFlag(data, self.Flags.AbilityIndicesJanuary27, function()
		local equippedAbilityIndices = {}
		
		for slotNumber, index in pairs(data.Inventory.EquippedAbilityIndices) do
			equippedAbilityIndices[tostring(slotNumber)] = index
		end
		
		data.Inventory.EquippedAbilityIndices = equippedAbilityIndices
	end)
	
	self:CheckFlag(data, self.Flags.SwitchHotbarFebruary1, function()
		data.Inventory.OffhandAbilityIndices = {}
	end)
	
	self:CheckFlag(data, self.Flags.StatsMarch1, function()
		data.Stats = {
			Strength = 0,
			Agility = 0,
			Constitution = 0,
			Perseverance = 0,
			Dominance = 0,
			Compassion = 0,
		}
	end)
	
	self:CheckFlag(data, self.Flags.TalentsApril12, function()
		data.EquippedTalents = {}
		data.UnlockedTalents = {}
	end)
	
	if data.IsNewData then
		self:AddFlag(data, self.Flags.EmbrithasTransfer)
	else
		if not self:HasFlag(data, self.Flags.EmbrithasTransfer) then
			local info = {}
			
			local ItemData = require(self.Storage.ItemData)
			
			-- weapons
			local rares = {}
			local mythics = {}
			
			for _, slotData in pairs(data.Inventory.Weapons) do
				local id = slotData.Id
				local data = ItemData.Weapons[id]
				if (data.Rarity == "Rare") and (table.find(rares, id) == nil) then
					table.insert(rares, id)
					
				elseif (data.Rarity == "Mythic") and (table.find(mythics, id) == nil) then
					table.insert(mythics, id)
				end
			end
			
			info.BattleaxeUnlocked = #rares >= 7
			info.SwordUnlocked = #mythics >= 7
			
			-- gold
			info.GoldTier1Unlocked = data.Inventory.Gold >= 10000
			info.GoldTier2Unlocked = data.Inventory.Gold >= 100000
			info.GoldTier3Unlocked = data.Inventory.Gold >= 1000000
			
			-- level
			info.LevelUnlocked = data.Level >= 100
			
			-- mission log
			local raidsCleared = 0
			local raidIds = {"worstCaseScenario", "theYawningAbyss", "siegeOfFyreth"}
			
			for _, entry in pairs(data.MissionLog) do
				if table.find(raidIds, entry.MissionId) then
					raidsCleared += 1
				end
			end
			
			info.MapUnlocked = raidsCleared >= 1
			info.TelescopeUnlocked = raidsCleared >= 3
			
			spawn(function()
				local newPlayerData = self:GetNewPlayerData()
				local categoriesDeleted = self.Storage.Remotes.PromptTransfer:InvokeClient(player, info)
				
				data.Alignment = {
					Order = 0,
					College = 0,
					League = 0,
				}
				
				if categoriesDeleted.Items then
					-- save event items
					local savedItems = {}
					local eventItemIds = {15, 16, 17, 35, 60}
					for _, slotData in pairs(data.Inventory.Weapons) do
						if table.find(eventItemIds, slotData.Id) then
							table.insert(savedItems, slotData)
						end
					end
					
					-- nuke it
					data.Inventory = {
						Weapons = {
							{Id = 1},
						},
						EquippedWeaponIndex = 1,
						OffhandWeaponIndex = 0,
						
						Abilities = {
							{Id = 1},
						},
						EquippedAbilityIndices = {
							["1"] = 1,
						},
						OffhandAbilityIndices = {},
						
						Trinkets = {},
						EquippedTrinketIndices = {},
						
						Materials = {},
						
						Gold = data.Inventory.Gold,
					}
					
					-- actually equip new equipment
					local legend = self:GetClass("Legend").GetLegendFromPlayer(player)
					legend:EquipWeapon(data.Inventory.Weapons[data.Inventory.EquippedWeaponIndex])
					for slotNumber = 1, 10 do
						legend:EquipAbilityByObject(tostring(slotNumber), nil)
					end
					legend:EquipAbility("1", data.Inventory.Abilities[data.Inventory.EquippedAbilityIndices["1"]])
					for slotNumber = 1, 3 do
						legend:EquipTrinketByObject(slotNumber, nil)
					end
					self:FireRemote("InventoryUpdated", player, data.Inventory)
					
					-- restore event items
					for _, savedItem in pairs(savedItems) do
						table.insert(data.Inventory.Weapons, savedItem)
					end
					
					-- add in poggers championship rewards
					if info.BattleaxeUnlocked then
						table.insert(data.Inventory.Weapons, {Id = 62})
					end
					if info.SwordUnlocked then
						table.insert(data.Inventory.Weapons, {Id = 63})
					end
				end
				
				local products = self:GetPlayerPurchases(player).Products
				
				if categoriesDeleted.Gold then
					data.Inventory.Gold = 0
					
					if info.GoldTier1Unlocked then
						table.insert(products, -1)
					end
					if info.GoldTier2Unlocked then
						table.insert(products, -2)
					end
					if info.GoldTier3Unlocked then
						table.insert(products, -3)
					end
				end
				
				if categoriesDeleted.Level then
					data.Level = 1
					data.Experience = 0
					
					if info.LevelUnlocked then
						table.insert(products, -4)
					end
				end
				
				if categoriesDeleted.Mission then
					data.MissionLog = {}
					
					if info.MapUnlocked then
						table.insert(products, -5)
					end
					if info.TelescopeUnlocked then
						table.insert(data.Inventory.Weapons, {Id = 64})
					end
				end
				
				self:GetService("StatService"):ResetStats(player)
				
				self:AddFlag(data, self.Flags.EmbrithasTransfer)
				
				self:SavePlayerPurchasesAsync(player)
				
				delay(2.5, function()
					player:Kick("Your save file has been successfully migrated. Please rejoin!")
				end)
			end)
		end
	end
	
	self:CheckFlag(data, self.Flags.RefundStatsJune19, function()
		spawn(function()
			self:GetService("StatService"):ResetStats(player)
		end)
	end)
	
	self:CheckFlag(data, self.Flags.QuestsJune24, function()
		data.QuestLogData = {
			Quests = {},
		}
	end)
	
	self:CheckFlag(data, self.Flags.NoDuplicateWeaponsJune29, function()
		data.Inventory.OffhandWeaponIndex = 0
	end)
	
	self:CheckFlag(data, self.Flags.FuckOffCheeseJuly5, function()
		local inventory = data.Inventory
		local weapons = inventory.Weapons
		for index = #weapons, 1, -1 do
			local weapon = weapons[index]
			if weapon.Id == 68 then
				table.remove(weapons, index)
				
				if index == inventory.EquippedWeaponIndex then
					inventory.EquippedWeaponIndex = 1
				elseif index == inventory.OffhandWeaponIndex then
					inventory.OffhandWeaponIndex = 0
				end
			end
		end
		inventory.EquippedWeaponIndex = 1
	end)
	
	-- last minute catches
	data.Inventory.Gold = math.floor(data.Inventory.Gold)
	
	if not data.Inventory.OffhandWeaponIndex then
		data.Inventory.OffhandWeaponIndex = 0
	end
	
	if not data.Inventory.EquippedWeaponIndex then
		data.Inventory.EquippedWeaponIndex = 1
	end
end

function DataService:CleanCache()
	local badKeys = {}
	for userId, data in pairs(self.PlayerDataCache) do
		if game:GetService("Players"):GetPlayerByUserId(userId) == nil then
			table.insert(badKeys, userId)
		end
	end
	for _, badKey in pairs(badKeys) do
		self.PlayerDataCache[badKey] = nil
	end
	
	badKeys = {}
	for userId, data in pairs(self.PlayerPurchasesCache) do
		if game:GetService("Players"):GetPlayerByUserId(userId) == nil then
			table.insert(badKeys, userId)
		end
	end
	for _, badKey in pairs(badKeys) do
		self.PlayerPurchasesCache[badKey] = nil
	end
end

DataService.DataFetchRequests = {}
function DataService:GetPlayerData(player)
	self:CleanCache()
	
	local key = self:GetKeyFromPlayer(player)
	local data
	
	if not self.PlayerDataCache[key] then
		if self.DataFetchRequests[player] then
			self.DataFetchRequests[player]:Connect(function(d)
				data = d
			end)
			repeat wait() until (data ~= nil)
		else
			local fetchRequest = self:CreateNew"Signal"()
			self.DataFetchRequests[player] = fetchRequest
			
			data = self.PlayerDataStore:GetAsync(key)
			
			if data == nil then
				data = self:GetNewPlayerData()
				data.IsNewData = true
			end
			
			-- flag checks may edit purchase data
			self:GetPlayerPurchases(player)

			-- check flags
			self:CheckFlags(player, data)
			
			data.IsNewData = nil
			
			fetchRequest:Fire(data)
			self.DataFetchRequests[player] = nil
		end
	else
		data = self.PlayerDataCache[key]
	end
	
	-- cache results
	self.PlayerDataCache[key] = data
	return data
end

DataService.PurchaseFetchRequests = {}
function DataService:GetPlayerPurchases(player)
	self:CleanCache()
	
	local key = self:GetKeyFromPlayer(player)
	local purchases
	
	if not self.PlayerPurchasesCache[key] then
		if self.PurchaseFetchRequests[player] then
			self.PurchaseFetchRequests[player]:Connect(function(p)
				purchases = p
			end)
			repeat wait() until (purchases ~= nil)
		else
			local fetchRequest = self:CreateNew"Signal"()
			self.PurchaseFetchRequests[player] = fetchRequest
			
			purchases = self.PlayerPurchasesDataStore:GetAsync(key)
			
			if purchases == nil then
				purchases = self:GetNewPlayerPurchases()
			end
			
			fetchRequest:Fire(purchases)
			self.PurchaseFetchRequests[player] = nil
		end
	else
		purchases = self.PlayerPurchasesCache[key]
	end
	
	self.PlayerPurchasesCache[key] = purchases
	return purchases
end

function DataService:SaveOnClose()
	if game:GetService("RunService"):IsStudio() then return end
	
	for key, data in pairs(self.PlayerDataCache) do
		self:Attempt(4, function()
			local success, reason = pcall(function()
				self.PlayerDataStore:SetAsync(key, data)
			end)
			return success
		end)
	end
	for key, purchases in pairs(self.PlayerPurchasesCache) do
		self:Attempt(4, function()
			local success, reason = pcall(function()
				self.PlayerPurchasesDataStore:SetAsync(key, purchases)
			end)
			return success
		end)
	end
end

function DataService:SavePlayerDataAsync(player)
	local key = self:GetKeyFromPlayer(player)
	local data = self.PlayerDataCache[key]
	if not (key and data) then return end
	
	local success, attempts = self:Attempt(8, function()
		local success, reason = pcall(function()
			self.PlayerDataStore:SetAsync(key, data)
		end)
		return success
	end)
	
	if not success then
		warn(string.format("Attempted to save %s's data, but failed.", player.Name))
	else
		--print(string.format("Successfully saved %s's data after %d attempts.", player.Name, attempts))
	end
end

function DataService:SavePlayerPurchasesAsync(player)
	local key = self:GetKeyFromPlayer(player)
	local purchases = self.PlayerPurchasesCache[key]
	if not (key and purchases) then return end
	
	local success, attempts = self:Attempt(8, function()
		local success, reason = pcall(function()
			self.PlayerPurchasesDataStore:SetAsync(key, purchases)
		end)
		return success
	end)
	
	if not success then
		warn(string.format("Attempted to save %s's purchases, but failed.", player.Name))
	else
		--print(string.format("Successfully saved %s's purchases after %d attempts.", player.Name, attempts))
	end
end

function DataService:SaveGroupDataAsync(players)
	local verbose = false
	local function p(...)
		if verbose then print(...) end
	end
	
	local map = {}
	for _, player in pairs(players) do
		map[player] = false
	end
	
	local event = Instance.new("BindableEvent")
	
	for _, player in pairs(players) do
		spawn(function()
			p("SaveGroupDataAsync saving data for ", player.Name)
			self:SaveAllPlayerDataAsync(player)
			p("SaveGroupDataAsync successfully saved data for ", player.Name)
			map[player] = true
			event:Fire()
		end)
	end
	
	local function allGood()
		for _, val in pairs(map) do
			if not val then
				return false
			end
		end
		return true
	end
	
	p("Saving group data...")
	while not allGood() do
		event.Event:Wait()
	end
	p("Save successful.")
end

function DataService:SaveAllPlayerDataAsync(player)
	self:SavePlayerDataAsync(player)
	self:SavePlayerPurchasesAsync(player)
end

function DataService:SavePlayerData(player)
	spawn(function() self:SavePlayerDataAsync(player) end)
	spawn(function() self:SavePlayerPurchasesAsync(player) end)
end

function DataService:Autosave()
	for _, player in pairs(game.Players:GetPlayers()) do
		self:SavePlayerData(player)
	end
end

function DataService:SetPlayerData(player, data)
	local key = self:GetKeyFromPlayer(player)
	
	self.PlayerDataCache[key] = data
end

function DataService:GetPlayerLevel(player)
	local data = self:GetPlayerData(player)
	if not data then return 0 end
	return data.Level
end

function DataService:GetPlayerLastMission(player)
	local data = self:GetPlayerData(player)
	return data.MissionLog[1]
end

function DataService:UpdateLeaderboard(missionId, difficulty, player, value)
	local mission = require(self.Storage.Missions[missionId])
	local store = DSS:GetOrderedDataStore(missionId..difficulty, self.LeaderboardVersion)
	local key = self:GetKeyFromPlayer(player)
	
	spawn(function()
		self:Attempt(8, function()
			local success, reason = pcall(function()
				store:UpdateAsync(key, function(oldValue)
					if oldValue == nil then
						return value
					end
					
					if mission.RankingType == "MostFloors" then
						return math.max(oldValue, value)
					else
						return math.min(oldValue, value)
					end
				end)
			end)
			if not success then
				warn(reason)
			end
			return success
		end)
	end)
end

function DataService:GetContestLeaderboard()
	local playsStore = DSS:GetOrderedDataStore("ContestPlays", self.LeaderboardVersion)
	local winsStore = DSS:GetOrderedDataStore("ContestWins", self.LeaderboardVersion)
	local ratioStore = DSS:GetOrderedDataStore("ContestRatio", self.LeaderboardVersion)
	
	return {
		Plays = playsStore:GetSortedAsync(false, 10):GetCurrentPage(),
		Wins = winsStore:GetSortedAsync(false, 10):GetCurrentPage(),
		Ratio = winsStore:GetSortedAsync(false, 10):GetCurrentPage(),
	}
end

function DataService:UpdateContestLeaderboard(player, didWin)
	local playsStore = DSS:GetOrderedDataStore("ContestPlays", self.LeaderboardVersion)
	local winsStore = DSS:GetOrderedDataStore("ContestWins", self.LeaderboardVersion)
	local ratioStore = DSS:GetOrderedDataStore("ContestRatio", self.LeaderboardVersion)
	local key = self:GetKeyFromPlayer(player)
	
	local plays, wins
	
	spawn(function()
		self:Attempt(8, function()
			local success, reason = pcall(function()
				plays = playsStore:IncrementAsync(key)
			end)
			return success
		end)
		
		if didWin then
			self:Attempt(8, function()
				local success, reason = pcall(function()
					wins = winsStore:IncrementAsync(key)
				end)
				return success
			end)
		else
			self:Attempt(8, function()
				local success, reason = pcall(function()
					wins = winsStore:GetAsync(key)
				end)
				return success
			end)
		end
		
		if (plays or 0) < 10 then
			self:Attempt(8, function()
				local success, reason = pcall(function()
					ratioStore:SetAsync(key, 0)
				end)
				return success
			end)
		else
			local ratio = (wins or 0) / (plays or 1)
			
			self:Attempt(8, function()
				local success, reason = pcall(function()
					ratioStore:SetAsync(key, ratio * 10000)
				end)
				return success
			end)
		end
	end)
end

function DataService:UpdatePlayerMissionLog(player, update)
	local data = self:GetPlayerData(player)
	
	local missionId = update.MissionId
	local difficulty = update.Difficulty
	assert(missionId)
	
	local function findEntry()
		for index, entry in pairs(data.MissionLog) do
			local isMission = entry.MissionId == missionId
			local isDifficulty = (difficulty == nil) or (entry.Difficulty == difficulty)
			if isMission and isDifficulty then
				return index, entry
			end
		end
	end
	local index, entry = findEntry()
	
	if entry then
		table.remove(data.MissionLog, index)
	else
		entry = {
			MissionId = missionId,
			Difficulty = difficulty,
		}
	end
	
	entry.Timestamp = os.time()
	
	if update.Type == "Attempt" then
		entry.LastResult = "Attempt"
		entry.AttemptCount = (entry.AttemptCount or 0) + 1
		
	elseif update.Type == "Defeat" then
		entry.LastResult = "Defeat"
		
	elseif update.Type == "Victory" then
		entry.LastResult = "Victory"
		entry.VictoryCount = (entry.VictoryCount or 0) + 1
		
		if entry.BestTime and (entry.Version == Configuration.LeaderboardVersion) then
			entry.BestTime = math.min(entry.BestTime, update.Time)
		else
			entry.BestTime = update.Time
			entry.Version = Configuration.LeaderboardVersion
		end
		
		self:UpdateLeaderboard(missionId, update.Difficulty, player, math.floor(update.Time * 1000))
		
	elseif update.Type == "Floors" then
		if entry.BestFloors and (entry.Version == Configuration.LeaderboardVersion) then
			entry.BestFloors = math.max(entry.BestFloors, update.Floors)
		else
			entry.BestFloors = update.Floors
			entry.Version = Configuration.LeaderboardVersion
		end
		
		self:UpdateLeaderboard(missionId, update.Difficulty, player, entry.BestFloors)
		
	else
		error("Unexpected mission log update type: "..update.Type)
	end
	
	table.insert(data.MissionLog, 1, entry)
end

function DataService:ChangePlayerAlignment(player, faction, amount)
	local data = self:GetPlayerData(player)
	local alignment = data.Alignment
	
	local before = alignment[faction]
	alignment[faction] = math.clamp(alignment[faction] + amount, 0, 100)
	local after = alignment[faction]
	
	local image = FactionData[faction].Image
	
	self:FireRemote("AlignmentUpdated", player, alignment)
	self:FireRemote("NotificationRequested", player, {
		Title = "Alignment changed!",
		Content = string.format("%s from %d to %d", faction, before, after),
		Image = image,
	})
end

function DataService:UnlockLore(player, loreId)
	local data = self:GetPlayerData(player)
	local lore = data.Lore
	
	if table.find(lore, loreId) then return false end
	
	local loreEntry = LoreData[loreId]
	if loreEntry == nil then error("Attempted to unlock invalid lore entry with id "..loreId) end
	
	table.insert(lore, loreId)
	
	self:FireRemote("NotificationRequested", player, {
		Title = "Lore Discovered!",
		Content = "\""..loreEntry.Title.."\"",
	})
	
	return true
end

local Singleton = DataService:Create()
return Singleton