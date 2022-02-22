local Super = require(script.Parent)
local EnemyLostChampion = Super:Extend()

EnemyLostChampion.Resilient = true

function EnemyLostChampion:OnCreated()
	self.Target = nil
	self:CreateStateMachine()
	
	self.AttackPattern = self:CreateNew"AttackPattern"{Pattern = {
			"Ice",
			"Swipe",
			"Punches",
			"Roll",
			"Punches",
			"Roll",
			"Punches", 2,
			"Roll",
			"Swipe",
			"Roll",
			"Swipe",
			"Punches",
			"Roll",
			"Swipe",
			"Punches",
			"Roll",
			"Swipe",
			"Punches",
			"Spin",
			"Punches", 3,
			"Roll",
	}}
	
	Super.OnCreated(self)
	
	self:AnimationPlay("EvrigBossIdle")
	self:GetService("MusicService"):PlayPlaylist{"Cursed Warrior"}
	
	self.Speed.Base = 24
end

function EnemyLostChampion:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	self.StateMachine:Run(dt)
end

EnemyLostChampion.DetectionRange = 128
EnemyLostChampion.AttackRange = 12

EnemyLostChampion.Frustration = 0
EnemyLostChampion.FrustrationLimit = 2

function EnemyLostChampion:AttackIce()
	local pause = 1
	local duration = 30
	
	local ice = self.EnemyData.EmitterPart:Clone()
	local emitter = ice.EmitterAttachment.Emitter
	local position = self:GetFootPosition()
	
	self:AttackActiveCircle{
		Position = position,
		Radius = 32,
		Delay = pause,
		Duration = duration,
		Interval = 0.2,
		
		OnHit = function(legend, dt)
			self:GetService"DamageService":Damage{
				Source = self,
				Target = legend,
				Amount = self.Damage * 0.2 * dt,
				Type = "Cold",
				Tags = {"Magical"},
			}
			
			self:ApplyFrostyToLegend(legend, self.Damage)
		end,
		
		OnStarted = function(t)
			ice.Position = position + Vector3.new(0, 2, 0)
			ice.Parent = workspace.Effects
			self:SoundPlay("IceSummon")
		end,
		
		OnCleanedUp = function(t)
			emitter.Enabled = false
			game:GetService("Debris"):AddItem(ice, emitter.Lifetime.Max)
		end
	}
	
	self:AnimationPlay("EvrigBossAttackSwipe", nil, nil, 1 / pause)
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Waiting",
		Duration = pause,
	})
end

function EnemyLostChampion:AttackPunches()
	local radius = 8
	local duration = 0.75
	
	local here = self:GetFootPosition()
	local there = self.Target:GetFootPosition() + (self.Target:GetFlatVelocity() * duration * 0.5)
	local delta = (there - here) * Vector3.new(1, 0, 1)
	local position = here + delta.Unit * radius
	
	self:FaceTowards(position)
	
	local function attack(pause)
		self:AttackCircle{
			Position = position,
			Radius = radius,
			Duration = pause,
			OnHit = function(legend)
				self:GetService"DamageService":Damage{
					Source = self,
					Target = legend,
					Amount = self.Damage,
					Type = "Bludgeoning",
				}
			end,
		}
	end
	
	attack(duration)
	delay(duration, function()
		for _ = 1, 2 do
			attack(0.1)
			wait(0.1)
		end
	end)
	
	self:AnimationPlay("EvrigBossAttackTriple", nil, nil, 1 / duration)
	
	self.StateMachine:ChangeState("Resting", {
		Duration = duration + 0.25,
		NextState = "Waiting",
	})
end

function EnemyLostChampion:AttackRoll()
	local direction = CFrame.Angles(0, math.pi * 2 * math.random(), 0).LookVector
	local velocity = direction * 64
	local duration = 0.5
	self:FaceTowards(self:GetPosition() + velocity)
	self:Dash(velocity, duration)
	self:AnimationPlay("EvrigBossRoll", nil, nil, 1 / duration)
	
	self.StateMachine:ChangeState("Resting", {
		Duration = duration,
		NextState = "Waiting",
	})
end

function EnemyLostChampion:AttackSwipe()
	local function launch(speed)
		if not self:IsTargetValid() then return end
		
		self:AnimationPlay("EvrigBossAttackSwipe", nil, nil, speed)
		
		local width = 16
		
		local crescent = self.Storage.Models.Crescent:Clone()
		crescent.Size = Vector3.new(width, 0, 4)
		
		local model = Instance.new("Model")
		crescent.Parent = model
		model.Name = "AirSlice"
		model.PrimaryPart = crescent
		
		local projectileSpeed = 96
		
		local here = self:GetPosition()
		local there = self.Target:GetPosition()
		local distance = (there - here).Magnitude
		local t = distance / projectileSpeed
		there = there + self.Target:GetFlatVelocity() * t
		
		local delta = (there - here) * Vector3.new(1, 0, 1)
		
		self:FaceTowards(there)
		
		local function launchProjectile()
			local projectile = self:CreateNew"Projectile"{
				Model = model,
				CFrame = CFrame.new(here),
				Velocity = delta.Unit * projectileSpeed,
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
	end
	
	local ratio = self.Health / self.MaxHealth:Get()
	
	if (ratio < 0.5) then
		launch(2)
		delay(0.5, function()
			launch(2)
			wait(0.5)
			launch(2)
		end)
	else
		launch(1)
		delay(1, function()
			launch(2)
		end)
	end
		
	self.StateMachine:ChangeState("Resting", {
		NextState = "Waiting",
		Duration = 1.5,
	})
end

function EnemyLostChampion:AttackSpin()
	local duration = 8
	
	local function getPosition()
		return self:GetFootPosition()
	end
	
	local soundCooldown = self:CreateNew"Cooldown"{Time = 0.2}
	
	self:AttackActiveCircle{
		Position = getPosition(),
		Radius = 16,
		Duration = duration,
		
		OnHit = function(legend, dt)
			self:GetService"DamageService":Damage{
				Source = self,
				Target = legend,
				Amount = self.Damage * dt,
				Type = "Slashing",
			}
		end,
		
		OnTicked = function(t, dt)
			t:SetPosition(getPosition())
			
			if soundCooldown:IsReady() then
				soundCooldown:Use()
				self:SoundPlay("Spin")
			end
		end,
	}
	
	self.StateMachine:ChangeState("Spinning", {
		Duration = duration,
	})
end

function EnemyLostChampion:Flinch()
	-- don't
end

function EnemyLostChampion:IsTargetValid()
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

function EnemyLostChampion:CreateStateMachine()
	self.StateMachine = self:CreateNew"StateMachine"()
	
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
			self:AnimationPlay("EvrigBossWalk", nil, nil, 2)
		end,
		
		Run = function(state, machine, dt)
			self.Frustration = self.Frustration + dt
			if self.Frustration > self.FrustrationLimit then
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
			
			if attack == "Ice" then
				range = self.DetectionRange
			elseif attack == "Spin" then
				range = 32
			elseif attack == "Punches" then
				range = 12
			elseif attack == "Swipe" then
				range = 64
			elseif attack == "Roll" then
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
			self:AnimationStop("EvrigBossWalk")
		end,
	}
	
	self.StateMachine:AddState{
		Name = "Spinning",
		OnStateChanged = function()
			self:AnimationPlay("EvrigBossAttackSpin", nil, nil, 4)
			
			self.Speed.Percent = self.Speed.Percent - 0.5
		end,
		
		Run = function(state, machine, dt)
			state.Duration = state.Duration - dt
			if state.Duration <= 0 then
				machine:ChangeState("Waiting")
			end
			
			self.Target = self:GetNearestTarget(self.DetectionRange)
			if not self:IsTargetValid() then
				return
			end
			
			local targetPosition = self.Target:GetPosition()
			self:MoveTo(targetPosition)
		end,
		
		OnStateWillChange = function()
			self:AnimationStop("EvrigBossAttackSpin")
			
			self.Speed.Percent = self.Speed.Percent + 0.5
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

return EnemyLostChampion