local Super = require(script.Parent)
local EnemyOrcGrenadier = Super:Extend()

function EnemyOrcGrenadier:OnCreated()
	self.HeaveCooldown = self:CreateNew"Cooldown"{Time = 2}
	self.DodgeCooldown = self:CreateNew"Cooldown"{Time = 12}
	
	self.Target = nil
	self:CreateStateMachine()
	
	Super.OnCreated(self)
	
	self.Speed.Base = 10
end

function EnemyOrcGrenadier:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	if self:IsStunned() then return end
	
	self.StateMachine:Run(dt)
end

EnemyOrcGrenadier.DetectionRange = 128
EnemyOrcGrenadier.HoverRange = 30

EnemyOrcGrenadier.HeaveInaccuracy = 12
EnemyOrcGrenadier.HeaveRadius = 16
EnemyOrcGrenadier.HeaveTravelTime = 1

EnemyOrcGrenadier.DodgeDistance = 16

function EnemyOrcGrenadier:Dodge()
	if not self.DodgeCooldown:IsReady() then return end
	self.DodgeCooldown:Use()
	self.HeaveCooldown:Use()
	
	local direction = CFrame.Angles(0, math.pi * 2 * math.random(), 0).LookVector
	local velocity = direction * 32
	local duration = 1
	self:FaceTowards(self:GetPosition() + velocity)
	self:Dash(velocity, duration)
	self:AnimationPlay("CombatRoll", nil, nil, 1 / duration)

	self.StateMachine:ChangeState("Resting", {
		Duration = duration,
		NextState = "Waiting",
	})
	
	self:CreateNew"TrapBomb"{
		StartCFrame = CFrame.new(self:GetFootPosition()),
		StartParent = self:GetRun().Dungeon.Model,
	}
end

function EnemyOrcGrenadier:Heave()
	if not self.HeaveCooldown:IsReady() then return end
	self.HeaveCooldown:Use()

	local duration = 0.5

	self:AnimationPlay("MonsterAttackOverhead", nil, nil, 1 / duration)

	local targetPosition = self.Target:GetFootPosition()
	local theta = math.pi * 2 * math.random()
	local r = self.HeaveInaccuracy * math.random()
	targetPosition += Vector3.new(
		math.cos(theta) * r,
		0,
		math.sin(theta) * r
	)

	self:AttackCircle{
		Position = targetPosition,
		Radius = self.HeaveRadius,
		Duration = duration + self.HeaveTravelTime,
		OnHit = function(legend)
			self:GetService"DamageService":Damage{
				Source = self,
				Target = legend,
				Amount = self.Damage,
				Type = "Bludgeoning",
			}
		end,
	}

	delay(duration, function()
		self:GetService("EffectsService"):RequestEffectAll("LobProjectile", {
			Start = self.Model.RightHand.Position,
			Finish = targetPosition,
			Height = 12,
			Duration = self.HeaveTravelTime,
			Model = self.Storage.Models.Grenade,
		})
	end)
end

function EnemyOrcGrenadier:Flinch()
	-- don't
end

function EnemyOrcGrenadier:IsTargetValid()
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

function EnemyOrcGrenadier:CreateStateMachine()
	self.StateMachine = self:CreateNew"StateMachine"()
	
	self.StateMachine:AddState{
		Name = "Waiting",
		Run = function(state, machine, dt)
			self.Target = self:GetNearestTarget(self.DetectionRange)
			if self:IsTargetValid() then
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
		
		Run = function(state, machine, dt)
			self.Target = self:GetNearestTarget(self.DetectionRange)
			if not self:IsTargetValid() then
				self.Target = nil
				return machine:ChangeState("Waiting")
			end

			local here = self.Target:GetPosition()
			local there = self:GetPosition()
			local delta = (there - here) * Vector3.new(1, 0, 1)
			local position = here + (delta.Unit * self.HoverRange)

			self:MoveTo(position)
			
			local speed = self.Root.Velocity.Magnitude
			if (speed > 2) and (not state.AnimationPlaying) then
				state.AnimationPlaying = true
				self:AnimationPlay("RunDualWield")
				self.FacingPoint = nil
			elseif (speed < 2) then
				if state.AnimationPlaying then
					state.AnimationPlaying = false
					self:AnimationStop("RunDualWield")
				end
				self.FacingPoint = here
			end
			
			local distance = delta.Magnitude
			if distance < self.DodgeDistance then
				self:Dodge()
			end
			
			self:Heave()
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

return EnemyOrcGrenadier