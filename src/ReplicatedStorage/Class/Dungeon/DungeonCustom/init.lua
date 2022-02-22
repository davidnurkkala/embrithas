local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Super = require(script.Parent)
local DungeonCustom = Super:Extend()

function DungeonCustom:OnCreated()
	Super.OnCreated(self)
	
	self:SetUpModel()
	self:InitLighting()
	self:InitTerrain()
	self:InitScripts()
	
	local onStarted = self.Model:FindFirstChild("OnStarted")
	if onStarted then
		delay(1, function()
			self:Start()
		end)
		self:DoEvent(onStarted)
	end
end

function DungeonCustom:InitScripts()
	if self.Model:FindFirstChild("ClientScript") then
		local function onPlayerAdded(player)
			self:FireRemote("ClientScriptRequested", player, self.Model.ClientScript)
		end
		self:AddConnection(Players.PlayerAdded:Connect(onPlayerAdded))
		for _, player in pairs(Players:GetPlayers()) do
			onPlayerAdded(player)
		end
	end
	
	if self.Model:FindFirstChild("ServerScript") then
		require(self.Model.ServerScript)(self)
	end
	
	if self.FloorScript then
		local function onPlayerAdded(player)
			self:FireRemote("ClientFloorScriptRequested", player, self.FloorScript, self.Model)
		end
		self:AddConnection(Players.PlayerAdded:Connect(onPlayerAdded))
		for _, player in pairs(Players:GetPlayers()) do
			onPlayerAdded(player)
		end
		
		require(self.FloorScript).Server(self)
	end
end

function DungeonCustom:InitTerrain()
	local terrain = self.Model:FindFirstChild("Terrain")
	if terrain then
		for _, part in pairs(terrain:GetChildren()) do
			workspace.Terrain:FillBlock(part.CFrame, part.Size, part.Name)
			part:Destroy()
		end
	end
	
	self.PreviousTerrainSettings = {}
	local terrainSettings = self.Model:FindFirstChild("TerrainSettings")
	if terrainSettings then
		for _, setting in pairs(terrainSettings:GetChildren()) do
			self.PreviousTerrainSettings[setting.Name] = workspace.Terrain[setting.Name]
			workspace.Terrain[setting.Name] = setting.Value
		end
	end
	
	if self.Model:FindFirstChild("TerrainRegion") then
		workspace.Terrain:PasteRegion(self.Model.TerrainRegion, workspace.Terrain.MaxExtents.Min, true)
	end
end

function DungeonCustom:InitLighting()
	self:GetClass("ThemeMachine"):SetUpLighting()
	
	local model = self.Model
	local lighting = game:GetService("Lighting")
	
	if model:FindFirstChild("SkyboxName") then
		lighting:ClearAllChildren()
		self.Storage.Models:FindFirstChild(model.SkyboxName.Value):Clone().Parent = lighting
	end
	
	self.PreviousLightingSettings = {}
	if model:FindFirstChild("Lighting") then
		for _, valueObject in pairs(model.Lighting:GetChildren()) do
			self.PreviousLightingSettings[valueObject.Name] = lighting[valueObject.Name]
			lighting[valueObject.Name] = valueObject.Value
		end
	end
end

function DungeonCustom:SetUpModel()
	local model = self.Storage.CustomDungeons:FindFirstChild(self.DungeonId):Clone()
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
	
	-- set up doors
	if model:FindFirstChild("Doors") then
		for _, doorModel in pairs(model.Doors:GetChildren()) do
			self:SetUpDoor(doorModel)
		end
	end
	
	-- collision groups
	local physicsService = game:GetService("PhysicsService")
	for _, object in pairs(self.Model:GetDescendants()) do
		if object:IsA("BasePart") then
			if (not physicsService:CollisionGroupContainsPart("Debris", object)) then
				physicsService:SetPartCollisionGroup(object, "Dungeon")
			end
			
			if CollectionService:HasTag(object, "Hidden") then
				object.Transparency = 1
				object.CanCollide = false
			end
		end
	end
	
	-- we're good
	model.Parent = workspace
	
	-- set up breakables
	if model:FindFirstChild("Breakables") then
		for _, breakable in pairs(model.Breakables:GetChildren()) do
			self:GetClass("DungeonFeature"):SetUpBreakable(breakable, breakable.PrimaryPart)
		end
	end
end

function DungeonCustom:SetUpDoor(model)
	-- this is an awful hack and I hate you future David
	local rooms = {}

	local event = model:FindFirstChild("OnOpened")
	if event then
		event.Parent = nil
		local function onOpened()
			self:DoEvent(event)
		end
		rooms = {{Activate = onOpened}}
	end
	
	local door = self:CreateNew"Door"{
		Model = model,
		CFrame = model:GetPrimaryPartCFrame(),
		Dungeon = self,
		Rooms = rooms,
		
		Locked = function()
			return false
		end,
	}
end

function DungeonCustom:DoEvent(event)
	if not self.Active then return end
	
	local eventData = {
		Enemies = {},
		PostCallbacks = {},
	}
	
	for _, object in pairs(event:GetChildren()) do
		self["Event"..object.Name](self, object, eventData)
	end
	
	for _, callback in pairs(eventData.PostCallbacks) do
		callback()
	end
end

function DungeonCustom:EventOnEnemiesSlain(event, eventData)
	table.insert(eventData.PostCallbacks, function()
		local function onDestroyed()
			for _, enemy in pairs(eventData.Enemies) do
				if enemy.Active then
					return
				end
			end
			
			-- only executed if all enemies are inactive
			self:DoEvent(event)
		end
		
		for _, enemy in pairs(eventData.Enemies) do
			enemy.Destroyed:Connect(onDestroyed)
		end
	end)
end

function DungeonCustom:EventSpawnEnemy(part, eventData)
	local name = part.EnemyName.Value
	local spawnCFrame = part.CFrame + Vector3.new(0, 8, 0)
	
	local args = {
		StartCFrame = spawnCFrame,
	}
	if part:FindFirstChild("Args") then
		for _, object in pairs(part.Args:GetChildren()) do
			args[object.Name] = object.Value
		end
	end
	
	local enemy = self:GetService("EnemyService"):CreateEnemy(name, self.Level)(args)
	
	if part:FindFirstChild("DisplayName") then
		enemy.Name = part.DisplayName.Value
	end
	
	if part:FindFirstChild("HealthMultiplier") then
		enemy.MaxHealth.Base *= part.HealthMultiplier.Value
		enemy.Health = enemy.MaxHealth:Get()
	end
	
	if part:FindFirstChild("AttackPatternStart") and enemy.AttackPattern then
		enemy.AttackPattern.Index = part.AttackPatternStart.Value
	end
	
	local onDestroyed = part:FindFirstChild("OnDestroyed") 
	if onDestroyed then
		enemy.Destroyed:Connect(function()
			self:DoEvent(onDestroyed)
		end)
	end
	
	self:GetWorld():AddObject(enemy)
	
	table.insert(eventData.Enemies, enemy)
end

function DungeonCustom:EventCompleteDungeon()
	self.Completed:Fire()
end

function DungeonCustom:EventDialogue(folder)
	self:GetService("EffectsService"):RequestEffectAll("Dialogue", {
		Name = folder:FindFirstChild("Name").Value,
		Image = folder.Image.Value,
		Text = folder.Text.Value,
	})
end

function DungeonCustom:EventTimer(object)
	delay(object.Value, function()
		self:DoEvent(object)
	end)
end

function DungeonCustom:CleanUp()
	self.Active = false
	
	self:CleanConnections()
	
	-- terrain
	workspace.Terrain:Clear()
	for setting, value in pairs(self.PreviousTerrainSettings) do
		workspace.Terrain[setting] = value
	end
	
	-- lighting
	local lighting = game:GetService("Lighting")
	for setting, value in pairs(self.PreviousLightingSettings) do
		lighting[setting] = value
	end
end

function DungeonCustom:Destroy()
	self.Model:Destroy()
	
	self:CleanUp()
end

function DungeonCustom:Explode()
	self:GetService("EffectsService"):RequestEffectAll("ExplodeDungeon", {Model = self.Model})
	game:GetService("Debris"):AddItem(self.Model, 2)
	
	self:CleanUp()
end

return DungeonCustom