local function init(self)
	local spawnArea = self.Model.EnemySpawnArea
	
	local function spawnEnemy()
		local sx = spawnArea.Size.X / 2
		local sz = spawnArea.Size.Z / 2
		local dx = self:RandomFloat(-sx, sx)
		local dz = self:RandomFloat(-sz, sz)
		local dy = 4
		local position = spawnArea.CFrame:PointToWorldSpace(Vector3.new(dx, dy, dz))
		local cframe = CFrame.new(position) * CFrame.Angles(0, math.pi * 2 * math.random(), 0)
		
		local enemyService = self:GetService("EnemyService")
		local enemy = enemyService:CreateEnemy(self:GetRun():RequestEnemy(), self.Level){
			StartCFrame = cframe
		}
		enemyService:ApplyDifficultyToEnemy(enemy)
		self:GetWorld():AddObject(enemy)
		
		enemy.Root.CFrame += Vector3.new(0, 64, 0)
		self:TweenNetwork{
			Object = enemy.Root,
			Goals = {CFrame = cframe},
			Duration = 2,
			Direction = Enum.EasingDirection.In,
		}
	end
	
	local function spawnWave()
		for _ = 1, 14 do
			delay(2 * math.random(), spawnEnemy)
		end
	end
	
	local waveCount = 15
	local waveDuration = 15
	local finalClearTime = 15
	
	local totalTime = (waveDuration * waveCount) + finalClearTime
	local currentTime = 0
	
	local function pause(duration)
		while duration > 0 do
			local dt = wait()
			duration -= dt
			currentTime += dt
			
			self.Model.Progress.Value = currentTime / totalTime
		end
	end
	
	spawn(function()
		for waveNumber = 1, waveCount do
			pause(waveDuration)
			if not self.Active then return end
			
			spawnWave()
		end
		pause(finalClearTime)
		if not self.Active then return end
		
		self.Completed:Fire()
	end)
end

return init