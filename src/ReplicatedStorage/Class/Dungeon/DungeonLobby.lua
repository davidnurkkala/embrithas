local Super = require(script.Parent)
local DungeonLobby = Super:Extend()

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

function DungeonLobby:OnCreated()
	self:GetService("LobbyService")
	
	Super.OnCreated(self)
	
	self:SetUpLighting()
	self:SetUpModel()
	self:SetUpDummies()
	self:SetUpMisc()
	self:SetUpLoreBooks()
	self:SetUpContest()
	
	local function onPlayerAdded(player)
		-- spawn this because getting player data may yield
		spawn(function()
			self:FireRemote("LobbyRequested", player, self.Model, self:GetService("DataService"):GetPlayerData(player), self.Run.RunData.IsTutorial)
		end)
	end
	game:GetService("Players").PlayerAdded:Connect(onPlayerAdded)
	for _, player in pairs(game.Players:GetPlayers()) do
		onPlayerAdded(player)
	end
end

function DungeonLobby:SetUpContest()
	local contest = self.Model.Contest
	
	local blueArea = contest.BlueArea
	local blueLanding = contest.BlueLanding
	
	local redArea = contest.RedArea
	local redLanding = contest.RedLanding
	
	local leaderboard = contest.Leaderboard
	leaderboard.Name = "ContestLeaderboard"
	leaderboard.Parent = self.Model
	
	contest.Parent = game:GetService("ServerStorage")
	
	local bluePlayers = {}
	local redPlayers = {}
	
	local cooldown = self:CreateNew"Cooldown"{Time = 15}
	
	local function updateLeaderboard()
		local function updateList(gui, page, format)
			for _, child in pairs(gui:GetChildren()) do
				if child.Name == "Frame" then
					child:Destroy()
				end
			end
			
			for rank, entry in pairs(page) do
				local userId = entry.key
				local name = Players:GetNameFromUserIdAsync(userId)
				local thumbnail = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
				
				local frame = gui.TemplateFrame:Clone()
				frame.Name = "Frame"
				frame.Visible = true
				frame.NameText.Text = name
				frame.Icon.Image = thumbnail
				frame.ValueText.Text = format(entry.value)
				frame.LayoutOrder = rank
				frame.Parent = gui
			end
		end
		
		local gui = leaderboard.Part.Gui
		local pages = self:GetService("DataService"):GetContestLeaderboard()
		updateList(gui.Plays.ContentFrame, pages.Plays, function(value) return string.format([[<b>%d</b>]], value) end)
		updateList(gui.Wins.ContentFrame, pages.Wins, function(value) return string.format([[<b>%d</b>]], value) end)
		updateList(gui.Ratio.ContentFrame, pages.Ratio, function(value) return string.format([[<b>%4.2f</b>]], value / 10000) end)
		
		delay(120, updateLeaderboard)
	end
	spawn(updateLeaderboard)
	
	local function isPlayerInZone(player, zone)
		local char = player.Character
		if not char then return end
		local root = char.PrimaryPart
		if not root then return end
		
		local position = zone.CFrame:PointToObjectSpace(root.Position)
		local inX = (position.X > -zone.Size.X / 2) and (position.X < zone.Size.X / 2)
		local inZ = (position.Z > -zone.Size.Z / 2) and (position.Z < zone.Size.Z / 2)
		return inX and inZ
	end
	
	local function convertToUserIds(playerList)
		local ids = {}
		for _, player in pairs(playerList) do
			table.insert(ids, player.UserId)
		end
		return ids
	end
	
	-- 52243 was here to witness the end 11/10/2020
	local function teleport()
		cooldown:Use()
		
		local teleportGui = self.Storage.UI.LoadingGui:Clone()
		teleportGui.TitleLabel.Text = "The Contest of Slayers"
		teleportGui.TipLabel.Text = "Prepare yourselves for combat, slayers!"
		
		local teleportData = {
			MissionId = "contestOfSlayers",
			Difficulty = "Rookie",
			
			Args = {
				Teams = {
					Red = convertToUserIds(redPlayers),
					Blue = convertToUserIds(bluePlayers),
				},
			},
		}
		
		local players = {}
		for _, player in pairs(bluePlayers) do
			table.insert(players, player)
		end
		for _, player in pairs(redPlayers) do
			table.insert(players, player)
		end
		self:GetService("DataService"):SaveGroupDataAsync(players)

		pcall(function()
			teleportData = self:GetService("AnalyticsService"):AddTeleportData(players, teleportData)
		end)

		for _, player in pairs(players) do
			teleportGui:Clone().Parent = player:FindFirstChild("PlayerGui")
		end

		local placeId = game.PlaceId
		local serverId = TeleportService:ReserveServer(placeId)
		TeleportService:TeleportToPrivateServer(placeId, serverId, players, nil, teleportData, teleportGui)
	end
	
	local function movePlayer(player, part)
		local char = player.Character
		if not char then return end
		local root = char.PrimaryPart
		if not root then return end
		
		root.CFrame = CFrame.new(part.Position + Vector3.new(0, 4, 0))
	end
	
	local function onUpdated(dt)
		if not cooldown:IsReady() then return end
		
		-- find out which players are where
		local players = Players:GetPlayers()
		
		for _, player in pairs(players) do
			local inBlue = isPlayerInZone(player, blueArea)
			if inBlue and #bluePlayers < 4 then
				movePlayer(player, blueLanding)
				table.insert(bluePlayers, player)
			end
			
			local inRed = isPlayerInZone(player, redArea)
			if inRed and #redPlayers < 4 then
				movePlayer(player, redLanding)
				table.insert(redPlayers, player)
			end
			
			local escapeZones = contest.EscapeZones:GetChildren()
			local escaped = false
			for _, escapeZone in pairs(escapeZones) do
				if isPlayerInZone(player, escapeZone) then
					movePlayer(player, contest.QuitZone)
					escaped = true
				end
			end
			if escaped then
				local index do
					index = table.find(bluePlayers, player)
					if index then
						table.remove(bluePlayers, index)
					end

					index = table.find(redPlayers, player)
					if index then
						table.remove(redPlayers, index)
					end
				end
			end
		end
		
		for index, bluePlayer in pairs(bluePlayers) do
			if not table.find(players, bluePlayer) then
				table.remove(bluePlayers, index)
				break
			end
		end
		
		for index, redPlayer in pairs(redPlayers) do
			if not table.find(players, redPlayer) then
				table.remove(redPlayers, index)
				break
			end
		end
		
		-- teleport if we have full teams
		local blueCount = #bluePlayers
		local redCount = #redPlayers
		if blueCount == 4 and redCount == 4 then
			teleport()
		end
	end
	
	self:CreateNew"Timeline"{
		Infinite = true,
		Interval = 0.5,
		OnTicked = function(t, dt)
			onUpdated(dt)
		end,
	}:Start()
end

function DungeonLobby:SetUpMisc()
	self:GetService("MusicService"):PlayPlaylist{"City of Peace"}
	
	workspace.Terrain:PasteRegion(self.Model.TerrainRegion, workspace.Terrain.MaxExtents.Min, true)
	
	for _, npc in pairs(self.Model.NPCs:GetChildren()) do
		npc.AnimationController:LoadAnimation(npc.Idle):Play()
	end
	
	spawn(function()
		local chat = game:GetService("Chat")
		while true do
			chat:Chat(self.Model.NPCs.Guard2.Head, "I've heard they started doing the Contest of Slayers over at the docks again.")
			chat:Chat(self.Model.NPCs.Instructor.Head, "Slayers, I can re-train you to refund your stat points.")
			wait(30)
		end
	end)
end

function DungeonLobby:SetUpLoreBooks()
	local dataService = self:GetService("DataService")
	
	local function giveLoreOnTouched(part, loreId)
		local function onTouched(part)
			local legend = self:GetClass("Legend").GetLegendFromPart(part)
			if not legend then return end
			
			dataService:UnlockLore(legend.Player, loreId)
		end
		part.Touched:Connect(onTouched)
	end
	
	giveLoreOnTouched(self.Model.LoreBookOrder, "theOrderOfPurifiers")
	giveLoreOnTouched(self.Model.LoreBookCollege, "theCollegeOfReclamation")
	giveLoreOnTouched(self.Model.LoreBookValor, "theLeagueOfValor")
end

function DungeonLobby:SetUpLighting()
	local lighting = game:GetService("Lighting")
	lighting.Brightness = 2
	
	lighting:ClearAllChildren()
	self.Storage.Models.OutdoorSky:Clone().Parent = lighting
end

function DungeonLobby:SetUpModel()
	local model = self.Storage.CustomDungeons.lobby:Clone()
	model.Name = "Dungeon"
	self.Model = model
	
	-- get a start room
	local startArea = model.StartArea
	startArea.Parent = nil
	
	self.StartRoom = {
		GetSpawn = function()
			local corner = -startArea.Size / 2
			local position = corner + Vector3.new(
				startArea.Size.X * math.random(),
				0,
				startArea.Size.Z * math.random()
			)
			return startArea.CFrame:PointToWorldSpace(position)
		end
	}
	
	-- we're good
	model.Parent = workspace
end

-- fire_king66 was here 10/19/2020
function DungeonLobby:MakeDangerous(enemy)
	spawn(function()
		while true do
			enemy:AttackCircle{
				Position = enemy:GetFootPosition(),
				Radius = 6,
				Duration = 1,
				OnHit = function(legend)
					self:GetService("DamageService"):Damage{
						Source = enemy,
						Target = legend,
						Amount = math.min(legend.MaxHealth:Get() * 0.1, legend.Health - 1),
						Type = "Psychic",
					}
				end,
			}

			wait(3)
		end
	end)
end

function DungeonLobby:SetUpDummies()
	for _, child in pairs(self.Model.Dummies:GetChildren()) do
		self:SetUpDummy(child)
	end
	
	local part = self.Model.DangerDummy
	part.Parent = nil
	
	local enemy = self:SpawnEnemy(part, "Training Dummy", CFrame.Angles(0, math.pi * 2 * math.random(), 0), 1)
	enemy.Resilient = true
	
	enemy.OnWillTakeDamage = function(self, damage)
		enemy:GetSuper().OnWillTakeDamage(enemy, damage)
		
		enemy.MaxHealth.Base = damage.Amount + 1
	end
	
	enemy.OnDamaged = function(self, damage)
		enemy.Health = enemy.MaxHealth:Get()
	end
	
	enemy.Name = "Danger Dummy"
	delay(1, function()
		enemy.Root.Anchored = true
	end)
	self:MakeDangerous(enemy)
end
function DungeonLobby:SetUpDummy(part)
	part.Parent = nil
	
	local level = 0
	if part.Name == "Easy" then
		level = 10
	elseif part.Name == "Medium" then
		level = 100
	elseif part.Name == "Hard" then
		level = 1000
	elseif part.Name == "Immortal" then
		level = 1
	end
	
	local isImmortal = part.Name == "Immortal"
	local isDangerous = part:FindFirstChild("Dangerous")
	
	local spawnEnemy
	spawnEnemy = function()
		local enemy = self:SpawnEnemy(part, "Training Dummy", CFrame.Angles(0, math.pi * 2 * math.random(), 0), level)
		enemy.Died:Connect(function()
			wait(3)
			spawnEnemy()
		end)
		
		local damages = {}
		local dpsTime = 10
		enemy.OnDamaged = function(enemy, damage)
			table.insert(damages, damage.Amount)
			delay(dpsTime, function() table.remove(damages, 1) end)
			
			if isImmortal then
				enemy.Health = enemy.MaxHealth:Get()
			end
		end
		if isImmortal then
			enemy.OnWillTakeDamage = function(self, damage)
				enemy.MaxHealth.Base = damage.Amount + 1
			end
			delay(1, function()
				enemy.Root.Anchored = true
			end)
		end
		local onUpdated = enemy.OnUpdated
		enemy.OnUpdated = function(enemy, dt)
			onUpdated(enemy, dt)
			
			local dpsTotal = 0
			for _, damage in pairs(damages) do
				dpsTotal = dpsTotal + damage
			end
			enemy.Name = "DPS: "..(math.floor(dpsTotal / dpsTime * 100) / 100)
		end
		
		if isDangerous then
			self:MakeDangerous(enemy)
		end
	end
	spawnEnemy()
end

function DungeonLobby:SpawnEnemy(part, name, offset, level)
	local spawnCFrame = (part.CFrame + Vector3.new(0, 4, 0)) * offset
	
	local enemy = self:GetService("EnemyService"):CreateEnemy(name, level){
		StartCFrame = spawnCFrame
	}
	
	self:GetWorld():AddObject(enemy)
	
	return enemy
end

function DungeonLobby:Destroy()
	self.Active = false
	self.Model:Destroy()
end

function DungeonLobby:Explode()
	self:GetService("EffectsService"):RequestEffectAll("ExplodeDungeon", {Model = self.Model})
	game:GetService("Debris"):AddItem(self.Model, 2)
end

return DungeonLobby