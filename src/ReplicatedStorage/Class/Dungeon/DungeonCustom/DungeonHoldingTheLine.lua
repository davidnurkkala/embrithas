local Super = require(script.Parent)
local DungeonHoldingTheLine = Super:Extend()

function DungeonHoldingTheLine:OnCreated()
	Super.OnCreated(self)
	
	self:InitSpawnArea()
	
	self.Wave = 1
	
	delay(10, function()
		self:Start()
		self:DoWave()
	end)
end

function DungeonHoldingTheLine:DoWave()
	local finishedDeploying = false
	
	local count = 50
	local timeBetweenEnemies = 2
	local enemies = {}
	
	self:GetService("EffectsService"):RequestEffectAll("TextFeedback", {
		Duration = 1,
		TextArgs = {
			Text = string.format("-- Wave %s --", self.Wave),
		}
	})
	
	local function onFinished()
		wait(15)
		
		self.Wave += 1
		self:DoWave()
	end
	
	local function checkWaveCompletion()
		if not finishedDeploying then return end
		
		for _, enemy in pairs(enemies) do
			if enemy.Active then
				return
			end
		end
		
		onFinished()
	end
	
	for _ = 1, count do
		local enemy = self:SpawnEnemy()
		table.insert(enemies, enemy)
		enemy.Destroyed:Connect(function()
			checkWaveCompletion()
		end)
		wait(timeBetweenEnemies)
	end
	
	finishedDeploying = true
	checkWaveCompletion()
end

function DungeonHoldingTheLine:GetEnemyLevel()
	return 100 + (self.Wave - 1) * 5
end

function DungeonHoldingTheLine:GetPointInPart(part)
	local dx = part.Size.X * math.random() - part.Size.X / 2
	local dz = part.Size.Z * math.random() - part.Size.Z / 2
	local p = part.CFrame:PointToWorldSpace(Vector3.new(dx, 0, dz))
	return p
end

function DungeonHoldingTheLine:InitSpawnArea()
	self.SpawnArea = self.Model.SpawnArea
	self.SpawnArea.Parent = nil
end

function DungeonHoldingTheLine:SpawnEnemy(name)
	local position = self:GetPointInPart(self.SpawnArea) + Vector3.new(0, 4, 0)
	
	local enemyService = self:GetService("EnemyService")
	local enemy = enemyService:CreateEnemy(name or self.Run:RequestEnemy(), self:GetEnemyLevel()){
		StartCFrame = CFrame.new(position),
	}
	enemyService:ApplyDifficultyToEnemy(enemy)
	self:GetWorld():AddObject(enemy)
	
	local duration = 0.5
	
	enemy:AddStatus("StatusStunned", {Time = duration})
	
	self:TweenNetwork{
		Object = enemy.Root,
		Goals = {
			CFrame = enemy.Root.CFrame + Vector3.new(0, 0, -64),
		},
		Style = Enum.EasingStyle.Linear,
		Duration = duration,
	}
	
	return enemy
end

return DungeonHoldingTheLine