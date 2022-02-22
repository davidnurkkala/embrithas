local Super = require(script.Parent)
local EnemyJukumai = Super:Extend()

EnemyJukumai.Resilient = true

function EnemyJukumai:OnCreated()
	self.IceSpikes = {}
	
	self.Target = nil
	self:CreateStateMachine()
	
	self.AttackPattern = self:CreateNew"AttackPattern"{Pattern = {
		"Basic", 10,
		"Shield",
		"Basic", 5,
		"Barrage",
		"TeleportBasic", 2,
		"Fan",
		"Basic", 3,
		"Fan",
		"Basic", 2,
		"Fan",
		"Basic",
		"Fan",
		"TeleportFan", 1,
		"Shield",
		"Basic", 5,
		"TeleportBasic",
	}}
	
	Super.OnCreated(self)
	
	self:AnimationPlay("JukumaiIdle")
	self:GetService("MusicService"):PlayPlaylist{"Immortal Machinations"}
	
	self.IceCooldown = self:CreateNew"Cooldown"{Time = 0.25}
	self.SpawnCooldown = self:CreateNew"Cooldown"{Time = 4}
end

function EnemyJukumai:CustomOnDied()
	for _, spike in pairs(self.IceSpikes) do
		spike:Destroy()
	end
	
	delay(0.25, function()
		self:SoundPlay("Death")
		self:AnimationPlay("JukumaiDefeated")
		delay(1.8, function()
			self:AnimationPlay("JukumaiDefeatedLoop")
		end)
	end)
end

function EnemyJukumai:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	self.StateMachine:Run(dt)
	
	if self.IceCooldown:IsReady() then
		self.IceCooldown:Use()
		
		local position = self:GetFootPosition()
		local cframe = CFrame.new(position) * CFrame.Angles(0, math.pi * 2 * math.random(), 0)
		local sheet = self.EnemyData.IceSheet:Clone()
		sheet.CFrame = cframe
		sheet.Parent = workspace.Effects
		self:Tween(sheet, {Transparency = 1}, 1).Completed:Connect(function()
			sheet:Destroy()
		end)
	end
end

EnemyJukumai.DetectionRange = 128
EnemyJukumai.AttackRange = 128

EnemyJukumai.Frustration = 0
EnemyJukumai.FrustrationLimit = 2

function EnemyJukumai:AttackTeleportFan()
	self:AttackTeleport()
	self:AttackFan()
end

function EnemyJukumai:AttackBasic()
	local speed = 1.33
	local castDelay = 11/15
	local restDuration = 1.5
	
	local radius = 8
	local duration = 0.75
	
	local function attack(target, spawnIceSpike)
		self:FaceTowards(target:GetPosition())
		self:AnimationPlay("JukumaiCast", nil, nil, speed)
		
		delay(castDelay / speed, function()
			if not (target and target.Active) then return end
			
			local position = target:GetFootPosition() + (target:GetFlatVelocity() * duration)
			
			self:AttackCircle{
				Position = position,
				Radius = radius,
				Duration = duration,
				OnHit = self:DamageFunc(1, "Piercing", {"Magical"}),
				Sound = self.EnemyData.Sounds.Shatter,
			}
			
			if spawnIceSpike then
				delay(duration, function()
					self:SummonIceSpike(position)
				end)
				
				self:SoundPlay("Cast")
			end
			
			self:GetService("EffectsService"):RequestEffectAll("LobProjectile", {
				Start = self.Model.LeftHand.Position,
				Finish = position,
				Height = 8,
				Duration = duration,
				Model = self.Storage.Models.FrostBolt,
			})
		end)
	end
	
	local targets = self:GetService("TargetingService"):GetMortals()
	self:Shuffle(targets)
	for index = 1, math.min(5, #targets) do
		attack(targets[index], index == 1)
	end
	
	self.StateMachine:ChangeState("Resting", {
		Duration = restDuration / speed,
		NextState = "Waiting",
	})
end

function EnemyJukumai:AttackShield()
	local speed = 0.6
	
	local radius = 10
	local count = 8
	local castDelay = 13/15 / speed
	local animationDuration = 40/30 / speed
	
	self:AnimationPlay("JukumaiTossAndSlam", nil, nil, speed)
	
	local center = self:GetFootPosition()
	local thetaStep = math.pi * 2 / count
	for step = 0, count - 1 do
		local theta = thetaStep * step
		local position = center + Vector3.new(math.cos(theta) * radius, 0, math.sin(theta) * radius)
		self:SummonIceSpike(position, castDelay, step % 4 == 0, step % 3 == 0)
	end
	
	self.StateMachine:ChangeState("Resting", {
		Duration = animationDuration,
		NextState = "Waiting",
	})
end

function EnemyJukumai:AttackBarrage()
	local radius = 8
	local duration = 1
	
	local speed = 0.2
	
	local castDelay = 1 / speed
	local castDuration = 53/30 / speed
	
	local count = 40
	local pause = castDuration / count
	
	local function attack(target)
		local here = self:GetPosition() + Vector3.new(0, 8, 0)
		local center = target:GetFootPosition()
		
		for boltNumber = 1, 3 do
			local theta = math.pi * 2 * math.random()
			local r = radius * 4 * math.random()
			local position = center + Vector3.new(math.cos(theta) * r, 0, math.sin(theta) * r)
			
			self:AttackCircle{
				Position = position,
				Duration = duration,
				Radius = radius,
				OnHit = self:DamageFunc(1, "Piercing", {"Magical"}),
				Sound = (boltNumber == 1) and (self.EnemyData.Sounds.Shatter) or (self.Storage.Sounds.Silence),
			}
			
			self:GetService("EffectsService"):RequestEffectAll("LobProjectile", {
				Start = here,
				Finish = position,
				Height = 0,
				Duration = duration,
				Model = self.Storage.Models.FrostBolt,
			})
		end
		
		self:SoundPlay("Cast")
	end
	
	self:SoundPlay("Laugh")
	
	delay(castDelay, function()
		for _ = 1, count do
			local targets = self:GetService("TargetingService"):GetMortals()
			if #targets > 0 then
				attack(self:Choose(targets))
			end
			wait(pause)
		end
	end)
	
	self:AnimationPlay("JukumaiBarrage", nil, nil, speed)
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Waiting",
		Duration = castDelay + castDuration + 0.25,
	})
end

function EnemyJukumai:AttackTeleportBasic()
	self:AttackTeleport()
	self:AttackBasic()
end

function EnemyJukumai:AttackTeleport()
	local teleports = self:GetRun().Dungeon.Model.TeleportPoints:GetChildren()
	local teleport = self:Choose(teleports).Position
	
	local effectsService = self:GetService("EffectsService")
	
	local function airBlast(position)
		effectsService:RequestEffectAll("Sound", {
			Sound = self.EnemyData.Sounds.Cast,
			Position = position,
		})
		effectsService:RequestEffectAll("AirBlast", {
			Position = position,
			Radius = 16,
			Color = BrickColor.new("Light blue").Color,
			Duration = 0.5,
		})
	end
	
	local here = self:GetPosition()
	local there = teleport
	local delta = (there - here) * Vector3.new(1, 0, 1)
	
	self.Root.CFrame += delta
	
	airBlast(here)
	airBlast(there)
end

function EnemyJukumai:AttackFan()
	local speed = 0.5
	
	local projectileSpeed = 4
	local projectileAcceleration = 32
	local width = 6
	
	local function launchProjectile(cframe)
		local model = self.Storage.Models.FrostBolt:Clone()
		
		local projectile = self:CreateNew"Projectile"{
			Model = model,
			CFrame = CFrame.new(self:GetPosition()),
			Velocity = cframe.LookVector * projectileSpeed,
			FaceTowardsVelocity = true,
			Range = 128,
			Victims = {},
			
			ShouldIgnoreFunc = function()
				return true
			end,
			
			OnTicked = function(p, dt)
				p.Velocity += p.Velocity.Unit * projectileAcceleration * dt
				
				local here = p.LastCFrame.Position
				local there = p.CFrame.Position
				local delta = (there - here)
				local length = delta.Magnitude
				local midpoint = (here + there) / 2
				local cframe = CFrame.new(midpoint, there)
				
				for _, legend in pairs(self:GetClass("Legend").Instances) do
					local delta = cframe:PointToObjectSpace(legend:GetPosition())
					if math.abs(delta.X) <= (width / 2) and math.abs(delta.Z) <= (length / 2) and (not table.find(p.Victims, legend)) then
						self:GetService"DamageService":Damage{
							Source = self,
							Target = legend,
							Amount = self.Damage,
							Type = "Piercing",
							Tags = {"Magical"},
						}
						table.insert(p.Victims, legend)
					end
				end
			end,
		}
		self:GetWorld():AddObject(projectile)
		
		local effects = self:GetService("EffectsService")
		effects:RequestEffectAll("ShowProjectile", {
			Projectile = projectile.Model,
			Width = width,
		})
	end
	
	local castDelay = 2/3 / speed
	local animationDuration = 38/30 / speed
	
	self:GetService("EffectsService"):RequestEffectAll("Shockwave", {
		CFrame = CFrame.new(self:GetFootPosition()),
		StartSize = Vector3.new(64, 0, 64),
		EndSize = Vector3.new(0, 8, 0),
		Duration = castDelay,
		PartArgs = {
			BrickColor = BrickColor.new("LightBlue"),
		}
	})
	
	local here = self:GetPosition()
	local there = self.Target:GetPosition()
	local delta = (there - here) * Vector3.new(1, 0, 1)
	local cframe = CFrame.new(here, here + delta)
	
	local count = 16
	local angle = math.pi * 0.6
	local start = -angle
	local finish = angle
	local totalAngle = finish - start
	local angleStep = totalAngle / count
	delay(castDelay, function()
		for step = 0, count - 1 do
			local angle = start + angleStep * (step + 0.5)
			local launchCFrame = cframe * CFrame.Angles(0, angle, 0)
			launchProjectile(launchCFrame)
		end
	end)
	
	delay(castDelay, function()
		self:SoundPlay("Cast")
	end)
	
	self:AnimationPlay("JukumaiStaffSpin", nil, nil, speed)
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Waiting",
		Duration = animationDuration,
	})
end

function EnemyJukumai:SummonIceSpike(position, duration, lightEnabled, guaranteedSpawn)
	if not self.Active then return end
	
	if lightEnabled == nil then lightEnabled = true end
	if guaranteedSpawn == nil then guaranteedSpawn = false end
	duration = duration or 1.5
	
	local riseDuration = 0.25
	local radius = 20
	local spikeDuration = 15
	
	local cframe =
		CFrame.new(position) *
		CFrame.Angles(0, math.pi * 2 * math.random(), math.pi / 2) +
		Vector3.new(0, 6, 0)
	
	local spike = self.EnemyData.IceSpike:Clone()
	spike:SetPrimaryPartCFrame(cframe * CFrame.new(-32, 0, 0))
	if not lightEnabled then
		spike.Mesh.Light:Destroy()
	end
	table.insert(self.IceSpikes, spike)
	spike.Parent = self:GetRun().Dungeon.Model
	
	delay(duration - riseDuration, function()
		if not spike.Parent then return end
		
		self:TweenNetwork{
			Object = spike.PrimaryPart,
			Goals = {CFrame = cframe},
			Duration = riseDuration,
			Direction = Enum.EasingDirection.In,
		}
	end)
	
	delay(spikeDuration, function()
		if not spike.Parent then return end
		
		table.remove(self.IceSpikes, table.find(self.IceSpikes, spike))
		
		if self.SpawnCooldown:IsReady() or guaranteedSpawn then
			self.SpawnCooldown:Use()
			
			spike:Destroy()
			
			local spawnCFrame = CFrame.new(cframe.Position + Vector3.new(0, 8, 0))
			local enemyService = self:GetService("EnemyService")
			local enemy = enemyService:CreateEnemy("Skeleton Warrior", self.Level, false){
				StartCFrame = spawnCFrame,
			}
			self:GetWorld():AddObject(enemy)
			enemy:SoundPlayByObject(self.EnemyData.Sounds.Hit)
			
			local effectsService = self:GetService("EffectsService")
			effectsService:RequestEffectAll("AirBlast", {
				Position = spawnCFrame.Position,
				Radius = 16,
				Color = BrickColor.new("Light blue").Color,
				Duration = 0.5,
			})
		else
			local duration = 1
			self:GetService("EffectsService"):RequestEffectAll("FadeModel", {
				Model = spike,
				Duration = duration,
			})
			game:GetService("Debris"):AddItem(spike, duration)
		end
	end)
	
	self:AttackCircle{
		Position = position,
		Radius = radius,
		Duration = duration,
		OnHit = self:DamageFunc(1, "Cold", {"Magical"}),
	}
end

function EnemyJukumai:Flinch()
	-- don't
end

function EnemyJukumai:IsTargetValid()
	if not self.Target then
		return false
	end
	
	if not self:IsPointInRange(self.Target:GetPosition(), self.DetectionRange) then
		return false
	end
	
	return true
end

function EnemyJukumai:CreateStateMachine()
	self.StateMachine = self:CreateNew"StateMachine"()
	
	self.StateMachine:AddState{
		Name = "Waiting",
		Run = function(state, machine, dt)
			self.Target = self:GetNearestTarget(self.DetectionRange, nil, false)
			if self:IsTargetValid() then
				self:FaceTowards(self.Target:GetPosition())
				machine:ChangeState("Chasing")
			end
			self:StuckCheck(dt)
		end,
		OnStateWillChange = function()
			self:StuckReset()
		end
	}
	
	self.StateMachine:AddState{
		Name = "Chasing",
		OnStateChanged = function()
			self:AnimationPlay("JukumaiWalk")
		end,
		
		Run = function(state, machine, dt)
			self.Frustration = self.Frustration + dt
			if self.Frustration > self.FrustrationLimit then
				self.Frustration = 0
				self.Target = self:GetNearestTarget(self.DetectionRange, nil, false)
			end
			
			if not self:IsTargetValid() then
				self.Target = nil
				return machine:ChangeState("Waiting")
			end
			
			local targetPosition = self.Target:GetPosition()
			local distance = self:DistanceTo(targetPosition)
			
			self:MoveTo(targetPosition)
			
			local attack = self.AttackPattern:Get()
			local range = self.AttackRange
			
			if attack == "Summon" then
				range = self.DetectionRange
			elseif attack == "Resonance" then
				range = self.DetectionRange
			elseif attack == "Slam" then
				range = self.DetectionRange
			elseif attack == "Return" then
				range = self.DetectionRange
			end
			
			if distance < range then
				self["Attack"..attack](self)
				self.AttackPattern:Next()
			
			elseif distance > self.DetectionRange then
				self.Target = nil
				machine:ChangeState("Waiting")
			end
		end,
		
		OnStateWillChange = function()
			self.Frustration = 0
			self:MoveStop()
			self:AnimationStop("JukumaiWalk")
		end,
	}
	
	self.StateMachine:AddState{
		Name = "Resting",
		Run = function(state, machine, dt)
			state.Duration = state.Duration - dt
			if state.Duration <= 0 then
				machine:ChangeState(state.NextState)
			end
		end
	}
end

return EnemyJukumai