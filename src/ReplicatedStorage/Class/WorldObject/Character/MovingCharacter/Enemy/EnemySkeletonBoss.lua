local Super = require(script.Parent)
local EnemySkeletonBoss = Super:Extend()

EnemySkeletonBoss.Resilient = true

EnemySkeletonBoss.Frustration = 0
EnemySkeletonBoss.FrustrationMax = 2

function EnemySkeletonBoss:OnCreated()
	self.Target = nil
	self:CreateStateMachine()
	
	self.AttackPattern = self:CreateNew"AttackPattern"{Pattern = {
		"Cross", 2,
		"AirSlice",
		"Cross", 2,
		"AirSlice",
		"Cross", 2,
		"Breath",
		"Cross",
		"Breath",
		"Cross",
		"Breath",
		"Cross", 2,
		"Summon",
		"Cross", 2,
		"WarCry",
		"AirSlice",
		"Cross", 2,
		"WarCry",
		"AirSlice",
		"Cross", 2,
		"Breath", 3,
	}}
	
	Super.OnCreated(self)
	
	self.Speed.Base = 24
	
	self:GetService("MusicService"):PlayPlaylist{"Mortality Lost"}
end

function EnemySkeletonBoss:AttackCross()
	self:AnimationPlay("SkeletonBossAttack1")
	
	local length = 30
	local width = 10
	local duration = 1
	
	local here = self:GetFootPosition()
	local there = self.Target:GetFootPosition() + (self.Target.Root.Velocity * duration)
	local delta = (there - here) * Vector3.new(1, 0, 1)
	local cframe1 =
		CFrame.new(here, here + delta) *
		CFrame.new(0, 0, -length / 2)
	local cframe2 =
		cframe1 *
		CFrame.new(0, 0, -length / 2 - width / 2) *
		CFrame.Angles(0, math.pi / 2, 0)
	
	local function onHit(legend)
		self:GetService"DamageService":Damage{
			Source = self,
			Target = legend,
			Amount = self.Damage,
			Type = "Slashing",
		}
	end
	
	self:AttackSquare{
		CFrame = cframe1,
		Length = length,
		Width = width,
		Duration = duration,
		OnHit = onHit,
	}
	self:AttackSquare{
		CFrame = cframe2,
		Length = length,
		Width = width,
		Duration = duration,
		OnHit = onHit,
	}
	self:AttackCircle{
		Position = here,
		Radius = length * 0.3,
		Duration = duration,
		OnHit = onHit,
	}
	
	self:FaceTowards(there)
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Chasing",
		Duration = 1.25
	})
end

function EnemySkeletonBoss:AttackAirSlice()
	local speed = 1.25
	
	self:AnimationPlay("SkeletonBossAttack2", nil, nil, speed)
	
	local width = 24
	
	local crescent = self.Storage.Models.Crescent:Clone()
	crescent.Size = Vector3.new(width, 0, 4)
	
	local model = Instance.new("Model")
	crescent.Parent = model
	model.Name = "AirSlice"
	model.PrimaryPart = crescent
	
	local here = self:GetPosition()
	local there = self.Target:GetPosition()
	local delta = (there - here) * Vector3.new(1, 0, 1)
	
	self:FaceTowards(there)
	
	local function launchProjectile()
		local projectile = self:CreateNew"Projectile"{
			Model = model,
			CFrame = CFrame.new(here),
			Velocity = delta.Unit * 64,
			FaceTowardsVelocity = true,
			Range = 64,
			Victims = {},
			
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
							Type = "Slashing",
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
		effects:RequestEffectAll("Sound", {
			Position = here,
			Sound = self.EnemyData.Sounds.AirSlice,
		})
	end
	delay(1 / speed, launchProjectile)
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Chasing",
		Duration = (1 / speed) + 0.1
	})
end

function EnemySkeletonBoss:AttackBreath()
	self:AnimationPlay("SkeletonBossAttack3")
	
	local emitter = self.Model.Head.BreathAttachment.BreathEmitter
	
	local function breath()
		if not self.Target then return end
		
		self:GetService("EffectsService"):RequestEffectAll("Sound", {
			Position = self:GetPosition(),
			Sound = self.EnemyData.Sounds.Cough,
		})
		
		local cloud = self.EnemyData.EmitterPart:Clone()
		local position = self.Target:GetFootPosition()
		
		self:FaceTowards(position)
		
		self:AttackActiveCircle{
			Position = position,
			Radius = 12,
			Delay = 1,
			Duration = 20,
			Interval = 0.2,
			
			OnHit = function(legend, dt)
				self:GetService"DamageService":Damage{
					Source = self,
					Target = legend,
					Amount = self.Damage * 0.2 * dt,
					Type = "Internal",
				}
			end,
			
			OnStarted = function(t)
				cloud.Position = position
				cloud.Parent = workspace.Effects
			end,
			
			OnCleanedUp = function(t)
				cloud.Attachment.Emitter.Enabled = false
				game:GetService("Debris"):AddItem(cloud, cloud.Attachment.Emitter.Lifetime.Max)
			end
		}
		
		emitter.Enabled = true
		wait(0.75)
		emitter.Enabled = false
	end
	delay(0.75, breath)
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Chasing",
		Duration = 2
	})
end

function EnemySkeletonBoss:AttackSummon()
	self:AnimationPlay("WarCry")
	
	local function spawnSkeleton()
		local theta = math.pi * 2 * math.random()
		local r = 6
		local dx = math.cos(theta) * r
		local dz = math.sin(theta) * r
		local cframe = self.Root.CFrame + Vector3.new(dx, 0, dz)
		
		local skeleton = self:GetService("EnemyService"):CreateEnemy("Skeleton Warrior", self.Level, false){
			Name = "Resurrected Slayer",
			StartCFrame = cframe,
		}
		self:GetWorld():AddObject(skeleton)
		
		local effects = self:GetService("EffectsService")
		effects:RequestEffectAll("Sound", {
			Position = skeleton:GetPosition(),
			Sound = self.EnemyData.Sounds.Cast,
		})
		effects:RequestEffectAll("AirBlast", {
			Position = skeleton:GetPosition(),
			Color = Color3.fromRGB(61, 21, 133),
			Radius = 8,
			Duration = 0.25,
		})
	end
	
	delay(0.25, spawnSkeleton)
	delay(0.50, spawnSkeleton)
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Chasing",
		Duration = 1.25
	})
end

function EnemySkeletonBoss:AttackWarCry()
	self:AnimationPlay("WarCry")
	
	local radius = 32
	local speed = 128
	
	self:GetService("EffectsService"):RequestEffectAll("AirBlast", {
		Position = self:GetPosition(),
		Color = Color3.fromRGB(61, 21, 133),
		Radius = radius,
		Duration = 1/3,
	})
	
	self:PushMortalsAway(self:GetPosition(), radius, 64)
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Chasing",
		Duration = 1.25
	})
end

function EnemySkeletonBoss:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	self.StateMachine:Run(dt)
end

EnemySkeletonBoss.DetectionRange = 128
EnemySkeletonBoss.AttackRange = 18
EnemySkeletonBoss.Name = "Osseous Aberration"

function EnemySkeletonBoss:IsTargetValid()
	if not self.Target then
		return false
	end
	
	if not self:IsPointInRange(self.Target:GetPosition(), self.DetectionRange) then
		return false
	end
	
	if not self:CanSeePoint(self.Target:GetPosition()) then
		return false
	end
	
	return true
end

function EnemySkeletonBoss:CreateStateMachine()
	self.StateMachine = self:CreateNew"StateMachine"()
	
	self.StateMachine:AddState{
		Name = "Waiting",
		Run = function(state, machine)
			self.Target = self:GetNearestTarget(self.DetectionRange)
			if self:IsTargetValid() then
				machine:ChangeState("Chasing")
			end
		end,
	}
	
	self.StateMachine:AddState{
		Name = "Chasing",
		OnStateChanged = function()
			self:AnimationPlay("SkeletonBossWalk")
		end,
		
		Run = function(state, machine, dt)
			self.Frustration = self.Frustration + dt
			if self.Frustration > self.FrustrationMax then
				self.Frustration = 0
				self.Target = self:GetNearestTarget(self.DetectionRange)
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
			
			if attack == "AirSlice" then
				range = 48
			elseif attack == "WarCry" then
				range = 12
			elseif attack == "Summon" then
				range = 128
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
			self:AnimationStop("SkeletonBossWalk")
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

function EnemySkeletonBoss:Flinch()
	-- don't
end

return EnemySkeletonBoss