local Super = require(script.Parent)
local DungeonTutorial = Super:Extend()

function DungeonTutorial:OnCreated()
	Super.OnCreated(self)
	
	game:GetService("Lighting").Brightness = 1
	game:GetService("Lighting").OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
	
	self:GetClass("Legend").SprintDisabled = true
	
	self:SetUpModel()
	
	local door1Locked = true
	local function onTutorialUpdated(self, player, step)
		if step == 1 then
			self:GetLegend().AbilityActivated:Wait()
			self:FireRemote("TutorialUpdated", self:GetPlayer(), 1.1)
		elseif step == 1.1 then
			door1Locked = false
		elseif step == 3 then
			self.Step3Received = true
		elseif step == 3.1 then
			self.Step3_1Received = true
		elseif step == 4.1 then
			self.CorruptionDialogueFinished = true
		end
	end
	self:ConnectRemote("TutorialUpdated", onTutorialUpdated, true)
	
	delay(2.5, function()
		self:FireRemote("TutorialUpdated", self:GetPlayer(), 1)
	end)
	
	-- door 1
	local dummySpawns = {}
	for _, part in pairs(self.Model.DummySpawns:GetChildren()) do
		table.insert(dummySpawns, part)
	end
	self.Model.DummySpawns.Parent = nil
	
	local door1 = self:SetUpDoor(self.Model.Door1, function()
		local enemies = {}
		
		for _, part in pairs(dummySpawns) do
			local enemy = self:SpawnEnemy(part, "Training Dummy")
			enemy:FaceTowards(self.StartRoom:GetSpawn())
			table.insert(enemies, enemy)
		end
		
		self:FireRemote("TutorialUpdated", self:GetPlayer(), 2)
		
		local function areEnemiesDead()
			for _, enemy in pairs(enemies) do
				if enemy.Active then
					return false
				end
			end
			return true
		end
		
		spawn(function()
			while not areEnemiesDead() do wait() end
			self:DangerZoneTutorial()
		end)
	end)
	door1.Locked = function()
		return door1Locked
	end
	
	-- door 2
	local crystalSpawns = self.Model.CrystalSpawns:GetChildren()
	self.Model.CrystalSpawns.Parent = nil
	
	self.DangerZoneTutorialFinished = false
	self.CorruptionDialogueFinished = false
	
	local door2 = self:SetUpDoor(self.Model.Door2, function()
		for _ = 1, 15 do
			local part = crystalSpawns[math.random(1, #crystalSpawns)]
			local corner = -part.Size / 2
			local position = corner + Vector3.new(
				part.Size.X * math.random(),
				0,
				part.Size.Z * math.random()
			)
			position = part.CFrame:PointToWorldSpace(position)
			
			self:CreateNew"CorruptionCrystal"{
				StartCFrame = CFrame.new(position) * CFrame.Angles(
					0,
					math.random() * math.pi * 2,
					math.random() * math.pi / 4
				),
				StartParent = self.Model,
			}
		end
		
		self:GetRun().LifeEarned:Connect(function()
			self:FireRemote("TutorialUpdated", self:GetPlayer(), 5)
		end)
	end)
	door2.Locked = function()
		return (self.DangerZoneTutorialFinished == false) or (self.CorruptionDialogueFinished == false)
	end
	
	-- door 3
	local enemyDead = false
	local enemySpawn = self.Model.EnemySpawn
	enemySpawn.Parent = nil
	local door3 = self:SetUpDoor(self.Model.Door3, function()
		local enemy = self:SpawnEnemy(enemySpawn, "Orc")
		enemy.MaxHealth.Base = 250
		enemy.Health = enemy.MaxHealth:Get()
		enemy.Damage = 2.5
		enemy.Name = "Captive Orc"
		repeat wait() until not enemy.Active
		self:FireRemote("TutorialUpdated", self:GetPlayer(), 6)
		enemyDead = true
	end)
	door3.Locked = function()
		return self:GetRun().LivesRemaining < 4
	end
	
	-- door 4
	local door4 = self:SetUpDoor(self.Model.Door4, function()
		local player = self:GetPlayer()
		
		self.Completed:Fire()
	end)
	door4.Locked = function()
		return enemyDead == false
	end
end

function DungeonTutorial:DangerZoneTutorial()
	self:FireRemote("TutorialUpdated", self:GetPlayer(), 3)
	
	local hackEnemy = self:SpawnEnemy(workspace.Terrain, "Training Dummy")
	spawn(function()
		repeat wait() until self.Step3Received
		self:FireRemote("TutorialUpdated", self:GetPlayer(), 3.1)
		
		for _ = 1, 5 do
			hackEnemy:AttackCircle{
				Position = self:GetLegend():GetFootPosition(),
				Radius = 8,
				Duration = 1,
				OnHit = function(legend)
					-- do nothing
				end,
			}
			wait(1.5)
		end
		
		repeat wait() until self.Step3_1Received
		
		local dodges = 0
		while dodges < 3 do
			local clock = 2
			dodges = dodges + 1
			hackEnemy:AttackCircle{
				Position = self:GetLegend():GetFootPosition(),
				Radius = 8,
				Duration = 1,
				OnHit = function(legend)
					dodges = 0
					clock = 6
					self:FireRemote("TutorialUpdated", self:GetPlayer(), 3.2)
				end,
			}
			repeat clock = clock - wait() until clock <= 0
		end
		
		self:FireRemote("TutorialUpdated", self:GetPlayer(), 4)
		self.DangerZoneTutorialFinished = true
	end)
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

function DungeonTutorial:SpawnEnemy(part, name)
	local spawnCFrame = part.CFrame + Vector3.new(0, 4, 0)
	
	local enemy = self:GetService("EnemyService"):CreateEnemy(name, 1){
		StartCFrame = spawnCFrame
	}
	
	local onDestroyed = part:FindFirstChild("OnDestroyed") 
	if onDestroyed then
		enemy.Destroyed:Connect(function()
			self:DoEvent(onDestroyed)
		end)
	end
	
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