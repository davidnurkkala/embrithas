local Super = require(script.Parent)
local EnemyAssassin = Super:Extend()

function EnemyAssassin:OnCreated()
	self.Target = nil
	self:CreateStateMachine()
	
	Super.OnCreated(self)
	
	self:AnimationPlay("AssassinIdle")
end

function EnemyAssassin:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	if self:IsStunned() then return end
	
	self.StateMachine:Run(dt)
end

EnemyAssassin.DetectionRange = 128
EnemyAssassin.AttackRadius = 6
EnemyAssassin.AttackDelay = 1
EnemyAssassin.RestDuration = 1
EnemyAssassin.HideDuration = 2

function EnemyAssassin:IsTargetValid()
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

function EnemyAssassin:CreateStateMachine()
	self.StateMachine = self:CreateNew"StateMachine"()
	
	self.StateMachine:AddState{
		Name = "Waiting",
		Run = function(state, machine, dt)
			self.Target = self:GetNearestTarget(self.DetectionRange)
			if self:IsTargetValid() then
				machine:ChangeState("Hiding", {
					Duration = self.HideDuration,
				})
			end
			
			self:StuckCheck(dt)
		end,
		OnStateWillChange = function()
			self:StuckReset()
		end
	}
	
	self.StateMachine:AddState{
		Name = "Hiding",
		OnStateChanged = function(state)
			self:SetHidden(true)
		end,
		Run = function(state, machine, dt)
			state.Duration = state.Duration - dt
			if state.Duration <= 0 then
				if not self.Target then
					return machine:ChangeState("Waiting")
				end
				
				local targetPosition = self.Target:GetFootPosition() + self.Target:GetFlatVelocity() * self.AttackDelay
				if not self:DoesPointHaveFloor(targetPosition, 2) then
					targetPosition = self.Target:GetFootPosition()
				end
				
				local position do
					self:Attempt(8, function()
						local theta = math.pi * 2 * math.random()
						local dx = math.cos(theta) * self.AttackRadius
						local dz = math.sin(theta) * self.AttackRadius
						position = Vector3.new(
							targetPosition.X + dx,
							self:GetPosition().Y,
							targetPosition.Z + dz
						)
						return self:DoesPointHaveFloor(position)
					end)
				end
				
				self.Root.CFrame = CFrame.new(position)
				self:FaceTowards(targetPosition)
				
				machine:ChangeState("Attacking", {
					TargetPosition = targetPosition
				})
			end
		end,
		OnStateWillChange = function(state)
			self:SetHidden(false)
		end,
	}
	
	self.StateMachine:AddState{
		Name = "Attacking",
		Run = function(state, machine)
			if not self:IsTargetValid() then
				self.Target = nil
				return machine:ChangeState("Waiting")
			end
			
			local targetPosition = state.TargetPosition
			
			local duration = self.AttackDelay
			self:AnimationPlay("AssassinAttack", nil, nil, 1 / duration)
			
			self:AttackCircle{
				Position = targetPosition,
				Radius = self.AttackRadius,
				Duration = duration,
				OnHit = function(legend)
					self:GetService"DamageService":Damage{
						Source = self,
						Target = legend,
						Amount = self.Damage,
						Type = "Piercing",
					}
				end
			}
			
			machine:ChangeState("Resting", {
				NextState = "Hiding",
				NextStateData = {
					Duration = self.HideDuration
				},
				Duration = duration + self.RestDuration
			})
		end,
	}
	
	self.StateMachine:AddState{
		Name = "Resting",
		Run = function(state, machine, dt)
			state.Duration = state.Duration - dt
			if state.Duration <= 0 then
				machine:ChangeState(state.NextState, state.NextStateData)
			end
		end
	}
end

return EnemyAssassin