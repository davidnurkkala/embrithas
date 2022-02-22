local Super = require(script.Parent)
local EnemyMaul = Super:Extend()

function EnemyMaul:OnCreated()
	self.Target = nil
	self:CreateStateMachine()
	
	Super.OnCreated(self)
end

function EnemyMaul:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	if self:IsStunned() then return end
	
	self.StateMachine:Run(dt)
end

EnemyMaul.DetectionRange = 128
EnemyMaul.RetreatDuration = 1

EnemyMaul.ShockwaveCount = 4
EnemyMaul.ShockwaveRadius = 6
EnemyMaul.ShockwaveDelay = 0.8
EnemyMaul.ShockwavePause = 0.05
EnemyMaul.ShockwaveOverlap = 1.75

function EnemyMaul:GetShockwaveRange()
	return self.ShockwaveCount * self.ShockwaveRadius * self.ShockwaveOverlap
end

function EnemyMaul:AttackShockwave()
	local here = self:GetFootPosition()
	local there = self.Target:GetFootPosition() + self.Target:GetFlatVelocity() * self.ShockwaveDelay 
	local delta = (there - here) * Vector3.new(1, 0, 1)
	local direction = delta.Unit
	
	for shockwaveNumber = 0, self.ShockwaveCount - 1 do
		local distance = self.ShockwaveRadius * self.ShockwaveOverlap * shockwaveNumber
		delay(self.ShockwavePause * shockwaveNumber, function()
			if not self.Active then return end
			
			self:AttackCircle{
				Position = here + direction * distance,
				Radius = self.ShockwaveRadius,
				Duration = self.ShockwaveDelay,
				OnHit = function(legend)
					self:GetService"DamageService":Damage{
						Source = self,
						Target = legend,
						Amount = self.Damage,
						Type = "Bludgeoning",
					}
				end,
				Sound = (shockwaveNumber == 0) and self.EnemyData.Sounds.Hit or self.Storage.Sounds.Silence
			}
		end)
	end
	
	self:FaceTowards(there)
	
	delay(self.ShockwaveDelay - 0.5, function()
		self:AnimationPlay("MaulAttack0")
	end)
	
	self.StateMachine:ChangeState("Resting", {
		Duration = self.ShockwaveDelay,
		NextState = "Retreating",
	})
end

function EnemyMaul:IsTargetValid()
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

function EnemyMaul:CreateStateMachine()
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
			self:AnimationPlay("RunSingleWeapon")
			self.JumpFrustration = 0
		end,
		
		Run = function(state, machine, dt)
			if not self:IsTargetValid() then
				self.Target = nil
				return machine:ChangeState("Waiting")
			end
			
			local targetPosition = self.Target:GetPosition()
			local distance = self:DistanceTo(targetPosition)
			
			self:MoveTo(targetPosition)
			
			if distance < self:GetShockwaveRange() then
				self:AttackShockwave()
			end
		end,
		
		OnStateWillChange = function()
			self:MoveStop()
			self:AnimationStop("RunSingleWeapon")
		end,
	}
	
	self.StateMachine:AddState{
		Name = "Retreating",
		
		OnStateChanged = function(state, machine)
			state.Duration = self.RetreatDuration
			state.StrafeFactor = self:RandomSign()
			state.DistanceFactor = self:RandomFloat(0.25, 0.5)
			
			self:AnimationPlay("RunSingleWeapon")
		end,
		
		Run = function(state, machine, dt)
			if not self:IsTargetValid() then
				self.Target = nil
				return machine:ChangeState("Waiting")
			end
			
			local targetPosition = self.Target:GetPosition()
			local myPosition = self:GetPosition()
			local cframe = CFrame.new(targetPosition, myPosition)
			
			local range = self:GetShockwaveRange()
			local runPoint = cframe.Position + (cframe.LookVector * range * state.DistanceFactor) + (cframe.RightVector * state.StrafeFactor * range)
			
			self:MoveTo(runPoint)
			
			state.Duration = state.Duration - dt
			if state.Duration <= 0 then
				machine:ChangeState("Waiting")
			end
		end,
		
		OnStateWillChange = function()
			self:MoveStop()
			self:AnimationStop("RunSingleWeapon")
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

return EnemyMaul