local Super = require(script.Parent)
local EnemyBoneSpider = Super:Extend()

EnemyBoneSpider.Resilient = true

function EnemyBoneSpider:OnCreated()
	self.Target = nil
	self:CreateStateMachine()
	
	self.AttackPattern = self:CreateNew"AttackPattern"{Pattern = {
		"Barrage", 1,
		"Basic", 3,
		"Barrage", 1,
		"Basic", 3,
		"Escape",
		"Spit",
	}}
	
	Super.OnCreated(self)
	
	self.RangedHarassCooldown = self:CreateNew"Cooldown"{Time = 2}
	self.RangedHarassCooldown:Use()
	
	self.Speed.Base = 16
end

function EnemyBoneSpider:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	self.StateMachine:Run(dt)
	
	if self.RangedHarassCooldown:IsReady() then
		self.RangedHarassCooldown:Use()
		self:AttackRangedHarass()
	end
	
	if (not self.PoisonedArena) and (self.Health <= self.MaxHealth:Get() / 2) then
		self.PoisonedArena = true
		self:AttackPoisonArena()
	end
end

EnemyBoneSpider.DetectionRange = 128
EnemyBoneSpider.AttackRange = 12

EnemyBoneSpider.Frustration = 0
EnemyBoneSpider.FrustrationLimit = 4

function EnemyBoneSpider:AttackBasic()
	local duration = 1
	local radius = 12
	
	local targetPosition = self.Target:GetFootPosition() + self.Target:GetFlatVelocity() * duration

	local here = self:GetFootPosition()
	local delta = (targetPosition - here) * Vector3.new(1, 0, 1)
	local distance = delta.Magnitude
	if distance > self.AttackRange then
		targetPosition = here + (delta / distance) * self.AttackRange
	end

	self:FaceTowards(targetPosition)

	self:AnimationPlay("BoneSpiderAttack1", nil, nil, 1 / duration)

	self:AttackCircle{
		Position = targetPosition,
		Radius = radius,
		Duration = duration,
		OnHit = function(legend)
			self:GetService"DamageService":Damage{
				Source = self,
				Target = legend,
				Amount = self.Damage,
				Type = "Bludgeoning",
			}
		end
	}

	self.StateMachine:ChangeState("Resting", {
		NextState = "Waiting",
		Duration = duration
	})
end

function EnemyBoneSpider:AttackBarrage()
	local speed = 0.75
	
	self:AnimationPlay("BoneSpiderBarrage", nil, nil, speed)
	
	local function attack(duration, damageMultiplier, radius, sound)
		self.Target = self:GetNearestTarget(self.DetectionRange)
		if not self:IsTargetValid() then return end
		
		local targetPosition = self.Target:GetFootPosition() + self.Target:GetFlatVelocity() * duration
		
		local here = self:GetFootPosition()
		local delta = (targetPosition - here) * Vector3.new(1, 0, 1)
		local distance = delta.Magnitude
		if distance > self.AttackRange then
			targetPosition = here + (delta / distance) * self.AttackRange
		end
		
		self:FaceTowards(targetPosition)
		
		self:AttackCircle{
			Position = targetPosition,
			Radius = radius,
			Duration = duration / speed,
			OnHit = function(legend)
				self:GetService"DamageService":Damage{
					Source = self,
					Target = legend,
					Amount = self.Damage * damageMultiplier,
					Type = "Bludgeoning",
				}
			end,
			Sound = sound,
		}
		
		wait(duration / speed)
	end
	spawn(function()
		attack(0.50, 0.5, 12)
		attack(0.33, 0.1, 8)
		attack(0.33, 0.1, 8)
		attack(0.33, 0.1, 8)
		attack(0.33, 0.1, 8)
		attack(0.33, 0.1, 8)
		attack(0.50, 1,   24, self.EnemyData.Sounds.Rumble)
	end)
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Waiting",
		Duration = 3 / speed,
	})
end

function EnemyBoneSpider:AttackEscape()
	self:AnimationPlay("BoneSpiderJump")

	delay(0.5, function()
		local height = 64
		
		local corners = self:GetRun().Dungeon.Model.Corners:GetChildren()
		local corner = corners[math.random(1, #corners)].Position
		
		local start = self.Root.CFrame
		local airA = start * CFrame.new(0, height, 0)

		local delta = (corner - start.Position) * Vector3.new(1, 0, 1)
		local finish = start + delta
		local airB = finish * CFrame.new(0, height, 0)
		
		self:TweenNetwork{
			Object = self.Root,
			Goals = {CFrame = airA},
			Duration = 1/6,
			Style = Enum.EasingStyle.Linear,
		}.Completed:Connect(function()
			self.Root.CFrame = airB
			self:TweenNetwork{
				Object = self.Root,
				Goals = {CFrame = finish},
				Duration = 1/6,
				Style = Enum.EasingStyle.Linear,
			}
		end)
	end)
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Waiting",
		Duration = 2,
	})
end

function EnemyBoneSpider:AttackRangedHarass()
	local duration = 1
	
	local target = self:GetFurthestTarget(self.DetectionRange)
	if not target then return end
	
	self:AnimationPlay("BoneSpiderRanged", nil, nil, (21 / 29) / duration)
	
	local width = 8
	local projectileSpeed = 20
	
	local function launchProjectile(cframe)
		cframe *= CFrame.new(0, 0, -16)
		
		local model = self.Storage.Models.BoneSpiderBolt:Clone()
		
		local duration = 0.75
		local here = self:GetFootPosition()
		local delta = (cframe.Position - here) * Vector3.new(1, 0, 1)
		self:AttackCircle{
			Position = here + delta,
			Radius = 4,
			Duration = duration,
			OnHit = function() end,
			Sound = self.Storage.Sounds.Silence,
		}
		
		delay(duration, function()
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
		end)
	end
	delay(duration, function()
		if not target then return end
		
		local here = self:GetPosition()
		local there = target:GetPosition()
		local distance = (there - here).Magnitude
		local t = distance / projectileSpeed
		there = there + target:GetFlatVelocity() * t
		
		local delta = (there - here) * Vector3.new(1, 0, 1)
		
		local cframe = CFrame.new(here, here + delta)
		local angle = math.pi / 4
		
		launchProjectile(cframe)
		launchProjectile(cframe * CFrame.Angles(0,  angle, 0))
		launchProjectile(cframe * CFrame.Angles(0, -angle, 0))
		
		self:SoundPlay("Cast")
	end)
end

function EnemyBoneSpider:AttackSpit()
	local duration = 0.75
	
	self:AnimationPlay("BoneSpiderSpit", nil, nil, 1 / duration)
	
	local targets = self:GetService("TargetingService"):GetMortals()
	if #targets == 0 then return end
	self:Shuffle(targets)
	
	local radius = 12
	
	local function spit(target)
		local targetPosition = target:GetFootPosition()
		local theta = math.pi * 2 * math.random()
		local r = radius * 1.5 * math.random()
		local travelTime = self:RandomFloat(0.5, 4)
		
		targetPosition += Vector3.new(
			math.cos(theta) * r,
			0,
			math.sin(theta) * r
		)
		
		self:AttackCircle{
			Position = targetPosition,
			Radius = radius,
			Duration = duration + travelTime,
			OnHit = function(legend)
				self:GetService"DamageService":Damage{
					Source = self,
					Target = legend,
					Amount = self.Damage,
					Type = "Disintegration",
					Tags = {"Magical"},
				}
			end,
			Sound = self.EnemyData.Sounds.Sizzle,
		}
		
		delay(duration, function()
			self:GetService("EffectsService"):RequestEffectAll("LobProjectile", {
				Start = self.Model.Head.Position,
				Finish = targetPosition,
				Height = 64,
				Duration = travelTime,
				Model = self.Storage.Models.BoneSpiderBolt,
			})
		end)
	end
	
	delay(duration, function()
		self:SoundPlay("Spit")
	end)
	
	local index = 1
	for _ = 1, 40 do
		spit(targets[index])
		
		index += 1
		if index > #targets then
			index = 1
		end
	end
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Waiting",
		Duration = 4,
	})
end

function EnemyBoneSpider:AttackPoisonArena()
	local function poison(position)
		local cloud = self.EnemyData.EmitterPart:Clone()
		
		self:AttackActiveCircle{
			Position = position,
			Radius = 34,
			Delay = 3,
			Interval = 0.2,
			Infinite = true,
			
			OnHit = function(legend, dt)
				self:GetService"DamageService":Damage{
					Source = self,
					Target = legend,
					Amount = self.Damage * 0.5 * dt,
					Type = "Internal",
					Tags = {"Magical"},
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
	end
	
	local dungeonModel = self:GetRun().Dungeon.Model
	local corners = dungeonModel.Corners:GetChildren()
	table.insert(corners, dungeonModel.Center)
	
	for _, part in pairs(corners) do
		poison(part.Position)
	end
end

function EnemyBoneSpider:Flinch()
	-- don't
end

function EnemyBoneSpider:IsTargetValid()
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

function EnemyBoneSpider:CreateStateMachine()
	self.StateMachine = self:CreateNew"StateMachine"()

	self.StateMachine:AddState{
		Name = "Setup",
		Run = function(state, machine)
			machine:ChangeState("Sleeping")
		end,
	}

	self.StateMachine:AddState{
		Name = "Sleeping",
		OnStateChanged = function()
			self.StatusGui.Enabled = false
			self:AnimationPlay("BoneSpiderShrine", 0)
			self:AnimationLoad("BoneSpiderAwaken")
		end,
		Run = function(state, machine, dt)
			self.RangedHarassCooldown:Use()
			
			local isHurt = self.Health < self.MaxHealth:Get()
			self.Target = self:GetNearestTarget(32)
			if self:IsTargetValid() or isHurt then
				self.RangedHarassCooldown:Use(10)
				
				self:GetService("MusicService"):PlayPlaylist{"Horror of Horrors"}
				self.StatusGui.Enabled = true
				self:AnimationPlay("BoneSpiderAwaken", 0)
				delay(0.1, function()
					self:AnimationStop("BoneSpiderShrine")
				end)
				machine:ChangeState("Resting", {
					NextState = "Waiting",
					Duration = 6,
				})
			end
		end,
	}
	
	self.StateMachine:AddState{
		Name = "Waiting",
		Run = function(state, machine, dt)
			self.Target = self:GetNearestTarget(self.DetectionRange)
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
			self:AnimationPlay("BoneSpiderWalk", nil, nil, 0.5)
		end,
		
		Run = function(state, machine, dt)
			self.Frustration = self.Frustration + dt
			if self.Frustration > self.FrustrationLimit then
				self.Frustration = 0
				return self:AttackEscape()
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
			
			if attack == "Jump" then
				range = self.DetectionRange
			elseif attack == "Spit" then
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
			self:AnimationStop("BoneSpiderWalk")
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

return EnemyBoneSpider