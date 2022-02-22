local Super = require(script.Parent)
local TrapSpawner = Super:Extend()

TrapSpawner.TimeToDie = 10
TrapSpawner.MaxEnemiesSpawned = 3

function TrapSpawner:OnCreated()
	-- set up our model for becoming an enemy
	self.Model.PrimaryPart = self.Model.__SpawnPart
	
	Instance.new("AnimationController", self.Model)
	
	-- create the enemy
	local enemy = self:CreateNew"Enemy"{
		Model = self.Model,
		Name = self.Model.Name,
		StartCFrame = self.Model:GetPrimaryPartCFrame(),
		Undefendable = true,
		Resilient = true,
	}
	
	-- set up the enemy's stats properly
	local level = self.Room.Dungeon.Level
	enemy.Level = level
	
	local enemyService = self:GetService("EnemyService")
	local maxHealth = enemyService:GetHealthFromTimeToDie(self.TimeToDie, level)
	enemy.MaxHealth.Base = maxHealth
	enemy.Health = enemy.MaxHealth:Get()
	
	-- add the enemy to the world
	self.Room:AddEnemy(enemy)
	self:GetWorld():AddObject(enemy)
	
	-- keep track of the enemy
	self.Enemy = enemy
	
	-- determine what enemies we're spawning
	local enemies = self.Model:GetAttribute("Enemies")
	if enemies then
		self.EnemyNames = string.split(enemies, "|")
	end
	
	self.Enemies = {}
	
	-- start spawner
	self:SpawnEnemy()
end

function TrapSpawner:GetSpawnCFrame()
	return CFrame.new(self.Enemy:GetPosition()) * CFrame.Angles(0, math.pi * 2 * math.random(), 0)
end

function TrapSpawner:CanSpawnEnemy()
	for index = #self.Enemies, 1, -1 do
		local enemy = self.Enemies[index]
		if not enemy.Active then
			table.remove(self.Enemies, index)
		end
	end
	return #self.Enemies < self.MaxEnemiesSpawned
end

function TrapSpawner:SpawnEnemy()
	if not self.Enemy.Active then return end
	
	if self:CanSpawnEnemy() then
		local name
		if self.EnemyNames then
			name = self:Choose(self.EnemyNames)
		else
			name = self.Room.Dungeon.Run:RequestEnemy()
		end
		
		local enemyService = self:GetService("EnemyService")
		local enemy = enemyService:CreateEnemy(name, self.Room.Dungeon.Level){
			StartCFrame = self:GetSpawnCFrame()
		}
		enemyService:ApplyDifficultyToEnemy(enemy)
		self:GetWorld():AddObject(enemy)
		
		self.Room:AddEnemy(enemy)
		
		table.insert(self.Enemies, enemy)
	end
	
	delay(1 / self.SpawnRate, function()
		self:SpawnEnemy()
	end)
end

return TrapSpawner