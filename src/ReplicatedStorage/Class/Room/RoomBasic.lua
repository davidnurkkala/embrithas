local CollectionService = game:GetService("CollectionService")

local Super = require(script.Parent)
local Room = Super:Extend()

local CLASSES_WITH_ENABLED = {
	"PointLight",
	"SurfaceLight",
	"SpotLight",
	"Fire",
	"Smoke",
	"Sparkles",
	"ParticleEmitter",
}

local DEBUG = false

function Room:OnCreated()
	Super.OnCreated(self)
	
	assert(self.CFrame)
	assert(self.Model)
	assert(self.GridData)
	
	self.FloorItems = {}
	self.Features = {}
	self.Enemies = {}
	
	self.Model:SetPrimaryPartCFrame(self.CFrame)
	self.Model.PrimaryPart:Destroy()
	
	self:SetModelEffects(false)
	
	self:InitFeatures()
	
	self.Model.Parent = self.Dungeon.Model
	
	self:CreateSpawnLocations()
end

function Room:CreateSpawnLocations()
	local size = Vector3.new(62, 0, 62)
	local position = self.CFrame.Position
	
	local maxY = position.Y + 2
	local minY = position.Y - 2
	local scanLength = 32
	
	local startX = position.X - (size.X / 2)
	local startZ = position.Z - (size.Z / 2)
	
	local steps = 12
	local stepSizeX = size.X / steps
	local stepSizeZ = size.Z / steps
	local floorPoints = {}
	
	local function shouldIgnore(part)
		return (not part.CanCollide) or CollectionService:HasTag(part, "DungeonSpawnIgnored") or (not part:IsDescendantOf(self.Model))
	end
	
	for xStep = 0, steps do
		for zStep = 0, steps do
			local dx = xStep * stepSizeX
			local dz = zStep * stepSizeZ
			
			local x = startX + dx
			local z = startZ + dz
			local y = position.Y + (scanLength / 2)
			
			local ray = Ray.new(Vector3.new(x, y, z), Vector3.new(0, -scanLength, 0))
			
			local part, point = self:Raycast(ray, {}, shouldIgnore)
			
			if (part ~= nil) and (point.Y <= maxY) and (point.Y >= minY) then
				table.insert(floorPoints, point)
			end
		end
	end
	
	local spawnPoints = {}
	local wiggle = 0.25
	
	local function isAreaClear(min, max)
		local granularity = 5
		
		for stepX = 0, granularity do
			for stepZ = 0, granularity do
				local wx = stepX / granularity
				local wz = stepZ / granularity
				
				local x = self:Lerp(min.X, max.X, wx)
				local z = self:Lerp(min.Z, max.Z, wz)
				local y = max.Y
				
				local ray = Ray.new(Vector3.new(x, y, z), Vector3.new(0, min.Y - max.Y, 0))
				local _, point = self:Raycast(ray, {}, shouldIgnore)
				
				local deltaY = math.abs(min.Y - point.Y)
				if deltaY > 2 then
					return false
				end
			end
		end
		
		return true
	end
	
	for _, point in pairs(floorPoints) do
		local min = point + Vector3.new(
			-stepSizeX / 2 + wiggle,
			wiggle,
			-stepSizeZ / 2 + wiggle
		)
		local max = point + Vector3.new(
			stepSizeX / 2 - wiggle,
			wiggle + scanLength,
			stepSizeZ / 2 - wiggle
		)
		
		if isAreaClear(min, max) then
			table.insert(spawnPoints, point)
		end
	end
	
	local spawns = Instance.new("Folder")
	spawns.Name = "Spawns"
	spawns.Parent = self.Model
	self.Spawns = spawns
	
	local usedSpawns = Instance.new("Folder")
	usedSpawns.Name = "UsedSpawns"
	usedSpawns.Parent = self.Model
	self.UsedSpawns = usedSpawns
	
	for _, point in pairs(spawnPoints) do
		local val = Instance.new("Vector3Value")
		val.Value = point
		val.Name = tostring(point)
		val.Parent = self.Spawns
		
		if DEBUG then
			local p = Instance.new("Part")
			p.Size = Vector3.new(0.5, 0.5, 0.5)
			p.Color = Color3.new(1, 0, 1)
			p.Anchored = true
			p.Position = point
			p.Parent = self.Model
		end
	end
end

function Room:SetModelEffects(state)
	for _, desc in pairs(self.Model:GetDescendants()) do
		for _, class in pairs(CLASSES_WITH_ENABLED) do
			if desc:IsA(class) then
				desc.Enabled = state
				break
			end
		end
	end
end

function Room:GetSpawn(useSpawn)
	if useSpawn == nil then useSpawn = true end
	
	local spawns = self.Spawns:GetChildren()
	if #spawns == 0 then
		spawns = self.UsedSpawns:GetChildren()
		
		if #spawns == 0 then
			return self.Model.PrimaryPart.Position
		end
	end
	
	local chosenSpawn = spawns[math.random(1, #spawns)]
	if useSpawn then
		chosenSpawn.Parent = self.UsedSpawns
	end
	return chosenSpawn.Value
end

function Room:InitFeatures()
	local features = self.Model:FindFirstChild("__Features")
	if not features then return end
	
	for _, feature in pairs(features:GetChildren()) do
		table.insert(self.Features, self:CreateNew"DungeonFeatureBasic"{
			Model = feature,
			Room = self,
		})
	end
end

function Room:ActivateFeatures()
	for _, feature in pairs(self.Features) do
		feature:Activate()
	end
end

function Room:ActivateSafeFeatures()
	for _, feature in pairs(self.Features) do
		if feature:IsSafe() then
			feature:Activate()
		end
	end
end

function Room:AddEnemy(enemy)
	enemy.Room = self
	table.insert(self.Enemies, enemy)
	enemy.Destroyed:Connect(function()
		self:CheckForCompletion()
	end)
end

function Room:ActivateEncounter()
	self:LoadEncounter(self.EncounterData or self:GetDefaultEncounterData())
	
	local enemyService = self:GetService("EnemyService")
	
	local function onEnemyDestroyed()
		self:CheckForCompletion()
	end
	
	for _, enemy in pairs(self.Enemies) do
		enemy.Room = self
		enemyService:ApplyDifficultyToEnemy(enemy)
		enemy.Destroyed:Connect(onEnemyDestroyed)
		self:GetWorld():AddObject(enemy)
	end
end

function Room:CreateFloorItemSet()
	local sets, weights = self:GetService("GameService").CurrentRun:GetFloorItemSetData()
	if not sets then return end

	local name = self:GetWeightedResult(weights)
	if name == "None" then return end
	local set = sets[name]

	for className, amount in pairs(set) do
		if typeof(amount) == "table" then
			amount = self.Dungeon.Random:NextInteger(amount[1], amount[2])
		end

		for _ = 1, amount do
			local floorItem = self:CreateNew(className){
				StartCFrame = CFrame.new(self:GetSpawn(true)),
				StartParent = self.Dungeon.Model,
				Room = self,
			}
			if floorItem.CanBeCompleted then
				self:AddFloorItem(floorItem)
				floorItem.Completed:Connect(function()
					self:CheckForCompletion()
				end)
			end
		end
	end
end

function Room:Activate()
	if self.State ~= "Inactive" then return end
	self.State = "Active"
	
	self:SetModelEffects(true)
	self:ActivateEncounter()
	self:ActivateFeatures()
	
	-- create corruption crystals
	for _ = 1, math.random(1, 8) do
		local spawnPosition = self:GetSpawn()
		
		self:CreateNew"CorruptionCrystal"{
			StartCFrame = CFrame.new(spawnPosition) * CFrame.Angles(
				0,
				math.random() * math.pi * 2,
				math.random() * math.pi / 4
			),
			StartParent = self.Model,
		}
	end
	
	-- create floor items
	self:CreateFloorItemSet()
	
	-- potentially spawn gold
	if self.Dungeon.GoldEnabled then
		for _ = 1, math.random(1, 10) do
			local spawnCFrame = CFrame.new(self:GetSpawn()) * CFrame.Angles(0, math.pi * 2 * math.random(), 0) + Vector3.new(0, 0.5, 0)
			local amount = math.random(1, math.max(1, self.Dungeon.Level))

			local difficulty = self.Dungeon.Run:GetDifficultyData()
			if difficulty.LootChance then
				amount = math.max(1, amount * difficulty.LootChance)
			end

			amount = math.floor(amount + 0.5)

			self:CreateNew"GoldCoins"{
				StartCFrame = spawnCFrame,
				StartParent = self.Dungeon.Model,
				Amount = amount,
			}
		end
	end
	
	-- potentially create chests
	if self.Dungeon.ChestsEnabled and (math.random() <= self.Dungeon.ChestChance) then
		local spawnPosition = self:GetSpawn()
		self:CreateNew"TreasureChest"{
			Room = self,
			StartCFrame = CFrame.new(spawnPosition + Vector3.new(0, 1, 0)) * CFrame.Angles(0, math.pi * 2 * math.random(), 0),
			StartParent = self.Dungeon.Model,
		}
	end
	
	self.Activated:Fire()
end

function Room:AddFloorItem(floorItem)
	table.insert(self.FloorItems, floorItem)
end

function Room:GetEnemySpawnCFrame()
	local position = self:GetSpawn() + Vector3.new(0, 8, 0)
	return CFrame.new(position) * CFrame.Angles(0, math.pi * 2 * math.random(), 0)
end

function Room:LoadEncounter(data)
	local enemyService = self:GetService("EnemyService")

	if data.Type == "Mob" then
		for _ = 1, data.Count do
			local enemy = enemyService:CreateEnemy(
				data.Enemy or self.Dungeon.Run:RequestEnemy(),
				self:GetLevelFromEncounter(data)
			){
				StartCFrame = self:GetEnemySpawnCFrame(),
				HealthMultiplier = data.HealthMultiplier or 1,
			}
			
			table.insert(self.Enemies, enemy)
		end

	elseif data.Type == "EnemySet" then
		local set = data.Set

		local index = 1
		while index <= #set do
			local name = set[index]
			local count = 1

			index += 1
			if typeof(set[index]) == "number" then
				count = set[index]
				index += 1
			end

			for _ = 1, count do
				local enemy = enemyService:CreateEnemy(name, self:GetLevelFromEncounter(data)){
					StartCFrame = self:GetEnemySpawnCFrame(),
				}
				
				table.insert(self.Enemies, enemy)
			end
		end

	elseif data.Type == "Elite" then
		local enemy = enemyService:CreateEnemy(
			data.Enemy or self.Dungeon.Run:RequestEnemy(),
			self:GetLevelFromEncounter(data)
		){
			StartCFrame = self:GetEnemySpawnCFrame()
		}

		enemyService:MakeEnemyElite(enemy)
		table.insert(self.Enemies, enemy)

	elseif data.Type == "Lore" then
		local spawnCFrame = CFrame.new(self:GetSpawn()) * CFrame.Angles(0, math.pi * 2 * math.random(), 0) * CFrame.Angles(0, 0, math.pi / 2) + Vector3.new(0, 0.5, 0)

		self:CreateNew"LoreBook"{
			StartCFrame = spawnCFrame,
			StartParent = self.Dungeon.Model,
			LoreId = data.LoreId,
		}

		self:LoadEncounter(self:GetDefaultEncounterData())

	elseif data.Type == "Multi" then
		for _, encounter in pairs(data.Encounters) do
			self:LoadEncounter(encounter)
		end
	end
end

function Room:HasLivingEnemies()
	for _, enemy in pairs(self.Enemies) do
		if enemy.Active then
			return true
		end
	end
	return false
end

function Room:HasUncompletedFloorItems()
	for _, floorItem in pairs(self.FloorItems) do
		if floorItem.CanBeCompleted and (not floorItem.IsCompleted) then
			return true
		end
	end
	return false
end

function Room:CheckForCompletion()
	if self:HasUncompletedFloorItems() then return end
	if self:HasLivingEnemies() then return end

	self:Complete()
end

return Room