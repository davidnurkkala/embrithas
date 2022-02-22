local Super = require(script.Parent)
local RoomGranular = Super:Extend()

function RoomGranular:OnCreated()
	Super.OnCreated(self)
	
	assert(self.RoomTileGroup)
end

function RoomGranular:InitSpawns()
	self.Spawns = {}
	
	for _, tile in pairs(self.RoomTileGroup.Tiles) do
		if (not tile.Occupied) and (not tile.SpawnDisabled) then
			table.insert(self.Spawns, Vector3.new(
				tile.Position.X * self.Dungeon.TileSize,
				0,
				tile.Position.Y * self.Dungeon.TileSize
			))
		end
	end
end

function RoomGranular:GetSpawn(useSpawn)
	local index = self.Dungeon.Random:NextInteger(1, #self.Spawns)
	if useSpawn then
		return table.remove(self.Spawns, index)
	else
		return self.Spawns[index]
	end
end

function RoomGranular:GetEnemySpawnCFrame()
	local position = self:GetSpawn() + Vector3.new(0, 8, 0)
	return CFrame.new(position) * CFrame.Angles(0, math.pi * 2 * math.random(), 0)
end

function RoomGranular:HasLivingEnemies()
	for _, enemy in pairs(self.Enemies) do
		if enemy.Active or enemy.Resurrecting then
			return true
		end
	end
	return false
end

function RoomGranular:HasUncompletedFloorItems()
	for _, floorItem in pairs(self.FloorItems) do
		if floorItem.CanBeCompleted and (not floorItem.IsCompleted) then
			return true
		end
	end
	return false
end

function RoomGranular:LoadEncounter(data)
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

function RoomGranular:CreateGuaranteedFloorItems()
	for _, tile in pairs(self.RoomTileGroup.Tiles) do
		if tile.FloorItems then
			for _, data in pairs(tile.FloorItems) do
				local className
				local args = {}
				if typeof(data) == "string" then
					className = data
				elseif typeof(data) == "table" then
					className = data.Type
					for key, val in pairs(data) do
						if key ~= "Type" then
							args[key] = val
						end
					end
				end
				
				local position = Vector3.new(tile.Position.X, 0, tile.Position.Y) * self.Dungeon.TileSize
				
				args.StartCFrame = CFrame.new(position)
				args.StartParent = self.Dungeon.Model
				args.Room = self
				
				local floorItem = self:CreateNew(className)(args)
				
				if floorItem.CanBeCompleted then
					table.insert(self.FloorItems, floorItem)
					floorItem.Completed:Connect(function()
						self:CheckForCompletion()
					end)
				end
			end
		end
	end
end

function RoomGranular:CreateFloorItemSet()
	-- check guaranteed spawns first
	self:CreateGuaranteedFloorItems()
	
	-- now check the randomized ones
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
				StartCFrame = CFrame.new(self:GetSpawn()),
				StartParent = self.Dungeon.Model,
				Room = self,
			}
			if floorItem.CanBeCompleted then
				table.insert(self.FloorItems, floorItem)
				floorItem.Completed:Connect(function()
					self:CheckForCompletion()
				end)
			end
		end
	end
end

function RoomGranular:CheckForCompletion()
	if self:HasUncompletedFloorItems() then return end
	if self:HasLivingEnemies() then return end
	
	self:Complete()
end

function RoomGranular:AddEnemy(enemy)
	enemy.Room = self
	table.insert(self.Enemies, enemy)
	enemy.Destroyed:Connect(function()
		self:CheckForCompletion()
	end)
end

function RoomGranular:Activate()
	if self.State ~= "Inactive" then return end
	self.State = "Active"
	
	-- load the encounter for this room
	local encounterData = self.EncounterData or self:GetDefaultEncounterData()
	
	-- set up a datastructure to handle enemies, then
	-- load encounters into the room
	self.Enemies = {}
	
	self:LoadEncounter(encounterData)
	
	-- now prepare to complete if our enemies are destroyed
	local function onEnemyDestroyed()
		self:CheckForCompletion()
	end
	
	for _, enemy in pairs(self.Enemies) do
		enemy.Room = self
		self:GetService("EnemyService"):ApplyDifficultyToEnemy(enemy)
		enemy.Destroyed:Connect(onEnemyDestroyed)
		self:GetWorld():AddObject(enemy)
	end
	
	-- back to placeholder stuff
	local treasures = {}
	for treasureNumber = 1, math.random(1, 8) do
		local spawnPosition = self:GetSpawn()
		
		self:CreateNew"CorruptionCrystal"{
			StartCFrame = CFrame.new(spawnPosition) * CFrame.Angles(
				0,
				math.random() * math.pi * 2,
				math.random() * math.pi / 4
			),
			StartParent = self.Dungeon.Model,
		}
	end
	
	self:CreateFloorItemSet()
	
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

return RoomGranular