local Super = require(script.Parent)
local Run = Super:Extend()

local TeleportService = game:GetService("TeleportService")

Run.Active = true
Run.Floor = 1
Run.State = "Running"
Run.Points = 0
Run.LivesEarned = 0

Run.DifficultyData = {
	Recruit = {
		LevelDelta = -5,
		DamageMultiplier = 0.8,
		HealthMultiplier = 0.8,
		Armor = -0.1,
		LootChance = 0.6,
	},
	Rookie = {
		ModifierChance = 0.01,
		DamageMultiplier = 1,
		HealthMultiplier = 1,
		LootChance = 1,
	},
	Slayer = {
		LevelDelta = 5,
		DamageMultiplier = 1.1,
		HealthMultiplier = 1.1,
		Armor = 0.025,
		ModifierChance = 0.05,
		EliteChance = 0.02,
		ExtraSpawns = {0, 2},
		LootChance = 1.5,
	},
	Veteran = {
		LevelDelta = 10,
		DamageMultiplier = 1.25,
		HealthMultiplier = 1.2,
		Armor = 0.05,
		ModifierChance = 0.2,
		ModifierDoubleChance = 0.25,
		EliteChance = 0.05,
		ExtraSpawns = {2, 4},
		LootChance = 2,
	},
	Hero = {
		LevelDelta = 15,
		DamageMultiplier = 1.5,
		HealthMultiplier = 1.3,
		Armor = 0.075,
		ModifierChance = 0.5,
		ModifierDoubleChance = 0.5,
		EliteChance = 0.07,
		ExtraSpawns = {3, 7},
		LootChance = 3,
	},
	["Legendary Hero"] = {
		LevelDelta = 25,
		DamageMultiplier = 2,
		HealthMultiplier = 1.5,
		Armor = 0.1,
		ModifierChance = 0.9,
		ModifierDoubleChance = 0.6,
		ModifierTripleChance = 0.3,
		EliteChance = 0.1,
		ExtraSpawns = {5, 10},
		LootChance = 6,
	}
}

function Run:OnCreated()
	self:GetClass("Class").Run = self
	
	self.FloorModifiers = {}
	
	self.LivesRemaining = self.RunData.StartingLifeCount or 3
	self.RespawnQueue = {}
	
	self.Finished = self:CreateNew"Event"()
	self.LifeEarned = self:CreateNew"Event"()
	
	self:GetService("LogService"):Reset()
	
	print("Starting dungeon gen")
	self:NewDungeon()
	print("Done with dungeon gen")
	
	local function onPlayerAdded(...) self:OnPlayerAdded(...) end
	spawn(function()
		self:AddConnection(game.Players.PlayerAdded:Connect(onPlayerAdded))
		for _, player in pairs(game.Players:GetPlayers()) do
			onPlayerAdded(player)
		end
	end)
end

function Run:GetDifficultyData()
	if self.RunData.Difficulty then
		return self.DifficultyData[self.RunData.Difficulty]
	else
		return self.DifficultyData.Rookie
	end
end

function Run:GetFloorItemSetData()
	local floorData = self.RunData.Floors[self.Floor]
	if floorData and floorData.FloorItemSets then
		return floorData.FloorItemSets, floorData.FloorItemSetWeights
	elseif self.RunData.FloorItemSets then
		return self.RunData.FloorItemSets, self.RunData.FloorItemSetWeights
	else
		return nil
	end
end

function Run:StartDungeon()
	local dungeon = self.Dungeon
	
	dungeon.Completed:Connect(function()
		if dungeon ~= self.Dungeon then return end
		
		self:OnDungeonCompleted()
	end)
	
	if self.StartTime == nil then
		dungeon.Started:Connect(function()
			self.StartTime = tick()
		end)
	end
	
	self:StartFloorModifiers()
	
	-- if this floor has an OnStarted event then we need to do it
	delay(1, function()
		self:DoFloorEvent("OnStarted")
	end)
end

function Run:StartFloorModifiers()
	local floorData = self.RunData.Floors[self.Floor]
	if not floorData then return end
	if not floorData.Modifiers then return end
	
	for _, modifierName in pairs(floorData.Modifiers) do
		if typeof(modifierName) == "table" then
			local args = {
				Run = self,
				Dungeon = self.Dungeon
			}
			for key, val in pairs(modifierName.Args) do
				args[key] = val
			end
			
			local modifier = self:CreateNew("FloorModifier"..modifierName.Class)(args)
			table.insert(self.FloorModifiers, modifier)
		else
			local modifier = self:CreateNew("FloorModifier"..modifierName){
				Run = self,
				Dungeon = self.Dungeon,
			}
			table.insert(self.FloorModifiers, modifier)
		end
	end
end

function Run:EndFloorModifiers()
	for _, modifier in pairs(self.FloorModifiers) do
		modifier:OnEnded()
	end
	self.FloorModifiers = {}
end

function Run:NewDungeon()
	local floorData = self.RunData.Floors[self.Floor]
	
	local args = {}
	for key, val in pairs(floorData.Args or {}) do
		args[key] = val
	end
	args.Level = self.Floor + self.RunData.Level
	args.Run = self
	
	if floorData.Type == "Basic" then
		self.Dungeon = self:CreateNew"DungeonBasic"(args)
		
	elseif floorData.Type == "Granular" then
		self.Dungeon = self:CreateNew"DungeonGranular"(args)
		
	elseif floorData.Type == "Granular2" then
		self.Dungeon = self:CreateNew"DungeonGranular2"(args)
	
	elseif floorData.Type == "Custom" then
		self.Dungeon = self:CreateNew"DungeonCustom"(args)
	
	elseif floorData.Type == "Tutorial" then
		self.Dungeon = self:CreateNew"DungeonTutorial"(args)
	
	elseif floorData.Type == "Lobby" then
		self.Dungeon = self:CreateNew"DungeonLobby"(args)
		
	else
		self.Dungeon = self:CreateNew("Dungeon"..floorData.Type)(args)
		
	end
	
	if floorData.Encounters then
		self.Dungeon:DistributeEncounters(floorData.Encounters)
	end
	
	self:StartDungeon()
end

function Run:RequestEnemy()
	local floorData = self.RunData.Floors[self.Floor]
	local enemies = floorData.Enemies or self.RunData.Enemies
	
	return self:GetWeightedResult(enemies)
end

function Run:DoFloorEvent(eventName)
	local floorData = self.RunData.Floors[self.Floor]
	if not floorData then return end
	local events = floorData.Events
	if not events then return end
	local event = events[eventName]
	if not event then return end
	
	local EffectsService = self:GetService("EffectsService")
	
	local pause = 0
	
	for eventType, eventArgs in pairs(event) do
		if eventType == "Dialogue" then
			EffectsService:RequestEffectAll("Dialogue", eventArgs)
		elseif eventType == "Pause" then
			pause = eventArgs
		elseif eventType == "Custom" then
			spawn(function() eventArgs(self) end)
		end
	end
	
	if pause > 0 then
		wait(pause)
	end
end

function Run:ShowTitleForCurrentFloor(player, isNewArrival)
	local floorData = self.RunData.Floors[self.Floor]
	if not floorData then
		floorData = {Name = "Floor "..self.Floor}
	end
	
	local holdDuration = nil
	local fadeOutDuration = 0.5
	if isNewArrival then
		holdDuration = 2
		fadeOutDuration = 0
	end
	
	return self:GetService("EffectsService"):RequestEffect(player, "TitleScreen", {
		Title = floorData.Name,
		Subtitle = self.RunData.Name,
		
		FadeOutDuration = fadeOutDuration,
		HoldDuration = holdDuration,
		FadeInDuration = 0.5,
	})
end

function Run:CheckForVictory()
	return self.RunData.Floors[self.Floor] == nil
end

function Run:OnDungeonCompleted()
	if self.State ~= "Running" then return end
	
	-- enemies be gone
	self:ClearAllEnemies()
	
	-- respawn all waiting players
	self:PurgeAbsentPlayers()
	for _, player in pairs(self.RespawnQueue) do
		self:SpawnLegendForPlayer(player)
	end
	self.RespawnQueue = {}
	
	if self.RunData.RankingType == "MostFloors" then
		self:UpdateAllMissionLogs({
			Difficulty = self.RunData.Difficulty,
			Type = "Floors",
			Floors = self.Floor,
		})
	end
	
	self:DoFloorEvent("OnFinished")
	
	-- increment the floor
	self.Floor = self.Floor + 1
	
	-- did we win?
	if self:CheckForVictory() then
		self:Victory()
		return
	end
	
	-- now start the transition
	self.State = "Transitioning"
	
	-- pause for a message and to maybe do some last minute looting
	self:GetService("EffectsService"):RequestEffectAll("Message", {
		Text = string.format("Floor %d cleared!", self.Floor - 1)
	})
	wait(5)
	
	local trailControl = Instance.new("BoolValue")
	trailControl.Name = "MapTrailsDisabled"
	trailControl.Value = true
	trailControl.Parent = workspace
	
	-- lift everyone into the air
	local offset = Vector3.new(0, 32, 0)
	local legends = self:GetClass("Legend").Instances
	for _, legend in pairs(legends) do
		local bp = Instance.new("BodyPosition")
		bp.Name = "DungeonTransitionMover"
		bp.Position = legend.Root.Position + offset
		bp.MaxForce = Vector3.new(1e9, 1e9, 1e9)
		bp.Parent = legend.Root
	end
	
	wait(1)
	
	-- explode the dungeon
	self.Dungeon:Explode()
	self:EndFloorModifiers()
	
	wait(1)
	
	local titleScreenEffectIds = {}
	for _, legend in pairs(legends) do
		local id = self:ShowTitleForCurrentFloor(legend.Player, false)
		table.insert(titleScreenEffectIds, id)
		
		legend.Root.Anchored = true
		
		local mover = legend.Root:FindFirstChild("DungeonTransitionMover")
		if mover then
			mover:Destroy()
		end
	end
	
	wait(1)
	
	-- create a new dungeon and put everyone in position
	self:NewDungeon()
	
	-- cancel all the title screens
	for _, titleScreenEffectId in pairs(titleScreenEffectIds) do
		self:GetService("EffectsService"):CancelEffect(titleScreenEffectId)
	end
	
	local startRoom = self.Dungeon.StartRoom
	for _, legend in pairs(legends) do
		local position = startRoom:GetSpawn(false) + Vector3.new(0, 8, 0)
		legend.Root.CFrame = CFrame.new(position)
	end
	
	wait(1)
	
	if self.RunData.LifeType == "Raid" then
		self.LivesRemaining = self.RunData.StartingLifeCount
		self.LivesEarned = 0
		self.Points = 0
	end
	
	for _, legend in pairs(legends) do
		legend.Root.Anchored = false
	end
	
	delay(1, function()
		trailControl:Destroy()
	end)
	
	self.State = "Running"
end

function Run:Review(title)
	title = self.RunData.Name.."\n"..title
	
	local runAgainEnabled = true
	if self.RunData.Cost ~= nil then
		runAgainEnabled = false
	end
	
	delay(3, function()
		self:EndFloorModifiers()
	end)
	
	-- time to review and vote on the next course of action
	self.ReviewData = self:GetService("LogService"):GetReviewData()
	self:FireRemoteAll("ReviewRequested", title, self.ReviewData, runAgainEnabled)
	
	local voteData = {}
	local timer = 60
	
	local function onReviewVoted(voter, vote)
		voteData[voter.Name] = vote
		self:FireRemoteAll("ReviewVoted", timer, voteData)
	end
	local reviewVoted = self.Storage.Remotes.ReviewVoted.OnServerEvent:Connect(onReviewVoted)
	
	local function hasEveryoneVoted()
		for _, player in pairs(game:GetService("Players"):GetPlayers()) do
			if voteData[player.Name] == nil then
				return false
			end
		end
		return true
	end
	
	while (timer > 0) and (not hasEveryoneVoted()) do
		timer = timer - wait(0.5)
		self:FireRemoteAll("ReviewVoted", timer, voteData)
	end
	
	reviewVoted:Disconnect()
	self:FireRemoteAll("ReviewEnded")
	
	-- return the players that voted to return
	local returningPlayers = {}
	local players = game:GetService("Players")
	if runAgainEnabled then
		for _, player in pairs(players:GetPlayers()) do
			if voteData[player.Name] == "Return" then
				table.insert(returningPlayers, player)
			end
		end
	else
		returningPlayers = players:GetPlayers()
	end
	if #returningPlayers > 0 then
		spawn(function()
			self:GetService("DataService"):SaveGroupDataAsync(returningPlayers)
			
			local teleportGui = self.Storage.UI.LoadingGui:Clone()
			teleportGui.TitleLabel.Text = "Slayer Alliance Headquarters"
			teleportGui.TipLabel.Text = ""
			
			local teleportData = {}
			teleportData = self:GetService("AnalyticsService"):AddTeleportData(returningPlayers, teleportData)
			
			for _, player in pairs(returningPlayers) do
				teleportGui:Clone().Parent = player.PlayerGui
			end
			
			game:GetService("TeleportService"):TeleportPartyAsync(game.PlaceId, returningPlayers, teleportData, teleportGui)
		end)
	end
end

function Run:DoRewards()
	local players = game:GetService("Players"):GetPlayers()
	local inventoryService = self:GetService("InventoryService")
	local dataService = self:GetService("DataService")
	local rewardLevel = self.RunData.Level
	
	if self.RunData.FirstTimeRewards then
		for _, player in pairs(players) do
			local isFirstTime = true
			local missionLog = dataService:GetPlayerData(player).MissionLog
			local victories = 0
			for _, entry in pairs(missionLog) do
				if entry.MissionId == self.RunData.MissionId then
					victories += (entry.VictoryCount or 0)
				end
			end
			if victories > 1 then
				isFirstTime = false
			end
			
			if isFirstTime then
				local levelService = self:GetService("LevelService")
				local runLevel = math.max(1, self.RunData.Level)
				levelService:AddExperience(player, levelService:GetRequiredExperienceAtLevel(runLevel) * 2)
				
				for _, reward in pairs(self.RunData.FirstTimeRewards) do
					if reward.Type == "Weapon" then
						local slotData = self:GetService("LootService"):GenerateWeapon{Id = reward.Id}
						inventoryService:AddItem(player, "Weapons", slotData)
					elseif reward.Type == "Ability" then
						inventoryService:AddItem(player, "Abilities", {Id = reward.Id})
					elseif reward.Type == "Material" then
						inventoryService:AddItem(player, "Materials", {Id = reward.Id, Amount = reward.Amount or 1})
					elseif reward.Type == "Alignment" then
						dataService:ChangePlayerAlignment(player, reward.Faction, reward.Amount)
					end
				end
				
				self:FireRemote("NotificationRequested", player, {
					Title = "First clear rewards!",
					Content = "Bonus items for first clear:",
				})
			end
		end
	end
	
	if not self.RunData.Rewards then return end

	local lootChance = self:GetDifficultyData().LootChance or 1
	
	local seed = tick()
	local random = Random.new(seed)
	
	for _, player in pairs(players) do
		self:DebugMessage("Rolling loot for %s.", player.Name)
		
		if not self.RunData.RewardsRolledSeperately then
			random = Random.new(seed)
		end
		
		for _, reward in pairs(self.RunData.Rewards) do
			local roll = random:NextNumber()
			
			self:DebugMessage("Reward %s with roll %4.4f", self:DebugTableValues(reward), roll)
			
			if reward.Chance then
				local mercyNumber = math.floor(1 / reward.Chance)
				local completionTimes = self:GetService("DataService"):GetTotalMissionCompletions(player, self.RunData.MissionId)
				if (completionTimes ~= 0) and (completionTimes % mercyNumber == 0) then
					roll = 0
				end
			end
			
			if (reward.Chance == nil) or (roll <= reward.Chance * lootChance) then
				if reward.Type == "Weapon" then
					local slotData = self:GetService("LootService"):GenerateWeapon{Id = reward.Id}
					inventoryService:PromptAddItem(player, "Weapons", slotData)
				elseif reward.Type == "Ability" then
					inventoryService:PromptAddItem(player, "Abilities", {Id = reward.Id})
				elseif reward.Type == "Trinket" then
					inventoryService:PromptAddItem(player, "Trinkets", {
						Id = reward.Id,
					})
				elseif reward.Type == "Material" then
					local amount = reward.Amount or 1
					local max = math.ceil(amount * lootChance)
					amount = random:NextInteger(math.ceil(max / 2), max)
					
				inventoryService:PromptAddItem(player, "Materials", {
						Id = reward.Id,
						Amount = amount,
					})
				elseif reward.Type == "Alignment" then
					local amount = reward.Amount
					local max = math.ceil(amount * lootChance)
					amount = random:NextInteger(math.ceil(max / 2), max)
					
					dataService:ChangePlayerAlignment(player, reward.Faction, amount)
				elseif reward.Type == "Product" then
					local product = require(self.Storage.ProductData)[reward.Category][reward.Id]
					
					local dataService = self:GetService("DataService")
					local purchases = dataService:GetPlayerPurchases(player)
					if purchases and (table.find(purchases.Products, product.ProductId) == nil) then
						table.insert(purchases.Products, product.ProductId)
						self:FireRemote("CosmeticsUpdated", player, dataService:GetPlayerCosmetics(player))
						
						self:FireRemote("NotificationRequested", player, {
							Title = "New cosmetic!",
							Content = product.Name,
							Image = product.Image,
						})
					end
				end
			end
		end
		
		-- give one random generic weapon
		--local weaponIds = self:GetService("WeaponService").GenericWeaponIds
		--local id = weaponIds[random:NextInteger(1, #weaponIds)]
		--inventoryService:PromptAddItem(player, "Weapons", {
		--	Id = id,
		--	Level = rewardLevel,
		--})
		
		-- give gold per mission level unless the mission has a cost
		if self.RunData.Cost == nil then
			local min = rewardLevel * 10
			local max = rewardLevel * 20
			
			max = math.ceil(max * lootChance)
			min = math.ceil(max / 2)
			
			local amount = random:NextInteger(min, max)
			
			inventoryService:AddGold(player, amount)
			self:FireRemote("NotificationRequested", player, {
				Title = "Gold acquired!",
				Content = amount,
				Image = "rbxassetid://5272914329",
			})
		end
		
		self:DebugMessage("Loot roll complete.")
	end
end

function Run:UpdateAllMissionLogs(update)
	if self.RunData.MissionId then
		update.MissionId = self.RunData.MissionId
		for _, player in pairs(game.Players:GetPlayers()) do
			self:GetService("DataService"):UpdatePlayerMissionLog(player, update)
			
			local status
			if update.Type == "Victory" then
				status = "Complete"
			elseif update.Type == "Defeat" then
				status = "Fail"
			end
			if status then
				self:GetService("AnalyticsService"):AddProgressionEvent(player, self.RunData.MissionId, self.RunData.Difficulty or "Rookie", status)
			end
		end
	end
end

function Run:ClearAllEnemies()
	for _, object in pairs(self:GetWorld().Objects) do
		if object:IsA(self:GetClass("Enemy")) then
			object:Deactivate()
		end
	end
end

function Run:TryRecruitTrainingTeleport()
	if self.RunData.MissionId ~= "recruitTraining" then return end
	
	-- guarantee a save before teleporting the user back
	self:GetService("DataService"):SaveOnClose()
	
	local players = game:GetService("Players"):GetPlayers()
	local teleportData = {
		MissionId = "lobby",
		Args = {
			IsTutorial = true,
		},
	}
	teleportData = self:GetService("AnalyticsService"):AddTeleportData(players, teleportData)
	
	local placeId = game.PlaceId
	local serverId = TeleportService:ReserveServer(placeId)
	TeleportService:TeleportToPrivateServer(placeId, serverId, players, nil, teleportData)
end

function Run:Victory()
	if self.State == "Reviewing" then return end
	self.State = "Reviewing"
	
	self:ClearAllEnemies()
	
	local clearTime = tick() - self.StartTime
	self:UpdateAllMissionLogs({
		Difficulty = self.RunData.Difficulty,
		Type = "Victory",
		Time = clearTime,
	})
	
	self:DoRewards()
	
	self:GetService("QuestService"):ProcessGameplayEventAll({
		Type = "CompleteMission",
		MissionId = self.RunData.MissionId,
	})
	
	self:GetService("EffectsService"):RequestEffectAll("Message", {
		Text = string.format("Victory!", self.Floor - 1)
	})
	wait(5)
	
	self.Active = false
	
	self:TryRecruitTrainingTeleport()
	
	self:Review("Victory ("..self:FormatTime(clearTime)..") "..self.RunData.Difficulty)
	
	self.Dungeon:Destroy()
	self:CleanConnections()
	self:EndFloorModifiers()
	
	self.Finished:Fire()
end

function Run:Defeat()
	if self.State == "Reviewing" then return end
	self.State = "Reviewing"
	
	self:ClearAllEnemies()
	
	self:UpdateAllMissionLogs({
		Difficulty = self.RunData.Difficulty,
		Type = "Defeat",
	})
	
	self:GetService("EffectsService"):RequestEffectAll("Message", {
		Text = string.format("Defeat...", self.Floor - 1)
	})
	wait(5)
	
	self.Active = false
	
	local clearTime = tick() - self.StartTime
	self:Review("Defeat ("..self:FormatTime(clearTime)..") "..self.RunData.Difficulty)
	
	self.Dungeon:Destroy()
	self:CleanConnections()
	self:EndFloorModifiers()
	
	-- okay, we're finished
	self.Finished:Fire()
end

function Run:GetPointsRequiredForExtraLife()
	return 100 + self.LivesEarned * 25
end

function Run:AddPoints(points)
	self.Points = self.Points + points
	
	local pointsRequired = self:GetPointsRequiredForExtraLife()
	if self.Points >= pointsRequired then
		self.Points = self.Points - pointsRequired
		self:AddExtraLife()
	end
end

function Run:PurgeAbsentPlayers()
	for index = #self.RespawnQueue, 1, -1 do
		local player = self.RespawnQueue[index]
		if player.Parent ~= game:GetService("Players") then
			table.remove(self.RespawnQueue, index)
		end
	end
end

function Run:DestroyLives()
	local duration = 3
	self:FireRemoteAll("LivesDestroyed", duration, self.Storage.Sounds.MagicEerie2)
	delay(duration, function()
		self.LivesRemaining = 0
	end)
end

function Run:AddExtraLife()
	self.LivesEarned = self.LivesEarned + 1
	self.LivesRemaining = self.LivesRemaining + 1
	
	self:PurgeAbsentPlayers()
	if #self.RespawnQueue > 0 then
		self.LivesRemaining = self.LivesRemaining - 1
		
		local player = table.remove(self.RespawnQueue, 1)
		local deathPosition
		if player.Character and player.Character.PrimaryPart then
			deathPosition = player.Character.PrimaryPart.Position
		end
		self:SpawnLegendForPlayer(player, deathPosition)
	end
	
	self.LifeEarned:Fire()
end

function Run:SpawnLegendForPlayer(player, deathPosition)
	if not (player and player.Parent) then return end
	
	player:LoadCharacter()
	local legend = self:CreateNew"Legend"{
		Model = player.Character,
		Player = player,
	}
	local spawnPosition = self.Dungeon:GetRespawnPosition(deathPosition)
	
	legend.Model:SetPrimaryPartCFrame(CFrame.new(spawnPosition))
	self:GetClass("AbilityWarCry"):PushEnemies(spawnPosition, 24)
	
	local function onLegendDied()
		local deathPosition = legend:GetPosition()
		
		wait(5)
		
		while self.State == "Transitioning" do
			wait()
		end
		
		-- don't respawn if we're not an active run
		if not self.Active then return end
		
		-- don't respawn if they are already alive
		if self:GetClass("Legend").DoesPlayerHaveLegend(player) then return end
		
		-- now decide if we have enough lives
		if self.LivesRemaining > 0 then
			if (player and player.Parent) then
				self.LivesRemaining = self.LivesRemaining - 1
				self:SpawnLegendForPlayer(player, deathPosition)
			end
		else
			if (player and player.Parent) then
				table.insert(self.RespawnQueue, player)
			end
			
			local remainingLegends = #self:GetClass("Legend").Instances
			if (remainingLegends <= 0) then
				self:Defeat()
			
			else
				if (player and player.Parent) then
					player:LoadCharacter()
					
					local specter = self:CreateNew"Specter"{
						Model = player.Character,
						Player = player
					}
					specter.Model:SetPrimaryPartCFrame(CFrame.new(legend:GetPosition()) + Vector3.new(0, 4, 0))
					
					self:GetWorld():AddObject(specter)
				end
			end
		end
	end
	self:AddConnection(legend.Died:Connect(onLegendDied))
	self:GetWorld():AddObject(legend)
	
	return legend
end

function Run:OnPlayerAdded(player)
	if self.State == "Reviewing" then return end
	
	if self.State == "Transitioning" then
		repeat wait() until self.State == "Running"
	end
	
	if self.RunData.MissionId then
		delay(10, function()
			if player.Parent ~= game:GetService("Players") then return end
			
			self:GetService("AnalyticsService"):AddProgressionEvent(player, self.RunData.MissionId, self.RunData.Difficulty or "Rookie", "Start")
			self:GetService("DataService"):UpdatePlayerMissionLog(player, {
				Difficulty = self.RunData.Difficulty,
				MissionId = self.RunData.MissionId,
				Type = "Attempt",
			})
		end)
	end
	
	self:ShowTitleForCurrentFloor(player, true)
	self:SpawnLegendForPlayer(player)
end

return Run