local Super = require(script.Parent)
local EnemyHealer = Super:Extend()

function EnemyHealer:OnCreated()
	self.Target = nil
	self:CreateStateMachine()
	
	self.HealingCooldown = self:CreateNew"Cooldown"{Time = self.HealingCooldownTime}
	
	Super.OnCreated(self)
end

function EnemyHealer:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	if self:IsStunned() then return end
	
	self.StateMachine:Run(dt)
end

EnemyHealer.DetectionRange = 128
EnemyHealer.HealingRange = 16
EnemyHealer.HealingCooldownTime = 8
EnemyHealer.HealingAmount = 0.5
EnemyHealer.FleeRange = 12

function EnemyHealer:IsTargetValid()
	if not self.Target then
		return false
	end
	
	if self.Target.Health >= self.Target.MaxHealth:Get() then
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

function EnemyHealer:IsThreatValid()
	if not self.Threat then
		return false
	end
	
	if not self:IsPointInRange(self.Threat:GetPosition(), self.DetectionRange) then
		return false
	end
	
	if not self:CanSeePoint(self.Threat:GetPosition()) then
		return false
	end
	
	return true
end

function EnemyHealer:CreateStateMachine()
	self.StateMachine = self:CreateNew"StateMachine"()
	
	self.StateMachine:AddState{
		Name = "Waiting",
		Run = function(state, machine, dt)
			self.Threat = self:GetNearestTarget(self.FleeRange)
			if self:IsThreatValid() then
				return machine:ChangeState("Retreating")
			end
			
			self.Target = self:GetNearestWoundedEnemy(self.DetectionRange)
			if self:IsTargetValid() and self.HealingCooldown:IsReady() then
				return machine:ChangeState("Chasing")
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
			self:AnimationPlay("GenericRun", nil, nil, 2)
		end,
		
		Run = function(state, machine)
			if not self:IsTargetValid() then
				self.Target = nil
				return machine:ChangeState("Waiting")
			end
			
			local targetPosition = self.Target:GetPosition()
			local distance = self:DistanceTo(targetPosition)
			
			self:MoveTo(targetPosition)
			
			if distance < self.HealingRange then
				machine:ChangeState("Healing")
			
			elseif distance > self.DetectionRange then
				self.Target = nil
				machine:ChangeState("Waiting")
			end
		end,
		
		OnStateWillChange = function()
			self:MoveStop()
			self:AnimationStop("GenericRun")
		end,
	}

	self.StateMachine:AddState{
		Name = "Healing",
		Run = function(state, machine)
			if not self:IsTargetValid() then
				self.Target = nil
				return machine:ChangeState("Waiting")
			end
			
			-- do the healing
			local healing = self.MaxHealth:Get() * self.HealingAmount
			self.Target.Health = math.min(self.Target.MaxHealth:Get(), self.Target.Health + healing)
			
			-- attach the beam momentarily
			local attachment = Instance.new("Attachment")
			attachment.Name = "EnemyHealerAttachment"
			attachment.Parent = self.Target.Root
			self.Model.Staff.Beam.Attachment1 = attachment
			game:GetService("Debris"):AddItem(attachment, 0.5)
			
			-- play the animation
			self:AnimationPlay("MagicCast")
			
			-- play a sound
			self:SoundPlay("Heal")
			
			self.HealingCooldown:Use()
			
			machine:ChangeState("Waiting")
		end,
	}
	
	self.StateMachine:AddState{
		Name = "Retreating",
		
		OnStateChanged = function(state, machine)
			state.Duration = 1
			state.StrafeFactor = self:RandomSign()
			state.DistanceFactor = self:RandomFloat(1.25, 2)
			
			self:AnimationPlay("GenericRun", nil, nil, 2)
		end,
		
		Run = function(state, machine, dt)
			if not self:IsThreatValid() then
				self.Threat = nil
				return machine:ChangeState("Waiting")
			end
			
			local threatPosition = self.Threat:GetPosition()
			local myPosition = self:GetPosition()
			local cframe = CFrame.new(threatPosition, myPosition)
			
			local runPoint = cframe.Position + (cframe.LookVector * self.FleeRange * state.DistanceFactor) + (cframe.RightVector * state.StrafeFactor * self.FleeRange)
			
			self:MoveTo(runPoint)
			
			state.Duration = state.Duration - dt
			if state.Duration <= 0 then
				machine:ChangeState("Waiting")
			end
		end,
		
		OnStateWillChange = function()
			self:MoveStop()
			self:AnimationStop("GenericRun")
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

return EnemyHealer