local Super = require(script.Parent)
local DungeonTutorial = Super:Extend()

function DungeonTutorial:OnCreated()
	Super.OnCreated(self)
	
	self:SetUpModel()
	self:GetClass("ThemeMachine"):SetUpLighting()
	self:GetService("MusicService"):PlayPlaylist{"Classic Suspense"}
	
	local door1, door2, door3, door4, door5
	
	local room1Spawns = self:GetSpawns(self.Model.Room1)
	local room1Clear = false
	door1 = self:SetUpDoor(self.Model.Door1, function()
		self:GetService("MusicService"):PlayPlaylist{"Classic Action"}
		
		local enemies = {}
		
		for _, point in pairs(room1Spawns) do
			table.insert(enemies, self:SpawnEnemy(point, "Orc"))
		end
		
		local function enemiesAlive()
			for _, enemy in pairs(enemies) do
				if enemy.Active then
					return true
				end
			end
			return false
		end
		
		spawn(function()
			while enemiesAlive() do wait() end
			room1Clear = true
			self:Step(3, {Door = door2.Root})
		end)
		
		self:Step(2)
	end)
	
	local room2Spawns = self:GetSpawns(self.Model.Room2)
	local room2Clear = false
	door2 = self:SetUpDoor(self.Model.Door2, function()
		local enemies = {}
		
		for _, point in pairs(room2Spawns) do
			table.insert(enemies, self:SpawnEnemy(point, "Orc"))
		end

		local function enemiesAlive()
			for _, enemy in pairs(enemies) do
				if enemy.Active then
					return true
				end
			end
			return false
		end

		spawn(function()
			while enemiesAlive() do wait() end
			room2Clear = true
			
			self:Step(5, {Door = door3.Root})
		end)
		
		self:Step(4)
	end)
	door2.Locked = function()
		return (not room1Clear)
	end
	
	local crystalSpawns = self:GetSpawns(self.Model.CrystalSpawns)
	door3 = self:SetUpDoor(self.Model.Door3, function()
		for _, point in pairs(crystalSpawns) do
			self:CreateNew"CorruptionCrystal"{
				StartCFrame = CFrame.new(point),
				StartParent = self.Model,
			}
		end
		
		self:Step(6, {Door = door4.Root})
	end)
	door3.Locked = function()
		return (not room2Clear)
	end
	
	local eliteSpawn = self.Model.EliteSpawn.Position
	self.Model.EliteSpawn:Destroy()
	
	local lastRoomClear = false
	
	door4 = self:SetUpDoor(self.Model.Door4, function()
		local enemy = self:SpawnEnemy(eliteSpawn, "Orc")
		self:GetService("EnemyService"):MakeEnemyElite(enemy)
		
		spawn(function()
			while enemy.Active do wait() end
			lastRoomClear = true
			
			self:Step(8, {Door = door5.Root})
		end)
		
		self:Step(7)
	end)
	door4.Locked = function()
		return false
	end
	
	door5 = self:SetUpDoor(self.Model.Door5, function()
		self:Step(9)
		
		self.Completed:Fire()
	end)
	door5.Locked = function()
		return (not lastRoomClear)
	end
	
	self:InitSprintCheck()
	
	self:ConnectRemote("TutorialUpdated", function(self)
		self:Step(1, {Door = door1.Root})
	end, true)
end

function DungeonTutorial:InitSprintCheck()
	local zoneCFrame = self.Model.SprintDangerZone.CFrame
	local zoneSize = self.Model.SprintDangerZone.Size
	self.Model.SprintDangerZone:Destroy()
	
	local resetPoint = self.Model.SprintResetPoint.Position + Vector3.new(0, 3, 0)
	self.Model.SprintResetPoint:Destroy()
	
	local dummy = self:CreateNew"Character"{
		Model = workspace,
		Name = "sprint check",
		Telegraphs = {},
	}
	
	local duration = 1.75
	local pause = 1.75
	
	local function cycle()
		self:GetClass("Enemy").AttackSquare(dummy, {
			CFrame = zoneCFrame,
			Width = zoneSize.X,
			Length = zoneSize.Z,
			Duration = duration,
			OnHit = function(legend)
				local mover = Instance.new("BodyPosition")
				mover.MaxForce = Vector3.new(1e9, 1e9, 1e9)
				mover.Position = resetPoint
				mover.Parent = legend.Root
				game:GetService("Debris"):AddItem(mover, 2)
			end,
			Sound = self.Storage.Sounds.Silence,
		})
		delay(pause, cycle)
	end
	
	cycle()
end

function DungeonTutorial:Step(step, data)
	self:FireRemote("TutorialUpdated", self:GetPlayer(), step, data)
end

function DungeonTutorial:GetSpawns(model)
	local points = {}
	for _, child in pairs(model:GetChildren()) do
		table.insert(points, child.Position)
	end
	model:Destroy()
	return points
end

function DungeonTutorial:GetPlayer()
	local Players = game:GetService("Players")
	return Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
end

function DungeonTutorial:GetLegend()
	return self:GetClass("Legend").GetLegendFromPlayer(self:GetPlayer())
end

function DungeonTutorial:SetUpModel()
	local model = self.Storage.CustomDungeons.tutorial:Clone()
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
	
	-- terrain
	workspace.Terrain:PasteRegion(self.Model.TerrainRegion, workspace.Terrain.MaxExtents.Min, true)
	
	-- we're good
	model.Parent = workspace
end

function DungeonTutorial:SetUpDoor(model, onOpened)
	-- this is an awful hack and I hate you future David
	local rooms = {{Activate = onOpened}}
	
	local door = self:CreateNew"Door"{
		Model = model,
		CFrame = model:GetPrimaryPartCFrame(),
		Dungeon = self,
		Rooms = rooms,
		
		Locked = function()
			return false
		end,
	}
	
	return door
end

function DungeonTutorial:SpawnEnemy(point, name)
	local spawnCFrame = CFrame.new(point) + Vector3.new(0, 4, 0)
	
	local enemy = self:GetService("EnemyService"):CreateEnemy(name, 1){
		StartCFrame = spawnCFrame,
		NoExperience = true,
	}
	
	self:GetWorld():AddObject(enemy)
	
	return enemy
end

function DungeonTutorial:Destroy()
	self.Active = false
	self.Model:Destroy()
end

function DungeonTutorial:Explode()
	self:GetService("EffectsService"):RequestEffectAll("ExplodeDungeon", {Model = self.Model})
	game:GetService("Debris"):AddItem(self.Model, 2)
end

return DungeonTutorial