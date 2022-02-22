local function ragdoll(model)
	for _, desc in pairs(model:GetDescendants()) do
		if desc:IsA("Motor6D") then
			local motor = desc

			local attachmentA = Instance.new("Attachment")
			attachmentA.CFrame = motor.C0
			attachmentA.Parent = motor.Part0

			local attachmentB = Instance.new("Attachment")
			attachmentB.CFrame = motor.C1
			attachmentB.Parent = motor.Part1

			local ballAndSocket = Instance.new("BallSocketConstraint")
			ballAndSocket.Attachment0 = attachmentA
			ballAndSocket.Attachment1 = attachmentB
			ballAndSocket.Parent = model

			motor:Destroy()
		end

		if desc:IsA("BasePart") then
			desc.CanCollide = true
		end
	end
end

local function onCannonDied(self)
	self:SetCollisionGroup("Debris")
	
	local knights = {self.Model.Knight, self.Model.Knight2}
	for _, knight in pairs(knights) do
		knight.Parent = workspace
		ragdoll(knight)
		local duration = 1
		self:GetService("EffectsService"):RequestEffectAll("FadeModel", {
			Model = knight,
			Duration = duration
		})
		game:GetService("Debris"):AddItem(knight, duration)
	end

	self:SoundPlay("DeathMale")
	
	self.Model:BreakJoints()

	delay(2, function()
		local duration = 1
		self:GetService("EffectsService"):RequestEffectAll("FadeModel", {
			Model = self.Model,
			Duration = duration
		})
		game:GetService("Debris"):AddItem(self.Model, duration)
	end)

	self.StatusGui:Destroy()

	self:Deactivate()

	self.Died:Fire()
end

return function(self)
	self:GetService("MusicService"):PlayPlaylist(require(self.Storage.Music.Playlists.GenericDungeon))
	
	-- set up cannons
	local cannons = {}
	
	for _, cannon in pairs(self.Model.Cannons:GetChildren()) do
		local reload = cannon.AnimationController:LoadAnimation(self.Storage.Animations.StaticCannonReload)
		local fire = cannon.AnimationController:LoadAnimation(self.Storage.Animations.StaticCannonFire)
		
		cannon.Parent = workspace
		local ally = self:CreateNew"Ally"{
			Model = cannon,
			Name = "Cannon Team",
			Level = self.Level,
			OnDied = onCannonDied,
		}
		ally.MaxHealth.Base = 2500
		ally.Health = ally.MaxHealth:Get()
		self:GetWorld():AddObject(ally)
		
		spawn(function()
			while true do
				wait(2 + 3 * math.random())
				if not ally.Active then break end
				
				reload:Play()
				
				wait(1 + math.random())
				if not ally.Active then break end
				
				fire:Play()
				
				delay(10/30, function()
					if not ally.Active then return end
					
					local barrel = cannon.Cannon.Barrel
					
					barrel.Sound:Play()
					
					local e = Instance.new("Explosion")
					e.BlastPressure = 0
					e.Position = barrel.CFrame:PointToWorldSpace(Vector3.new(-barrel.Size.X / 2 - 4, 0, 0))
					e.Parent = workspace
				end)
			end
		end)
		
		table.insert(cannons, ally)
	end
	
	local function getLivingCannons()
		local count = 0
		for _, cannon in pairs(cannons) do
			if cannon.Active then
				count += 1
			end
		end
		return count
	end
	
	-- tunnels
	local tunnels = {}
	for _, model in pairs(self.Model.Tunnels:GetChildren()) do
		local tunnel = {
			SpawnPosition = model.SpawnZone.Position,
			LandingCFrame = model.LandingZone.CFrame,
			LandingSize = model.LandingZone.Size,
		}
		model:Destroy()
		
		table.insert(tunnels, tunnel)
	end
	
	local function getPointInPlane(cframe, size)
		local dx = size.X * math.random() - size.X / 2
		local dz = size.Z * math.random() - size.Z / 2
		local p = cframe:PointToWorldSpace(Vector3.new(dx, 0, dz))
		return p
	end

	local function getLandingPosition(dy, cframe, size)
		return getPointInPlane(cframe, size) + Vector3.new(0, dy, 0)
	end
	
	local function jump(enemy, position)
		enemy:FaceTowards(position)

		local a = enemy:GetPosition()
		local c = position
		local b = c + Vector3.new(0, 16, 0)

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
	
	local enemyService = self:GetService("EnemyService")
	
	local function spawnEnemy(name)
		local tunnel = self:Choose(tunnels)

		-- enemy
		local enemy = enemyService:CreateEnemy(name, self.Level){
			StartCFrame = CFrame.new(tunnel.SpawnPosition),
			DetectionRange = 512,
		}
		enemyService:ApplyDifficultyToEnemy(enemy)
		self:GetWorld():AddObject(enemy)

		-- jump
		jump(enemy, getLandingPosition(enemy:GetRootHeight(), tunnel.LandingCFrame, tunnel.LandingSize))
	end
	
	self.Started:Fire()
	
	local timer = 180
	local maxTimer = timer
	
	local progress = self.Model.Progress
	progress.Value = 1
	
	spawn(function()
		wait(10)
		
		self.Started:Fire()
		
		local cannonsAlive
		
		repeat
			spawnEnemy(self:GetRun():RequestEnemy())
			
			timer -= wait(2)
			
			cannonsAlive = getLivingCannons() >= 2
			progress.Value = timer / maxTimer
			
		until (not cannonsAlive) or (timer <= 0)
		
		if not cannonsAlive then
			self:GetRun():Defeat()
		else
			self.Completed:Fire()
			
			--deactivate cannons
			delay(5, function()
				for _, cannon in pairs(cannons) do
					cannon.Active = false
				end
			end)
		end
	end)
end