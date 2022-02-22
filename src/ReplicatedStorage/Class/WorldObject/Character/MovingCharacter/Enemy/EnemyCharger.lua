local Super = require(script.Parent)
local EnemyCharger = Super:Extend()

EnemyCharger.DamageType = "Bludgeoning"

function EnemyCharger:OnCreated()
	self.Target = nil
	self:CreateStateMachine()
	
	Super.OnCreated(self)
	
	self.MaxHealth.Base = 150
	self.Health = self.MaxHealth:Get()
end

function EnemyCharger:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	if self:IsStunned() then return end
	
	self.StateMachine:Run(dt)
end

EnemyCharger.DetectionRange = 128
EnemyCharger.ChargeDistance = 18
EnemyCharger.ChargeWidth = 6

function EnemyCharger:IsTargetValid()
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

function EnemyCharger:CreateStateMachine()
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
			
			if distance < self.ChargeDistance then
				machine:ChangeState("Charging")
			
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
		Name = "Charging",
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
			
			local duration = 2
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
						Type = self.DamageType,
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
				NextState = "Waiting",
				Duration = duration + 1,
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

return EnemyCharger