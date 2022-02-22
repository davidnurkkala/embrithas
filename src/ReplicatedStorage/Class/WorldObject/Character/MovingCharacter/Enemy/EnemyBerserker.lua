local Super = require(script.Parent)
local EnemyBerserker = Super:Extend()

EnemyBerserker.DamageType = "Slashing"

function EnemyBerserker:OnCreated()
	self.Target = nil
	self:CreateStateMachine()
	
	Super.OnCreated(self)
	
	if self.IdleAnimation then
		self:AnimationPlay(self.IdleAnimation)
	end
	
	self.Speed.Base = 24
	
	self.AttackPattern = self:CreateNew"AttackPattern"{Pattern = {
		"Slash",
		"Slice",
	}}
	self.AttackPattern:Randomize()
end

function EnemyBerserker:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	if self:IsStunned() then return end
	
	self.StateMachine:Run(dt)
end

EnemyBerserker.DetectionRange = 128
EnemyBerserker.AttackRange = 6
EnemyBerserker.AttackRadius = 8
EnemyBerserker.AttackDelay = 1
EnemyBerserker.Predictive = true

EnemyBerserker.SliceLength = 24
EnemyBerserker.SliceWidth = 12
EnemyBerserker.SliceDelay = 0.8
EnemyBerserker.SliceRange = 12

EnemyBerserker.RunAnimation = "RunSingleWeapon"
EnemyBerserker.AttackAnimation = "BerserkerAttack"

function EnemyBerserker:IsTargetValid()
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

function EnemyBerserker:CreateStateMachine()
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
			self:AnimationPlay(self.RunAnimation)
		end,
		
		Run = function(state, machine)
			if not self:IsTargetValid() then
				self.Target = nil
				return machine:ChangeState("Waiting")
			end
			
			local targetPosition = self.Target:GetPosition()
			local distance = self:DistanceTo(targetPosition)
			
			self:MoveTo(targetPosition)
			
			local attack = self.AttackPattern:Get()
			local range = self.AttackRange
			if attack == "Slice" then
				range = self.SliceRange
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
			end
			
			local attackName = self.AttackPattern:Get()
			self.AttackPattern:Next()
			
			if attackName == "Slash" then
				local function attack(cframe)
					local position = cframe.Position
					
					self:AttackCircle{
						Position = position,
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
				end
				
				local here = self:GetFootPosition()
				local there = targetPosition
				local cframe = CFrame.new(here, there)
				
				local forward = CFrame.new(0, 0, -self.AttackRadius)
				local angle = math.pi * 0.4
				
				attack(cframe * forward)
				attack(cframe * CFrame.Angles(0,  angle, 0) * forward)
				attack(cframe * CFrame.Angles(0, -angle, 0) * forward)
				
				self:FaceTowards(targetPosition)
				self:AnimationPlay(self.AttackAnimation, nil, nil, 1 / duration)
				
				machine:ChangeState("Resting", {
					NextState = "Waiting",
					Duration = duration
				})
			else
				local extraLength = self.SliceWidth / 2
				local length = self.SliceLength + extraLength
				
				local here = self:GetFootPosition()
				local there = targetPosition
				local delta = (there - here) * Vector3.new(1, 0, 1)
				local cframe = CFrame.new(here, here + delta) * CFrame.new(0, 0, (-length / 2) + extraLength)
				
				self:FaceTowards(there)
				
				self:AttackSquare{
					CFrame = cframe,
					Width = self.SliceWidth,
					Length = length,
					Duration = self.SliceDelay,
					OnHit = function(legend)
						self:GetService"DamageService":Damage{
							Source = self,
							Target = legend,
							Amount = self.Damage,
							Type = self.DamageType,
						}
					end
				}
				
				delay(self.SliceDelay - 0.5, function()
					self:AnimationPlay("GreatswordAttack0")
				end)
				
				self.StateMachine:ChangeState("Resting", {
					Duration = self.SliceDelay,
					NextState = "Waiting",
				})
			end
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

return EnemyBerserker