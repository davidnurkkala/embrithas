local Players = game:GetService("Players")

return function (self)
	self:GetService("MusicService"):PlayPlaylist(require(self.Storage.Music.Playlists.GenericDungeon))
	
	local captain = self.Model.Captain
	captain.AnimationController:LoadAnimation(captain.Idle):Play()
	
	local splashEmitter = self.Storage.Emitters.SplashEmitter
	local enemyService = self:GetService("EnemyService")
	
	local function getPointInPart(part)
		local dx = part.Size.X * math.random() - part.Size.X / 2
		local dz = part.Size.Z * math.random() - part.Size.Z / 2
		local p = part.CFrame:PointToWorldSpace(Vector3.new(dx, 0, dz))
		return p
	end
	
	local function getSpawnLocation()
		local valid =
			self.Model and
			self.Model:FindFirstChild("SpawnAreas") and
			#self.Model.SpawnAreas:GetChildren() > 0
		if not valid then
			return Vector3.new()
		end
		
		local part = self:Choose(self.Model.SpawnAreas:GetChildren())
		return getPointInPart(part)
	end
	
	local function getLandingPosition(dy)
		local part = self.Model.LandingArea
		return getPointInPart(part) + Vector3.new(0, dy, 0)
	end
	
	local function jump(enemy, position)
		enemy:FaceTowards(position)
		
		local a = enemy:GetPosition()
		local c = position
		local b = (a + c) / 2 + Vector3.new(0, 32, 0)
		
		local duration = 1
		
		enemy:AddStatus("StatusStunned", {
			Time = duration,
		})
		
		self:CreateNew"Timeline"{
			Time = duration,
			OnStarted = function()
				enemy.Root.Anchored = true
			end,
			OnTicked = function(t)
				local w = t:GetProgress()
				local ab = self:Lerp(a, b, w)
				local bc = self:Lerp(b, c, w)
				local p = self:Lerp(ab, bc, w)
				local root = enemy.Root
				local delta = p - root.Position
				root.CFrame += delta
			end,
			OnEnded = function()
				enemy.Root.Anchored = false
				enemy.StartCFrame = CFrame.new(position)
			end,
		}:Start()
	end
	
	local spawnedEnemies = {}
	
	local function spawnEnemy(name)
		local position = getSpawnLocation()
		
		-- emitter
		local attachment = Instance.new("Attachment")
		attachment.Parent = workspace.Terrain
		attachment.WorldPosition = position
		
		local emitter = splashEmitter:Clone()
		emitter.Parent = attachment
		emitter:Emit(64)
		
		game:GetService("Debris"):AddItem(attachment, emitter.Lifetime.Max)
		
		-- enemy
		local enemy = enemyService:CreateEnemy(name, self.Level){
			StartCFrame = CFrame.new(position)
		}
		enemyService:ApplyDifficultyToEnemy(enemy)
		self:GetWorld():AddObject(enemy)
		
		-- jump
		jump(enemy, getLandingPosition(enemy:GetRootHeight()))
		
		table.insert(spawnedEnemies, enemy)
	end
	
	local waves = {
		{
			"Chained One", 10,
			"Imprisoned One", 4,
		},
		{
			"Chained One", 10,
			"Imprisoned One", 2,
			"Terrorknight", 2,
		},
		{
			"Chained One", 8,
			"Terrorknight", 4,
		},
		{
			"Terrorknight", 6,
			"Imprisoned One", 4,
		}
	}
	
	local bonusPerPlayer = 0.25
	local minTime = 0.5
	local maxTime = 3
	
	local progress = self.Model.Progress
	progress.Value = 1
	
	local function doWave(wave, baseProgress)
		local enemies = {}
		local enemiesTotal = 0
		
		for index = 1, #wave, 2 do
			local name = wave[index]
			local count = wave[index + 1]
			count = math.ceil(count * (1 + bonusPerPlayer * #Players:GetPlayers()))
			table.insert(enemies, {Name = name, Count = count})
			
			enemiesTotal += count
		end
		
		local enemiesSpawned = 0
		
		local burst = 6
		local burstController = 0
		
		while #enemies > 0 do
			local index = math.random(1, #enemies)
			local enemy = enemies[index]
			enemy.Count -= 1
			if enemy.Count == 0 then
				table.remove(enemies, index)
			end
			spawnEnemy(enemy.Name)
			
			enemiesSpawned += 1
			progress.Value = baseProgress + (1 - enemiesSpawned / enemiesTotal) / #waves
			
			burstController += 1
			if burstController % burst == 0 then
				local timeWeight = #Players:GetPlayers() / 6
				wait(self:Lerp(maxTime, minTime, timeWeight) * burst)
			end
		end
	end
	
	local function allEnemiesDead()
		for index = #spawnedEnemies, 1, -1 do
			local enemy = spawnedEnemies[index]
			if enemy.Active then
				return false
			else
				table.remove(spawnedEnemies[index])
			end
		end
		return true
	end
	
	spawn(function()
		wait(5)
		self.Started:Fire()
		
		for index, wave in pairs(waves) do
			wait(10)
			doWave(wave, 1 - index / #waves)
		end
		
		while not allEnemiesDead() do wait(1) end
		
		if not self.Active then return end
		self.Completed:Fire()
	end)
end