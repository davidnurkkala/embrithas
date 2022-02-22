local Super = require(script.Parent)
local EnemyMeleeBasic = Super:Extend()

EnemyMeleeBasic.DamageType = "Bludgeoning"

function EnemyMeleeBasic:OnCreated()
	self.Target = nil
	self:CreateStateMachine()
	
	Super.OnCreated(self)
	
	if self.IdleAnimation then
		self:AnimationPlay(self.IdleAnimation)
	end
end

function EnemyMeleeBasic:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	if self:IsStunned() then return end
	
	self.StateMachine:Run(dt)
end

EnemyMeleeBasic.DetectionRange = 128
EnemyMeleeBasic.AttackRange = 6
EnemyMeleeBasic.AttackRadius = 8
EnemyMeleeBasic.AttackDelay = 1
EnemyMeleeBasic.RetreatDuration = 1
EnemyMeleeBasic.Predictive = false

EnemyMeleeBasic.RunAnimation = "GenericRun"
EnemyMeleeBasic.RunAnimationSpeed = 2

EnemyMeleeBasic.AttackAnimation = "MonsterAttackOverhead"
EnemyMeleeBasic.AttackAnimationSpeed = 1

function EnemyMeleeBasic:IsTargetValid()
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

function EnemyMeleeBasic:CreateStateMachine()
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
		OnStateChanged = function()
			self:AnimationPlay(self.RunAnimation, nil, nil, self.RunAnimationSpeed)
		end,
		
		Run = function(state, machine)
			if not self:IsTargetValid() then
				self.Target = nil
				return machine:ChangeState("Waiting")
			end
			
			local targetPosition = self.Target:GetPosition()
			local distance = self:DistanceTo(targetPosition)
			
			self:MoveTo(targetPosition)
			
			if distance < self.AttackRange then
				machine:ChangeState("Attacking")
			
			elseif distance > self.DetectionRange then
				self.Target = nil
				machine:ChangeState("Waiting")
			end
		end,
		
		OnStateWillChange = function()
			self:MoveStop()
			self:AnimationStop(self.RunAnimation)
		end,
	}
	
	self.StateMachine:AddState{
		Name = "Retreating",
		
		OnStateChanged = function(state, machine)
			state.Duration = self.RetreatDuration
			state.StrafeFactor = self:RandomSign()
			state.DistanceFactor = self:RandomFloat(0.5, 2.5)
			
			self:AnimationPlay(self.RunAnimation, nil, nil, self.RunAnimationSpeed)
		end,
		
		Run = function(state, machine, dt)
			if not self:IsTargetValid() then
				self.Target = nil
				return machine:ChangeState("Waiting")
			end
			
			local targetPosition = self.Target:GetPosition()
			local myPosition = self:GetPosition()
			local cframe = CFrame.new(targetPosition, myPosition)
			
			local runPoint = cframe.Position + (cframe.LookVector * self.AttackRange * state.DistanceFactor) + (cframe.RightVector * state.StrafeFactor * self.AttackRange)
			
			self:MoveTo(runPoint)
			
			state.Duration = state.Duration - dt
			if state.Duration <= 0 then
				machine:ChangeState("Waiting")
			end
		end,
		
		OnStateWillChange = function()
			self:MoveStop()
			self:AnimationStop(self.RunAnimation)
		end,
	}
	
	self.StateMachine:AddState{
		Name = "Attacking",
		Run = function(state, machine)
			if not self:IsTargetValid() then
				self.Target = nil
				return machine:ChangeState("Waiting")
			end
			
			local targetPosition = self.Target:GetFootPosition()
			
			local duration = self.AttackDelay
			if self.Predictive then
				targetPosition = targetPosition + self.Target:GetFlatVelocity() * duration
				
				local here = self:GetFootPosition()
				local delta = (targetPosition - here) * Vector3.new(1, 0, 1)
				local distance = delta.Magnitude
				if distance > self.AttackRange then
					targetPosition = here + (delta / distance) * self.AttackRange
				end
			end
			
			self:FaceTowards(targetPosition)
			
			self:AnimationPlay(self.AttackAnimation, nil, nil, 1 / duration * self.AttackAnimationSpeed)
			
			self:AttackCircle{
				Position = targetPosition,
				Radius = self.AttackRadius,
				Duration = duration,
				OnHit = function(legend)
					self:GetService"DamageService":Damage{
						Source = self,
						Target = legend,
						Amount = self.Damage,
						Type = self.DamageType,
					}
				end
			}
			
			machine:ChangeState("Resting", {
				NextState = "Retreating",
				Duration = duration
			})
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

return EnemyMeleeBasic