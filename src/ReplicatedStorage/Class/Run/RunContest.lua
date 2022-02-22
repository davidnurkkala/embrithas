local Super = require(script.Parent)
local RunContest = Super:Extend()

local Players = game:GetService("Players")

RunContest.StarterEnemies = {"Skeleton", "Orc", "Animated Construct"}
RunContest.StarterEnemyCount = 10

RunContest.Colors = {
	Blue = Color3.new(0.8, 0.8, 1),
	Red = Color3.new(1, 0.8, 0.8),
}

RunContest.BrickColors = {
	Blue = BrickColor.new("Steel blue"),
	Red = BrickColor.new("Dusty Rose"),
}

RunContest.Purchases = {
	[1] = {
		Enemy = {"Skeleton", "Orc", "Animated Construct", "Orc Bulwark"},
		AdvancedEnemy = {"Bone Archer", "Orc Archer", "Projected Construct", "Mystic Shadow", "Orc Miner", "Orc Sapper"},
		Modifier = {"Empowering", "Restorative"},
	},
	[2] = {
		Enemy = {"Orc Brute", "Skeleton Warrior", "Armored Shadow", "Shadow Warrior", "Zombie", "Orc Shaman"},
		AdvancedEnemy = {"Orc Berserker", "Raging Shadow", "Fiery Corruption"},
		Modifier = {"Resilient", "Mortar"},
	},
	[3] = {
		Enemy = {"Zombie Defender", "Stone Corruption", "Terrorknight"},
		AdvancedEnemy = {"Ghost", "Terrorknight Jailor"},
		Modifier = {"Electric", "Missile"},
	},
	[4] = {
		Enemy = {"Imprisoned One", "Frozen Corruption"},
		AdvancedEnemy = {"Terrorknight Summoner"},
		Modifier = {"Explosive"},
	}
}
RunContest.PurchaseTypesWeightTable = {
	Enemy = 3,
	AdvancedEnemy = 2,
	Modifier = 1,
}
RunContest.ImagesByPurchaseType = {
	Enemy = "rbxassetid://5680449433",
	AdvancedEnemy = "rbxassetid://5680449513",
	Modifier = "rbxassetid://5680449337",
}
RunContest.WaveSizeDivisor = 1.5

function RunContest:OnCreated()
	-- mostly for offline testing
	if not self.RunData.Teams then
		self.RunData.Teams = {
			Red = {676056, -1},
			Blue = {-2},
		}
	end
	
	-- now to the actual code
	Super.OnCreated(self)
	
	local starterEnemy = self:Choose(self.StarterEnemies)
	self.Waves = {
		Red = {[starterEnemy] = self.StarterEnemyCount},
		Blue = {[starterEnemy] = self.StarterEnemyCount},
	}
	self.Modifiers = {
		Red = {},
		Blue = {},
	}
	self.WaveNumber = 1
	
	self:InitObjectives()
	self:InitBoosters()
	
	self.BloodShardsByPlayer = {}
	self.PlayerTiers = {}
	self:CreateNew"Timeline"{
		Infinite = true,
		OnUpdated = function(t)
			for _, player in pairs(Players:GetPlayers()) do
				self:FireRemote("BloodShardsUpdated", player, {
					Type = "Update",
					Amount = self.BloodShardsByPlayer[player] or 0
				})
				self:FireRemote("ContestHealthUpdated", player, {
					Type = "Update",
					RatioBlue = self.Objectives.Blue.Health / self.Objectives.Blue.MaxHealth:Get(),
					RatioRed = self.Objectives.Red.Health / self.Objectives.Red.MaxHealth:Get(),
				})
			end
			
			local objectivesAlive = true
			for _, objective in pairs(self.Objectives) do
				if not objective.Active then
					t:Stop()
				end
			end
		end,
		OnEnded = function()
			for _, player in pairs(Players:GetPlayers()) do
				self:FireRemote("BloodShardsUpdated", player, {Type = "Hide"})
				self:FireRemote("ContestHealthUpdated", player, {Type = "Hide"})
			end
			self:FinishGame()
		end
	}:Start()
	
	delay(10, function()
		self:DoWave()
	end)
end

function RunContest:FinishGame()
	for _, object in pairs(self:GetWorld().Objects) do
		if object:IsA(self:GetClass("Enemy")) then
			object.Active = false
		end
	end
	
	self.State = "Reviewing"
	
	local winner, loser
	if self.Objectives.Blue.Active then
		winner = "Blue"
		loser = "Red"
	else
		winner = "Red"
		loser = "Blue"
	end
	
	local players = Players:GetPlayers()
	local message = string.format("%s team wins!", winner)
	local playerCount = #players
	local legitGame = (playerCount == 8) or (game:GetService("RunService"):IsStudio())
	if not legitGame then
		message ..= "\n"
		message ..= [[<font size="16"><i>No rewards or records since this was not a match of 4 vs 4.</i></font>]]
	end
	
	self:FireRemoteAll("AnnouncementRequested", message)
	
	if legitGame then
		local teams = self.RunData.Teams
		local dataService = self:GetService("DataService")
		local inventoryService = self:GetService("InventoryService")
		
		for _, player in pairs(players) do
			if table.find(teams[winner], player.UserId) then
				dataService:UpdateContestLeaderboard(player, true)
				inventoryService:AddItem(player, "Materials", {Id = 3, Amount = 3})
			else
				dataService:UpdateContestLeaderboard(player, false)
				inventoryService:AddItem(player, "Materials", {Id = 3, Amount = 1})
			end
		end
	end
	
	wait(15)
	
	self.Dungeon:Destroy()
	self:CleanConnections()
	self:EndFloorModifiers()

	-- okay, we're finished
	self.Finished:Fire()
end

-- bubbley552 was here for the end 11/10/2020
function RunContest:InitObjectives()
	self.Objectives = {}
	
	for _, model in pairs(self.Dungeon.Model.Worldstones:GetChildren()) do
		model.Parent = workspace
		
		local ally = self:CreateNew"Ally"{
			Model = model,
			Name = "Worldstone",
			Level = 100,
			OnDied = function(ally)
				ally:SetCollisionGroup("Debris")
				
				ally.Model.UpperTorso:Destroy()
				ally.Root.CanCollide = true
				ally.Root.Anchored = false
				ally.Root:ClearAllChildren()
				ally.Root.Velocity = Vector3.new(0, 128, 0)
				ally.Root.RotVelocity = Vector3.new(ally:RandomFloat(-32, 32), 0, ally:RandomFloat(-32, 32))
				
				local e = Instance.new("Explosion")
				e.BlastPressure = 0
				e.Position = ally.Root.Position
				e.Parent = workspace
				
				ally:SoundPlayByObject(ally.Storage.Sounds.Explosion1)
				
				delay(5, function()
					ally.Root.CanCollide = false
				end)
				
				ally:Deactivate()
				ally.StatusGui:Destroy()
				ally.Died:Fire()
			end,
		}
		ally.MaxHealth.Base = 10000
		ally.Health = ally.MaxHealth:Get()
		self:GetWorld():AddObject(ally)
		
		self.Objectives[model.Name] = ally
	end
end

function RunContest:InitBoosters()
	local Enemy = self:GetClass("Enemy")
	
	for _, booster in pairs(self.Dungeon.Model.Boosts:GetChildren()) do
		booster.Touched:Connect(function(part)
			local enemy = Enemy.GetEnemyFromPart(part)
			if not enemy then return end
			
			self:BoostEnemy(enemy)
		end)
	end
end

function RunContest:BoostEnemy(enemy)
	if enemy.BonusBloodShards then return end
	
	local attachment = self.Storage.Models.Attachments.BonusBloodShardAttachment:Clone()
	attachment.Parent = enemy.Root
	spawn(function() attachment.Emitter:Emit(1) end)
	enemy.BonusBloodShards = 1
	
	enemy.Died:Connect(function()
		attachment:Destroy()
	end)
end

function RunContest:GetPointInPart(part)
	local corner = -part.Size / 2
	local dx = part.Size.X * math.random()
	local dy = part.Size.Y
	local dz = part.Size.Z * math.random()
	return part.CFrame:PointToWorldSpace(corner + Vector3.new(dx, dy, dz))
end

function RunContest:SpawnEnemy(team, enemyName, modifiers)
	local zone = self.Dungeon.Model.EnemySpawnZones[team]
	local position = self:GetPointInPart(zone) + Vector3.new(0, 6, 0)
	
	local enemyService = self:GetService("EnemyService")
	local enemy = enemyService:CreateEnemy(enemyName, 100, false){
		NoExperience = true,
		StartCFrame = CFrame.new(position),
	}
	self:GetWorld():AddObject(enemy)
	
	local effects = self:GetService("EffectsService")
	effects:RequestEffectAll("Sound", {
		Position = enemy:GetPosition(),
		Sound = self.Storage.Sounds.CastDark,
	})
	effects:RequestEffectAll("AirBlast", {
		Position = enemy:GetPosition(),
		Color = Color3.fromRGB(61, 21, 133),
		Radius = 8,
		Duration = 0.25,
	})
	
	if modifiers[1] then
		local modifier = table.remove(modifiers, 1)
		enemy:AddModifier(modifier)
	end
	
	return enemy
end

function RunContest:PullEnemyFromWave(wave)
	local names = {}
	for name, count in pairs(wave) do
		table.insert(names, name)
	end
	if #names == 0 then
		return nil
	end
	local name = self:Choose(names)
	wave[name] -= 1
	if wave[name] <= 0 then
		wave[name] = nil
	end
	return name
end

function RunContest:SendMessage(players, message, color)
	for _, player in pairs(players) do
		self:GetService("EffectsService"):RequestEffect(player, "ChatMessage", {
			Text = message,
			Color = color or Color3.new(1, 1, 1),
			TextSize = 14,
		})
	end
end

function RunContest:DoWave()
	local message = string.format("Wave %d", self.WaveNumber)
	if self.WaveNumber == 1 then
		message ..= "\n"
		message ..= [[<font size="16" color="rgb(255, 204, 204)"><i>Allow enemies to cross the red line for bonus Blood Shards</i></font>]]
	end
	self:FireRemoteAll("AnnouncementRequested", message)
	
	local tMax = 30
	local t = tMax
	
	local waveBlue = self:DeepCopy(self.Waves.Blue)
	local countBlue = 0
	for _, count in pairs(waveBlue) do
		countBlue += count
	end
	local tBlue = tMax / countBlue
	
	local waveRed = self:DeepCopy(self.Waves.Red)
	local countRed = 0
	for _, count in pairs(waveRed) do
		countRed += count
	end
	local tRed = tMax / countRed
	
	local modifiersBlue = self:DeepCopy(self.Modifiers.Blue)
	self:Shuffle(modifiersBlue)
	local modifiersRed = self:DeepCopy(self.Modifiers.Red)
	self:Shuffle(modifiersRed)
	
	local clockBlue = 0
	local clockRed = 0
	
	local blueEnemies = {}
	local redEnemies = {}
	
	while t > 0 do
		local dt = wait()
		if self.State ~= "Running" then break end
		t -= dt
		
		clockBlue += dt
		while clockBlue > tBlue do
			clockBlue -= tBlue
			
			local name = self:PullEnemyFromWave(waveBlue)
			if name then
				table.insert(blueEnemies, self:SpawnEnemy("Blue", name, modifiersBlue))
			end
		end
		
		clockRed += dt
		while clockRed > tRed do
			clockRed -= tRed
			
			local name = self:PullEnemyFromWave(waveRed)
			if name then
				table.insert(redEnemies, self:SpawnEnemy("Red", name, modifiersRed))
			end
		end
	end
	
	local function enemiesDead(enemies)
		for _, enemy in pairs(enemies) do
			if enemy.Active then
				return false
			end
		end
		return true
	end
	
	local event = Instance.new("BindableEvent")
	
	local blueDone = false
	spawn(function()
		repeat wait() until enemiesDead(blueEnemies)
		blueDone = true
		event:Fire()
		
		if self.State ~= "Running" then return end
		
		local waveSize = self:GetWaveSize(self.Waves.Red)
		local amount = math.floor(waveSize / self.WaveSizeDivisor)
		self:AddBloodShardsToTeam("Blue", amount)
		self:SendMessage(self:GetPlayersOnTeam("Blue"), string.format("Earned %d bonus Blood Shards for sending %d enemies at the other team.", amount, waveSize))
		
		self:PromptPlayersForUpgrades(self:GetPlayersOnTeam("Blue"))
	end)
	
	local redDone = false
	spawn(function()
		repeat wait() until enemiesDead(redEnemies)
		redDone = true
		event:Fire()
		
		if self.State ~= "Running" then return end
		
		local waveSize = self:GetWaveSize(self.Waves.Blue)
		local amount = math.floor(waveSize / self.WaveSizeDivisor)
		self:AddBloodShardsToTeam("Red", amount)
		self:SendMessage(self:GetPlayersOnTeam("Red"), string.format("Earned %d bonus Blood Shards for sending %d enemies at the other team.", amount, waveSize))
		
		self:PromptPlayersForUpgrades(self:GetPlayersOnTeam("Red"))
	end)
	
	while not (redDone and blueDone) do
		event.Event:Wait()
	end
	
	if self.State == "Running" then
		wait(15)
	end
	
	self:CancelUpgradePrompts()
	
	if self.State == "Running" then
		self.WaveNumber += 1
		self:DoWave()
	end
end

function RunContest:GetWaveSize(wave)
	local size = 0
	for name, count in pairs(wave) do
		size += count
	end
	return size
end

function RunContest:CancelUpgradePrompts()
	for _, player in pairs(Players:GetPlayers()) do
		spawn(function()
			self.Storage.Remotes.PromptContest:InvokeClient(player, {Cancel = true})
		end)
	end
end

function RunContest:PromptPlayersForUpgrades(players)
	for _, player in pairs(players) do
		spawn(function()
			self:PromptPlayerForUpgrade(player)
		end)
	end
end

function RunContest:PromptPlayerForUpgrade(player)
	local rerolls = 0
	local purchases = 0
	
	local lastResult = ""
	
	while (lastResult ~= "Finish") and (lastResult ~= "Cancel") do
		local tier = self.PlayerTiers[player] or 1
		local canUpgrade = tier < #self.Purchases
		
		local upgradeCost = tier * 60
		local rerollCost = 4 + rerolls * 2
		
		local options = {}
		
		for index = 1, 4 do
			local purchaseType = self:GetWeightedResult(self.PurchaseTypesWeightTable)
			
			local cost = 4
			if purchaseType == "AdvancedEnemy" then
				cost = 6
			elseif purchaseType == "Modifier" then
				cost = 8
			end
			cost += purchases * 2
			cost += (tier - 1) * 2
			
			local name = self:Choose(self.Purchases[tier][purchaseType])
			
			local description
			if purchaseType == "Enemy" then
				description = "Adds this enemy into the other team's waves from here on out."
			elseif purchaseType == "AdvancedEnemy" then
				description = "Adds this advanced enemy into the other team's waves from here on out."
			elseif purchaseType == "Modifier" then
				description = "An enemy will spawn with this modifier in each of the other team's waves."
			end
			
			options[index] = {
				Name = name,
				Type = (purchaseType == "AdvancedEnemy") and "Advanced Enemy" or purchaseType,
				Description = description,
				Cost = cost,
				Image = self.ImagesByPurchaseType[purchaseType],
			}
		end
		
		local args = {
			Currency = self.BloodShardsByPlayer[player] or 0,
			UpgradeCost = upgradeCost,
			RerollCost = rerollCost,
			Options = options,
			CanUpgrade = canUpgrade,
		}
		
		lastResult = self.Storage.Remotes.PromptContest:InvokeClient(player, args)
		
		local function processOption(option)
			local myTeam = self:GetTeamFromPlayer(player)
			local enTeam = self:GetOtherTeam(myTeam)
			
			if (option.Type == "Enemy") or (option.Type == "Advanced Enemy") then
				local wave = self.Waves[enTeam]
				wave[option.Name] = (wave[option.Name] or 0) + 1
				
				self:SendMessage(
					self:GetPlayersOnTeam(myTeam),
					string.format("%s is sending a(n) %s to the enemy team!", player.Name, option.Name),
					self.Colors.Blue
				)
				self:SendMessage(
					self:GetPlayersOnTeam(enTeam),
					string.format("%s is sending a(n) %s at your team!", player.Name, option.Name),
					self.Colors.Red
				)
				
			elseif (option.Type == "Modifier") then
				local modifiers = self.Modifiers[enTeam]
				table.insert(modifiers, option.Name)
				
				self:SendMessage(
					self:GetPlayersOnTeam(myTeam),
					string.format("%s has added a(n) %s modifier to the other team!", player.Name, option.Name),
					self.Colors.Blue
				)
				self:SendMessage(
					self:GetPlayersOnTeam(enTeam),
					string.format("%s is adding a(n) %s modifier to your team!", player.Name, option.Name),
					self.Colors.Red
				)
			end
			
			purchases += 1
			self.BloodShardsByPlayer[player] -= option.Cost
		end
		
		if lastResult == "Reroll" then
			rerolls += 1
			self.BloodShardsByPlayer[player] -= rerollCost
			
		elseif lastResult == "Upgrade" then
			self.PlayerTiers[player] = (self.PlayerTiers[player] or 1) + 1
			self.BloodShardsByPlayer[player] -= upgradeCost
			
		elseif lastResult == "Option1" then
			processOption(options[1])
		elseif lastResult == "Option2" then
			processOption(options[2])
		elseif lastResult == "Option3" then
			processOption(options[3])
		elseif lastResult == "Option4" then
			processOption(options[4])
		end
	end
end

function RunContest:GetPlayersOnTeam(team)
	local players = {}
	for _, player in pairs(Players:GetPlayers()) do
		if self:GetTeamFromPlayer(player) == team then
			table.insert(players, player)
		end
	end
	return players
end

function RunContest:GetTeamFromPlayer(player)
	local teams = self.RunData.Teams
	if table.find(teams.Red, player.UserId) then
		return "Red"
	else
		return "Blue"
	end
end

function RunContest:GetOtherTeam(team)
	if team == "Blue" then
		return "Red"
	else
		return "Blue"
	end
end

function RunContest:GetTeamFromLegend(legend)
	return self:GetTeamFromPlayer(legend.Player)
end

function RunContest:TeleportLegendToArena(legend)
	local zone = self.Dungeon.Model.PlayerSpawnZones[self:GetTeamFromLegend(legend)]
	legend.Root.CFrame = CFrame.new(zone.Position + Vector3.new(0, 4, 0))
end

function RunContest:AddBloodShardsToTeam(team, amount)
	for _, player in pairs(self:GetPlayersOnTeam(team)) do
		self:AddBloodShardsToPlayer(player, amount)
	end
end

function RunContest:AddBloodShardsToPlayer(player, amount)
	self.BloodShardsByPlayer[player] = (self.BloodShardsByPlayer[player] or 0) + amount
end

function RunContest:SpawnLegendForPlayer(player, deathPosition)
	self.LivesRemaining = 10
	
	local legend = Super.SpawnLegendForPlayer(self, player, deathPosition)
	legend.Level = 100
	
	local team = self:GetTeamFromPlayer(player)
	player.Team = game:GetService("Teams"):FindFirstChild(team)
	
	legend.DefeatedEnemy:Connect(function(enemy)
		self:AddBloodShardsToPlayer(player, 1)
		
		local bonusShards = 1 + (enemy.BonusBloodShards or 0)
		for _ = 1, bonusShards do
			local poorest = nil
			local poorestAmount = math.huge
			for _, teammate in pairs(self:GetPlayersOnTeam(team)) do
				local amount = self.BloodShardsByPlayer[teammate] or 0
				if amount < poorestAmount then
					poorest = teammate
					poorestAmount = amount
				end
			end
			self:AddBloodShardsToPlayer(poorest, 1)
		end
	end)
	
	local pause = self.WaveNumber - 1
	local function teleport()
		self:TeleportLegendToArena(legend)
	end
	if pause > 0 then
		delay(pause, teleport)
	else
		teleport()
	end
end

return RunContest