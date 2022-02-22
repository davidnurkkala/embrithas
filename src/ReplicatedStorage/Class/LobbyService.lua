local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local CraftingData = require(game:GetService("ReplicatedStorage").CraftingData)

local Super = require(script.Parent)
local LobbyService = Super:Extend()

LobbyService.InviteLifetime = 15

LobbyService.Promos = {
	{
		Code = "threethousandstrong",
		Image = "rbxassetid://7080308755",
		HasItemCallback = function(self, player)
			local weapons = self:GetService("InventoryService"):GetInventory(player).Weapons
			for _, weapon in pairs(weapons) do
				if weapon.Id == 70 then
					return true
				end
			end
			return false
		end,
		GiveItemCallback = function(self, player)
			self:GetService("InventoryService"):AddItem(player, "Weapons", {Id = 70})
		end,
	},
	{
		Code = "embrithasrelease",
		Image = "rbxassetid://7009405765",
		HasItemCallback = function(self, player)
			local weapons = self:GetService("InventoryService"):GetInventory(player).Weapons
			for _, weapon in pairs(weapons) do
				if weapon.Id == 65 then
					return true
				end
			end
			return false
		end,
		GiveItemCallback = function(self, player)
			self:GetService("InventoryService"):AddItem(player, "Weapons", {Id = 65})
		end,
	}
}

function LobbyService:OnCreated()
	self.Parties = {}
	self.InviteGuidsByPlayer = {}
	
	self:ConnectRemote("PartyUpdated", self.OnPartyUpdated, true)
	self:ConnectRemote("TutorialTried", self.TryTutorial, true)
	self:ConnectRemote("OpenPartiesUpdated", self.UpdateOpenParties, true)
	self:ConnectRemote("PromoSubmitted", self.OnPromoSubmitted, true)
	
	Players.PlayerRemoving:Connect(function(player)
		self:OnPlayerRemoving(player)
	end)
	
	Players.PlayerAdded:Connect(function(player)
		self:OnPlayerAdded(player)
	end)
	
	self.Storage.Remotes.GetMissionInfos.OnServerInvoke = function(...)
		return self:GetMissionInfos(...)
	end
	
	self.Storage.Remotes.CraftRecipe.OnServerInvoke = function(...)
		return self:CraftRecipe(...)
	end
	
	self.Storage.Remotes.TryResetStats.OnServerInvoke = function(...)
		return self:TryResetStats(...)
	end
	
	self.Storage.Remotes.LobbyRanger.OnServerInvoke = function(...)
		return self:LobbyRanger(...)
	end
end

function LobbyService:GetPlayerParty(player)
	for _, party in pairs(self.Parties) do
		if party:HasMember(player) then
			return party
		end
	end
	return nil
end

function LobbyService:IsPlayerInParty(player)
	return self:GetPlayerParty(player) ~= nil
end

function LobbyService:AddParty(leader, missionModule)
	local party = self:CreateNew"Party"{
		MissionModule = missionModule,
		MissionId = missionModule.Name,
		Mission = require(missionModule),
	}
	party:AddMember(leader)
	table.insert(self.Parties, party)
	return party
end

function LobbyService:RemoveParty(party)
	local index = table.find(self.Parties, party)
	if index then
		table.remove(self.Parties, index)
		return true
	else
		return false
	end
end

function LobbyService:OnPartyReplicated()
	self:UpdateOpenParties()
end

function LobbyService:UpdateOpenParties()
	for _, player in pairs(game:GetService("Players"):GetPlayers()) do
		local openParties = {}
		
		for _, party in pairs(self.Parties) do
			if party.IsPublic then
				table.insert(openParties, {
					Leader = party:GetLeader(),
					MissionModule = party.MissionModule,
					MemberCount = #party.Members,
					Difficulty = party.Difficulty,
					Qualified = (#self:GetUnmetRequirements(player, party.Mission) == 0)
				})
			end
		end
		
		self:FireRemote("OpenPartiesUpdated", player, openParties)
	end
end

function LobbyService:OnPlayerRemoving(player)
	self.InviteGuidsByPlayer[player] = nil
	
	for _, party in pairs(self.Parties) do
		if party:HasMember(player) then
			party:RemoveMember(player)
			if party:IsEmpty() then
				self:RemoveParty(party)
			end
		end
		
		if party:IsInvited(player) then
			party:Uninvite(player)
		end
		
		party:Replicate()
	end
end

function LobbyService:GetHasPlayerDoneRecruitTraining(player)
	if game:GetService("RunService"):IsStudio() then return true end
	local dataService = self:GetService("DataService")
	local data = dataService:GetPlayerData(player)
	if not data then return false end
	local missionLog = data.MissionLog
	for _, entry in pairs(missionLog) do
		if entry.MissionId == "recruitTraining" and (entry.VictoryCount or 0) > 0 then
			return true
		end
	end
	return false
end

function LobbyService:OnPromoSubmitted(player, code)
	code = string.lower(code)
	
	for _, promo in pairs(self.Promos) do
		if promo.Code == code then
			if not promo.HasItemCallback(self, player) then
				promo.GiveItemCallback(self, player)
				return
			end
		end
	end
	self:FireRemote("PromoSubmitted", player)
end

function LobbyService:TryPromo(player, image, hasItemCallback)
	if hasItemCallback(self, player) then return end
	
	self:FireRemote("PromoRequested", player, {
		Image = image,
	})
end

function LobbyService:TryGiveaway(player)
	-- regular giveaway
	-- none
	
	-- discord promo
	local promo = self.Promos[1]
	self:TryPromo(player, promo.Image, promo.HasItemCallback)
end

function LobbyService:OnPlayerAdded(player)
	if not self:GetHasPlayerDoneRecruitTraining(player) then
		wait(5)
		self:OnPartyRequested(player, "recruitTraining")
		return
	end
	
	self:TryGiveaway(player)
	
	for _, party in pairs(self.Parties) do
		party:Replicate()
	end
end

function LobbyService:OnPartyRequested(player, missionId, startPublic)
	if self:IsPlayerInParty(player) then return end
	local missionModule = self.Storage.Missions:FindFirstChild(missionId)
	if not missionModule then return end
	
	local party = self:AddParty(player, missionModule)
	if startPublic then
		party.IsPublic = true
	end
	party:Replicate()
	
	if party.Mission.PartySize == 1 then
		self:OnPartyEmbarked(player)
	end
end

function LobbyService:OnPartyQuickPlayRequested(player, missionId)
	for _, party in pairs(self.Parties) do
		if party.MissionId == missionId and party.IsPublic then
			return self:OnPartyJoined(player, party:GetLeader())
		end
	end
	self:OnPartyRequested(player, missionId, true)
end

function LobbyService:OnPartyLeft(player)
	local party = self:GetPlayerParty(player)
	if party then
		party:RemoveMember(player)
		if party:IsEmpty() then
			self:RemoveParty(party)
		else
			party:Replicate()
		end
	end
	
	self:UpdateOpenParties()
end

function LobbyService:CanPartyPayForMission(party, mission)
	if not mission.Cost then return true end
	if not party.ContributionsByMember then return false end
	
	local inventoryService = self:GetService("InventoryService")
	
	-- ensure that all costs are covered
	for costName, amount in pairs(mission.Cost) do
		if costName == "Gold" then
			local contributed = 0
			for member, contribution in pairs(party.ContributionsByMember) do
				contribution.Gold = math.min(contribution.Gold, inventoryService:GetInventory(member).Gold)
				contributed = contributed + contribution.Gold
			end
			
			if contributed < amount then
				return false
			end
		end
	end
	
	-- at this point we've confirmed all costs are covered, now we can take stuff
	for costName, amount in pairs(mission.Cost) do
		if costName == "Gold" then
			local memberAmountPairs = {}
			for member, contribution in pairs(party.ContributionsByMember) do
				table.insert(memberAmountPairs, {
					Member = member,
					Amount = contribution.Gold,
				})
			end
			
			table.sort(memberAmountPairs, function(a, b)
				return a.Amount > b.Amount
			end)
			
			for _, pair in pairs(memberAmountPairs) do
				local taken = math.min(amount, pair.Amount)
				inventoryService:RemoveGold(pair.Member, taken)
				amount = amount - taken
				
				if amount <= 0 then
					break
				end
			end
		end
	end
	
	-- all good, everything's taken care of
	return true
end

function LobbyService:DoesPlayerOwnExpansion(player, packId)
	local cosmetics = self:GetService("DataService"):GetPlayerCosmetics(player)
	local product = require(self.Storage.ProductData).Expansion[packId]
	local owned = (cosmetics.IsUnlimited) or (table.find(cosmetics.Purchased, product.ProductId) ~= nil)
	return owned
end

function LobbyService:OnPartyDifficultyChanged(player, difficulty)
	local party = self:GetPlayerParty(player)
	if not party then return end
	if player ~= party:GetLeader() then return end
	if not self:GetClass("Run").DifficultyData[difficulty] then return end

	party.Difficulty = difficulty
	party:Replicate()
end

function LobbyService:OnPartyMadePublic(player)
	local party = self:GetPlayerParty(player)
	if not party then return end
	if player ~= party:GetLeader() then return end
	if party.IsPublic then return end
	
	party.IsPublic = true
	party:Replicate()
end

function LobbyService:OnPartyEmbarked(player)
	local party = self:GetPlayerParty(player)
	if not party then return end
	if party.Embarking then return end
	if player ~= party:GetLeader() then return end
	
	local mission = party.Mission
	if mission.Hidden then return end
	
	if mission.RequiredExpansion then
		if not self:DoesPlayerOwnExpansion(party.Members[1], mission.RequiredExpansion) then
			return
		end
	end
	
	for _, member in pairs(party.Members) do
		local unmetRequirements = self:GetUnmetRequirements(member, mission)
		if #unmetRequirements > 0 then return end
	end
	
	if not self:CanPartyPayForMission(party, mission) then return end
	
	local dataService = self:GetService("DataService")
	local maxLevel = dataService:GetPlayerLevel(party:GetLeader())
	
	local teleportData = {
		MissionId = party.MissionModule.Name,
		MaxPlayerLevel = maxLevel,
		Difficulty = party.Difficulty,
	}
	
	if #party.Members > mission.PartySize then return end
	
	party.Embarking = true
	
	for _, player in pairs(party.Members) do
		self:FireRemote("PartyUpdated", player, "Embarked")
		
		self:GetService("QuestService"):ProcessGameplayEvent(player, {
			Type = "StartMission",
			MissionId = party.MissionModule.Name,
		})
	end
	
	local teleportGui = self.Storage.UI.LoadingGui:Clone()
	teleportGui.TitleLabel.Text = mission.Name
	teleportGui.TipLabel.Text = ""
	
	self:GetService("DataService"):SaveGroupDataAsync(party.Members)
	
	pcall(function()
		teleportData = self:GetService("AnalyticsService"):AddTeleportData(party.Members, teleportData)
	end)
	
	for _, player in pairs(party.Members) do
		teleportGui:Clone().Parent = player.PlayerGui
	end
	
	local placeId = game.PlaceId
	local serverId = TeleportService:ReserveServer(placeId)
	TeleportService:TeleportToPrivateServer(placeId, serverId, party.Members, nil, teleportData, teleportGui)
end

function LobbyService:CanPlayerInvite(inviter, invitee)
	if not inviter then return false end
	if not invitee then return false end
	
	local options = self:GetService("OptionsService"):GetPlayerOptions(invitee)
	if options.InviteFilter == "None" then
		return true
		
	elseif options.InviteFilter == "Friends" then
		return invitee:IsFriendsWith(inviter.UserId)
	end
end

function LobbyService:OnPartyJoined(player, partyLeader)
	if player == partyLeader then return end
	if self:GetPlayerParty(player) then return end
	local party = self:GetPlayerParty(partyLeader)
	if not party then return end
	if party:HasMember(player) then return end
	if not party.IsPublic then return end
	local partySize = #party.Members + 1
	if partySize >= party.Mission.PartySize then return end
	
	party:AddMember(player)
	party:Replicate()
end

function LobbyService:OnPartyInvited(player, invited)
	if invited == player then return end
	local party = self:GetPlayerParty(player)
	if not party then return end
	if player ~= party:GetLeader() then return end
	if party:HasMember(invited) then return end
	if party:IsInvited(invited) then return end
	local partySize = #party.Members + #party.Invited
	if partySize >= party.Mission.PartySize then return end
	if not self:CanPlayerInvite(player, invited) then return end
	
	local inviteGuid = HttpService:GenerateGUID()
	self.InviteGuidsByPlayer[invited] = inviteGuid
	
	party:Invite(invited)
	party:Replicate()
	
	self:FireRemote("PartyUpdated", invited, "Invited", {
		Leader = player,
		MissionModule = party.MissionModule
	})
	
	delay(self.InviteLifetime, function()
		if self.InviteGuidsByPlayer[invited] ~= inviteGuid then return end
		self.InviteGuidsByPlayer[invited] = nil
		
		if party:Uninvite(invited) then
			party:Replicate()
			self:FireRemote("PartyUpdated", invited, "InviteExpired", player)
		end
	end)
end

function LobbyService:OnPartyInviteAccepted(player, leader)
	if not leader then return end
	local party = self:GetPlayerParty(leader)
	if not party then return end
	if leader ~= party:GetLeader() then return end
	if party:HasMember(player) then return end
	if not party:IsInvited(player) then return end
	
	party:Uninvite(player)
	party:AddMember(player)
	party:Replicate()
end

function LobbyService:OnPartyInviteRejected(player, leader)
	if not leader then return end
	local party = self:GetPlayerParty(leader)
	if not party then return end
	if leader ~= party:GetLeader() then return end
	if party:HasMember(player) then return end
	if not party:IsInvited(player) then return end
	
	party:Uninvite(player)
	party:Replicate()
end

function LobbyService:OnPartyKicked(player, kicked)
	if kicked == player then return end
	local party = self:GetPlayerParty(player)
	if not party then return end
	if player ~= party:GetLeader() then return end
	if not party:HasMember(kicked) then return end
	
	party:RemoveMember(kicked)
	party:Replicate()
	
	self:FireRemote("PartyUpdated", kicked, "Kicked")
end

function LobbyService:IsContributionValid(player, contribution)
	local dataService = self:GetService("DataService")
	local inventoryService = self:GetService("InventoryService")
	local inventory = inventoryService:GetInventory(player)
	
	for costName, amount in pairs(contribution) do
		if costName == "Gold" then
			if tonumber(amount) == nil then
				return false
			end
			
			if amount ~= amount then
				return false
			end
			
			amount = math.floor(amount)
			
			if (amount < 0) or (amount > inventory.Gold) then
				return false
			end
		end
		
		contribution[costName] = amount
	end
	
	return true
end

function LobbyService:OnPartyContributed(player, contribution)
	local party = self:GetPlayerParty(player)
	if not party then return end
	
	if not self:IsContributionValid(player, contribution) then return end
	
	party:AddMemberContribution(player, contribution)
	party:Replicate()
end

function LobbyService:OnPartyUpdated(player, func, ...)
	self["OnParty"..func](self, player, ...)
end

function LobbyService:GetUnmetRequirements(player, mission)
	local unmetRequirements = {}
	
	local dataService = self:GetService("DataService")
	
	local function checkRequirement(requirement)
		if requirement.Type == "Level" then
			local playerLevel = dataService:GetPlayerLevel(player)
			return playerLevel >= requirement.Level
			
		elseif requirement.Type == "Mission" then
			local missionLog = dataService:GetPlayerData(player).MissionLog
			for _, entry in pairs(missionLog) do
				if (entry.MissionId == requirement.Id) and entry.VictoryCount and (entry.VictoryCount > 0) then
					return true
				end
			end
			return false
			
		elseif requirement.Type == "Alignment" then
			local alignment = dataService:GetPlayerData(player).Alignment
			return alignment[requirement.Faction] >= requirement.Amount
		end
	end
	
	local requirements = {}
	for _, requirement in pairs(mission.Requirements or {}) do
		table.insert(requirements, requirement)
	end
	
	for _, requirement in pairs(requirements) do
		if not checkRequirement(requirement) then
			table.insert(unmetRequirements, requirement)
		end
	end
	
	return unmetRequirements
end

function LobbyService:GetMissionInfos(player)
	local missionInfos = {}
	
	for _, missionModule in pairs(self.Storage.Missions:GetChildren()) do
		local mission = require(missionModule)
		if not mission.Hidden then
			local missionInfo = {
				Module = missionModule,
				UnmetRequirements = self:GetUnmetRequirements(player, mission),
			}
			
			table.insert(missionInfos, missionInfo)
		end
	end
	
	return missionInfos
end

function LobbyService:LobbyRanger(player, request)
	local function getStatus()
		local data = self:GetService("DataService"):GetPlayerData(player)

		local function findAbility(id)
			for _, ability in pairs(data.Inventory.Abilities) do
				if ability.Id == id then
					return true
				end
			end
			return false
		end

		if findAbility(20) then
			return "barrage"
		elseif findAbility(19) then
			return "explosive"
		elseif findAbility(16) then
			return "rain"
		elseif findAbility(18) then
			return "fan"
		elseif findAbility(17) then
			return "ricochet"
		end

		for _, quest in pairs(data.QuestLogData.Quests) do
			if quest.Name == "Ranger Basics" then
				return "quest"
			end
		end

		return "fresh"
	end
	
	if request == "query" then
		return getStatus()
		
	elseif request == "startQuest" then
		if getStatus() ~= "fresh" then return false end
		
		self:GetService("QuestService"):AddQuestToPlayer(player, self:GetClass("Quest"):CreateFromData(require(self.Storage.QuestData).rangerQuest1))
		
		return true
	end
end

function LobbyService:TryResetStats(player)
	local data = self:GetService("DataService"):GetPlayerData(player)
	if not data then return false, "noData" end
	
	if data.Inventory.Gold < 1000 then
		return false, "gold"
	end
	
	local total = 0
	for statName, value in pairs(data.Stats) do
		total += value
	end
	if total == 0 then
		return false, "zero"
	end
	
	self:GetService("InventoryService"):RemoveGold(player, 1000)
	self:GetService("StatService"):ResetStats(player)
	
	
	
	return true, ""
end

function LobbyService:CraftRecipe(player, categoryIndex, recipeId, repeats, itemIndicesById)
	if typeof(repeats) ~= "number" then return end
	
	-- detect NaN
	if repeats ~= repeats then return end
	
	if not recipeId then return false end
	
	if repeats < 1 then return end
	repeats = math.floor(repeats)
	
	local category = CraftingData.Categories[categoryIndex]
	if not category then return false end
	
	local recipe = category.Recipes[recipeId]
	if not recipe then return false end
	
	local dataService = self:GetService("DataService")
	local playerData = dataService:GetPlayerData(player)
	
	local inventoryService = self:GetService("InventoryService")
	local inventory = inventoryService:GetInventory(player)
		
	-- check that we have the materials
	for _, input in pairs(recipe.Inputs) do
		local held = 0
		local required = 0
		
		if input.Category == "Gold" then
			held = inventory.Gold
			required = input.Amount * repeats
			
		elseif input.Category == "Alignment" then
			held = playerData.Alignment[input.Faction]
			required = input.Amount
			
		elseif input.Category == "Materials" then
			for index, slotData in pairs(inventory.Materials) do
				if slotData.Id == input.Id then
					held = held + slotData.Amount
				end
			end
			required = input.Count * repeats
		else
			required = input.Count * repeats
			
			local id = input.Id
			local indices = itemIndicesById[tostring(id)]
			if not indices then
				return false
			end
			
			-- ensure none of the selected indices are equipped weapons, non-existent, or the wrong item
			for _, index in pairs(indices) do
				local isEquippedWeapon = (input.Category == "Weapons") and ((index == inventory.EquippedWeaponIndex) or (index == inventory.OffhandWeaponIndex))
				
				if isEquippedWeapon then
					return false
				end
				
				local slotData = inventory[input.Category][index]
				if not slotData then
					return false
				end
				if slotData.Id ~= id then
					return false
				end
			end
			
			-- count 'em
			held = #indices
		end
		
		if held < required then
			return false
		end
	end
	
	-- remove the materials
	local removedIndicesByCategory = {}
	
	for _, input in pairs(recipe.Inputs) do
		if input.Category == "Gold" then
			inventory.Gold = inventory.Gold - (input.Amount * repeats)
			
		elseif input.Category == "Alignment" then
			-- do nothing, alignments are mere requirements
			
		elseif input.Category == "Materials" then
			for index, slotData in pairs(inventory.Materials) do
				if slotData.Id == input.Id then
					slotData.Amount = slotData.Amount - (input.Count * repeats)
					if slotData.Amount == 0 then
						table.remove(inventory.Materials, index)
					end
					
					break
				end
			end
		else
			if not removedIndicesByCategory[input.Category] then
				removedIndicesByCategory[input.Category] = {}
			end
			
			local indices = itemIndicesById[tostring(input.Id)]
			for _, index in pairs(indices) do
				table.insert(removedIndicesByCategory[input.Category], index)
			end
		end
	end
	
	-- sort and remove the chosen indices in descending order by category (yikes)
	for category, indices in pairs(removedIndicesByCategory) do
		table.sort(indices, function(a, b)
			return b < a
		end)
		
		for _, index in pairs(indices) do
			table.remove(inventory[category], index)
		end
	end
	
	-- add the new items
	for _, output in pairs(recipe.Outputs) do
		if output.Category == "Materials" then
			inventoryService:AddItem(player, "Materials", {Id = output.Id, Amount = output.Count * repeats})
			
		elseif output.Category == "Alignment" then
			dataService:ChangePlayerAlignment(player, output.Faction, output.Amount * repeats)
			
		else
			for _ = 1, output.Count * repeats do
				local slotData = {Id = output.Id, Level = output.Level or 1}
				
				if output.Category == "Weapons" then
					slotData = self:GetService("LootService"):GenerateWeapon(slotData)
				end
				
				inventoryService:AddItem(player, output.Category, slotData)
			end
		end
	end
	
	return true
end

-- tutorial stuff
function LobbyService:IsTutorial()
	return self:GetRun().RunData.IsTutorial
end

function LobbyService:TryTutorial()
	if not self:IsTutorial() then return end
	
	local player = self:GetTutorialPlayer()
	
	self:FireRemote("TutorialUpdated", player, "walkToAnvil")
	
	local dataService = self:GetService("DataService")
	local data = dataService:GetPlayerData(player)
	dataService:CheckFlag(data, dataService.Flags.HasDoneIntroQuest, function()
		local questData = require(self.Storage.QuestData).introQuest1
		self:GetService("QuestService"):AddQuestToPlayer(player, self:GetClass("Quest"):CreateFromData(questData))
	end)
end

function LobbyService:GetTutorialPlayer()
	return game:GetService("Players"):GetPlayers()[1]
end

local Singleton = LobbyService:Create()
return Singleton