local Super = require(script.Parent)
local EnemyCageBoss = Super:Extend()

EnemyCageBoss.Resilient = true

EnemyCageBoss.Colors = {
	Red = Color3.fromRGB(255, 62, 62),
	Purple = Color3.fromRGB(151, 47, 255),
	Green = Color3.fromRGB(128, 255, 143),
	Blue = Color3.fromRGB(64, 105, 255),
}

function EnemyCageBoss:OnCreated()
	self.IceSpikes = {}
	
	self.Target = nil
	self:CreateStateMachine()
	
	self.PatternRed = self:CreateNew"AttackPattern"{Pattern = {
		"Cleaver",
		"Smash",
		"Cleaver",
		"Spin",
	}}
	
	self.PatternPurple = self:CreateNew"AttackPattern"{Pattern = {
		"Reach",
		"Cleaver", 2,
	}}
	
	self.PatternGreen = self:CreateNew"AttackPattern"{Pattern = {
		"Summon",
		"Cleaver", 6,
	}}
	
	self.PatternBlue = self:CreateNew"AttackPattern"{Pattern = {
		"Cast", 3,
		"Storm",
	}}
	
	self.ColorCooldown = self:CreateNew"Cooldown"{Time = 20}
	self.ColorCooldown:Use()
	
	Super.OnCreated(self)
	
	self:AnimationPlay("CageIdle")
	self:GetService("MusicService"):PlayPlaylist{"Caged Souls"}
	
	self:AttackColorRed()
end

function EnemyCageBoss:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	if self.ColorCooldown:IsReady() then
		self.ColorCooldown:Use()
		
		local colorNames = {}
		for colorName, _ in pairs(self.Colors) do
			if colorName ~= self.Color then
				table.insert(colorNames, colorName)
			end
		end
		self["AttackColor"..self:Choose(colorNames)](self)
	end
	
	self.StateMachine:Run(dt)
end

EnemyCageBoss.DetectionRange = 128
EnemyCageBoss.RangeByAttack = {
	Cleaver = 12,
	Smash = 16,
	Spin = 12,
	Reach = 128,
	Summon = 128,
	Cast = 128,
	Storm = 128,
}

EnemyCageBoss.Frustration = 0
EnemyCageBoss.FrustrationLimit = 2

function EnemyCageBoss:AttackCleaver()
	self:AnimationPlay("CageCleaver")
	
	local hitDelay = 1
	
	local here = self:GetFootPosition()
	local there = self.Target:GetFootPosition() + self.Target:GetFlatVelocity() * hitDelay
	local delta = (there - here) * Vector3.new(1, 0, 1)
	local position = here + delta.Unit * 12
	
	self:FaceTowards(position)
	
	self:AttackCircle{
		Position = position,
		Duration = hitDelay,
		Radius = 12,
		OnHit = self:DamageFunc(1, "Slashing"),
	}
	
	local smallDelay = 6/30
	
	delay(hitDelay, function()
		self:AttackCircle{
			Position = position,
			Duration = smallDelay,
			Radius = 18,
			OnHit = self:DamageFunc(1, "Slashing"),
		}
		wait(smallDelay)
		self:AttackCircle{
			Position = position,
			Duration = smallDelay,
			Radius = 24,
			OnHit = self:DamageFunc(1, "Slashing"),
		}
	end)
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Waiting",
		Duration = 3,
	})
end

function EnemyCageBoss:AttackSmash()
	local hitDelay = 36/30
	
	local here = self:GetFootPosition()
	local there = self.Target:GetPosition()
	local delta = (there - here) * Vector3.new(1, 0, 1)
	there = here + delta
	local cframe = CFrame.new(here, there)
	
	self:FaceTowards(there)
	
	self:AttackCircle{
		Position = cframe.Position + cframe.LookVector * 12,
		Radius = 20,
		Duration = hitDelay,
		OnHit = self:DamageFunc(1, "Bludgeoning"),
	}
	
	delay(hitDelay, function()
		local stepCount = 6
		local angle = math.pi
		local startAngle = -math.pi / 2
		local duration = 13/30
		local windup = 19/30
		
		for step = 0, stepCount do
			local theta = startAngle + (angle / stepCount) * step
			local d = windup + (duration / stepCount) * step
			self:AttackSquare{
				CFrame = cframe * CFrame.Angles(0, theta, 0) * CFrame.new(0, 0, -16),
				Length = 20,
				Width = 14,
				Duration = d,
				OnHit = self:DamageFunc(1, "Bludgeoning")
			}
		end
	end)
	
	self:AnimationPlay("CageSmash")
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Waiting",
		Duration = 3,
	})
end

function EnemyCageBoss:AttackSpin()
	self:AnimationPlay("CageMeleeSpin")
	
	local hitDelay = 32/30
	local radius = 16
	
	self:AttackCircle{
		Position = self:GetFootPosition(),
		Radius = radius,
		Duration = hitDelay,
		OnHit = self:DamageFunc(1, "Slashing"),
		Sound = self.EnemyData.Sounds.Spin,
	}
	
	delay(hitDelay, function()
		local duration = 48/30
		local rate = 5
		local spinDelay = 1 / rate
		local spinCount = duration * rate
		
		for spin = 1, spinCount do
			radius += 3
			self:AttackCircle{
				Position = self:GetFootPosition(),
				Radius = radius,
				Duration = spinDelay,
				OnHit = self:DamageFunc(1, "Slashing"),
				Sound = self.EnemyData.Sounds.Spin,
			}
			wait(spinDelay)
		end
	end)
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Waiting",
		Duration = 3.5,
	})
end

function EnemyCageBoss:AttackReach()
	local here = self:GetFootPosition()
	local there = self.Target:GetFootPosition()
	local delta = (there - here) * Vector3.new(1, 0, 1)
	there = here + delta
	local cframe = CFrame.new(here, there)
	
	self:FaceTowards(there)
	
	local length = 128
	local hitDelay = 32/30
	
	self:AttackSquare{
		CFrame = cframe * CFrame.new(0, 0, -length/2),
		Length = length,
		Width = 20,
		Duration = hitDelay,
		OnHit = function(legend)
			self:DamageFunc(0.2, "Internal", {"Magical"})(legend)
			
			legend:AddStatus("StatusSlowed", {
				Time = 2,
				Percent = 1,
			})
		end,
		Sound = self.EnemyData.Sounds.Cast,
	}
	
	self:AnimationPlay("CageReach")
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Waiting",
		Duration = 2,
	})
end

function EnemyCageBoss:AttackSummon()
	self:AnimationPlay("CageRangedSpin")
	
	local enemyService = self:GetService("EnemyService")
	local effectsService = self:GetService("EffectsService")
	
	delay(20/30, function()
		local duration = 5
		local stepCount = 15
		local durationStep = duration / stepCount
		
		for step = 1, stepCount do
			local theta = math.pi * 2 * math.random()
			local radius = 16
			local dx = math.cos(theta) * radius
			local dz = math.sin(theta) * radius
			local position = self:GetPosition() + Vector3.new(dx, 0, dz)
			
			local enemy = enemyService:CreateEnemy("Imprisoned One", self.Level, false){
				StartCFrame = CFrame.new(position)
			}
			self:GetWorld():AddObject(enemy)
			enemy:SoundPlayByObject(self.EnemyData.Sounds.Cast)
			
			effectsService:RequestEffectAll("AirBlast", {
				Position = position,
				Radius = 6,
				Duration = 0.5,
				Color = self.Colors.Green,
			})
			
			wait(durationStep)
		end
	end)
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Waiting",
		Duration = 6.5,
	})
end

function EnemyCageBoss:FireProjectile(cframe)
	local model = self.EnemyData.Projectile:Clone()
	local projectileSpeed = 20
	local width = 10
	
	local projectile = self:CreateNew"Projectile"{
		Model = model,
		CFrame = cframe,
		Velocity = cframe.LookVector * projectileSpeed,
		FaceTowardsVelocity = true,
		Range = 128,
		Victims = {},

		ShouldIgnoreFunc = function()
			return true
		end,

		OnTicked = function(p)
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
						Type = "Disintegration",
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

function EnemyCageBoss:AttackCast()
	local here = self:GetPosition()
	local there = self.Target:GetPosition()
	local delta = (there - here) * Vector3.new(1, 0, 1)
	there = here + delta
	local cframe = CFrame.new(here, there)
	
	self:FaceTowards(there)
	
	delay(32/30, function()
		for _, angle in pairs{-60, -30, 0, 30, 60} do
			self:FireProjectile(cframe * CFrame.Angles(0, math.rad(angle), 0))
		end
		self:SoundPlay("Cast")
	end)
	
	self:AnimationPlay("CageReach")
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Waiting",
		Duration = 2,
	})
end

function EnemyCageBoss:AttackStorm()
	self:AnimationPlay("CageRangedSpin")
	
	delay(20/30, function()
		local duration = 5
		local stepCount = 60
		local durationStep = duration / stepCount

		for step = 1, stepCount do
			local theta = math.pi * 2 * math.random()
			self:FireProjectile(CFrame.new(self:GetPosition()) * CFrame.Angles(0, theta, 0))
			self:SoundPlay("Cast")
			
			wait(durationStep)
		end
	end)
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Waiting",
		Duration = 6.5,
	})
end

for colorName, color in pairs(EnemyCageBoss.Colors) do
	EnemyCageBoss["AttackColor"..colorName] = function(self)
		self:ChangeColor(color)
		self.Color = colorName
	end
end

function EnemyCageBoss:ChangeColor(color)
	local effectsService = self:GetService("EffectsService")
	
	effectsService:RequestEffectAll("Shockwave", {
		CFrame = CFrame.new(self:GetFootPosition()),
		StartSize = Vector3.new(20, 0, 20),
		EndSize = Vector3.new(2, 20, 2),
		Duration = 1,
		PartArgs = {
			Color = color,
		}
	})
	
	delay(1, function()
		for _, desc in pairs(self.Model:GetDescendants()) do
			if desc:IsA("Beam") or desc:IsA("ParticleEmitter") then
				desc.Color = ColorSequence.new(color)
			elseif desc:IsA("Light") then
				desc.Color = color
			end
		end
		
		effectsService:RequestEffectAll("AirBlast", {
			Position = self:GetPosition(),
			Radius = 32,
			Color = color,
			Duration = 0.25
		})
	end)
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Waiting",
		Duration = 2,
	})
end

function EnemyCageBoss:Flinch()
	-- don't
end

function EnemyCageBoss:IsTargetValid()
	if not self.Target then
		return false
	end
	
	if not self:IsPointInRange(self.Target:GetPosition(), self.DetectionRange) then
		return false
	end
	
	return true
end

function EnemyCageBoss:CreateStateMachine()
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
			self:AnimationPlay("CageWalk")
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
			
			local pattern = self["Pattern"..self.Color]
			local attack = pattern:Get()
			local range = self.RangeByAttack[attack]
			
			if distance < range then
				self["Attack"..attack](self)
				pattern:Next()
			
			elseif distance > self.DetectionRange then
				self.Target = nil
				machine:ChangeState("Waiting")
			end
		end,
		
		OnStateWillChange = function()
			self.Frustration = 0
			self:MoveStop()
			self:AnimationStop("CageWalk")
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

return EnemyCageBoss