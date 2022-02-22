local Super = require(script.Parent)
local EnemySwordAndShield = Super:Extend()

function EnemySwordAndShield:OnCreated()
	self.Target = nil
	self:CreateStateMachine()
	
	self.ChargeCooldown = self:CreateNew"Cooldown"{Time = 10}
	
	Super.OnCreated(self)
end

function EnemySwordAndShield:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	if self:IsStunned() then return end
	
	self.StateMachine:Run(dt)
end

EnemySwordAndShield.DetectionRange = 128
EnemySwordAndShield.AttackRange = 6
EnemySwordAndShield.AttackRadius = 6
EnemySwordAndShield.ChargeDistance = 18
EnemySwordAndShield.ChargeWidth = 6

function EnemySwordAndShield:IsTargetValid()
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

function EnemySwordAndShield:AttackPosition(position, attackNumber)
	local here = self:GetFootPosition()
	local delta = (position - here) * Vector3.new(1, 0, 1)
	local distance = delta.Magnitude
	if distance > self.AttackRange then
		position = here + (delta / distance) * self.AttackRange
	end
	
	self:FaceTowards(position)
	
	local duration = 0.75
	local hitDelay = 0.5
	local animationSpeed = 1.5
	
	delay(duration - (hitDelay / animationSpeed), function()
		self:AnimationPlay("SwordShieldAttack"..attackNumber, nil, nil, animationSpeed)
	end)
	
	self:AttackCircle{
		Position = position,
		Radius = self.AttackRadius,
		Duration = duration,
		OnHit = function(legend)
			self:GetService"DamageService":Damage{
				Source = self,
				Target = legend,
				Amount = self.Damage,
				Type = "Slashing",
			}
		end
	}
end

function EnemySwordAndShield:CreateStateMachine()
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
			self:AnimationPlay("RunSwordShield")
		end,
		
		Run = function(state, machine)
			if not self:IsTargetValid() then
				self.Target = nil
				return machine:ChangeState("Waiting")
			end
			
			local targetPosition = self.Target:GetPosition()
			local distance = self:DistanceTo(targetPosition)
			
			self:MoveTo(targetPosition)
			
			if self.ChargeCooldown:IsReady() then
				if distance < self.ChargeDistance then
					return machine:ChangeState("Charging")
				end
			end
			
			if distance < self.AttackRange then
				machine:ChangeState("Attacking")
			
			elseif distance > self.DetectionRange then
				self.Target = nil
				machine:ChangeState("Waiting")
			end
		end,
		
		OnStateWillChange = function()
			self:MoveStop()
			self:AnimationStop("RunSwordShield")
		end,
	}
	
	self.StateMachine:AddState{
		Name = "Retreating",
		
		OnStateChanged = function(state, machine)
			state.Duration = 1
			state.StrafeFactor = self:RandomSign()
			state.DistanceFactor = self:RandomFloat(0.5, 2.5)
			
			self:AnimationPlay("RunSwordShield")
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
				machine:ChangeState("Chasing")
			end
		end,
		
		OnStateWillChange = function()
			self:MoveStop()
			self:AnimationStop("RunSwordShield")
		end,
	}
	
	self.StateMachine:AddState{
		Name = "Charging",
		
		OnStateChanged = function(state, machine)
			self.ChargeCooldown:Use()
		end,
		
		Run = function(state, machine)
			if not self:IsTargetValid() then
				self.Target = nil
				return machine:ChangeState("Waiting")
			end
			
			local here = self:GetPosition()
			local there = self.Target:GetPosition()
			local delta = (there - here) * Vector3.new(1, 0, 1)
			
			local _, point = self:Raycast(Ray.new(here, delta.Unit * self.ChargeDistance))
			there = point
			delta = (there - here) * Vector3.new(1, 0, 1)
			
			local distance = delta.Magnitude
			
			self:FaceTowards(there)
			
			local duration = 1.5
			local halfDuration = duration / 2
			self:AnimationPlay("ShieldCharge", nil, nil, 1 / duration)
			
			local myFoot = self:GetFootPosition()
			local targetFoot = self.Target:GetFootPosition()
			local delta = (targetFoot - myFoot) * Vector3.new(1, 0, 1)
			targetFoot = myFoot + delta
			local cframe = CFrame.new(myFoot, targetFoot) * CFrame.new(0, 0, -distance / 2)
			
			self:AttackSquare{
				CFrame = cframe,
				Width = self.ChargeWidth,
				Length = distance,
				Duration = halfDuration,
				OnHit = function(legend)
					self:GetService"DamageService":Damage{
						Source = self,
						Target = legend,
						Amount = self.Damage,
						Type = "Bludgeoning",
					}
				end
			}
			
			self:Channel(halfDuration, nil, function()
				local dashDuration = 0.2
				local there = self.Root.CFrame + (cframe.LookVector * distance)
				
				self:Tween(self.Root, {CFrame = there}, dashDuration, Enum.EasingStyle.Linear)
				self:GetService("EffectsService"):RequestEffectAll("Tween", {
					Object = self.Root,
					Goals = {CFrame = there},
					Duration = dashDuration,
					Style = Enum.EasingStyle.Linear
				})
				
				delay(dashDuration, function()
					self:AnimationStop("ShieldCharge")
				end)
			end)
			
			machine:ChangeState("Resting", {
				NextState = "Chasing",
				Duration = duration,
			})
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
			
			self:AttackPosition(targetPosition, 0)
			
			machine:ChangeState("Resting", {
				NextState = "AttackingPredictive",
				Duration = 0.75
			})
		end,
	}
	
	self.StateMachine:AddState{
		Name = "AttackingPredictive",
		Run = function(state, machine)
			if not self:IsTargetValid() then
				self.Target = nil
				return machine:ChangeState("Waiting")
			end
			
			local targetPosition = self.Target:GetFootPosition()
			local targetVelocity = self.Target.Root.Velocity * Vector3.new(1, 0, 1)
			local duration = 0.75
			targetPosition = targetPosition + targetVelocity * duration
			
			self:AttackPosition(targetPosition, 1)
			
			machine:ChangeState("Resting", {
				NextState = "Retreating",
				Duration = 1
			})
		end
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

return EnemySwordAndShield