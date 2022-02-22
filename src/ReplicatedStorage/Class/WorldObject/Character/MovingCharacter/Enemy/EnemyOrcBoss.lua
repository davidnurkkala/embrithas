local Super = require(script.Parent)
local EnemyOrcBoss = Super:Extend()

EnemyOrcBoss.Resilient = true

function EnemyOrcBoss:OnCreated()
	self.Target = nil
	self:CreateStateMachine()
	
	self.AttackPattern = self:CreateNew"AttackPattern"{Pattern = {
		"Basic", 2,
		"Predictive", 2,
		"Shockwave",
		"Basic", 2,
		"Predictive", 2,
		"Shockwave",
		"GroundSlam",
		"Basic", 2,
		"Predictive", 2,
		"Leap",
		"Predictive",
		"Leap", 2,
		"Predictive", 2,
		"Shockwave",
		"Leap", 3,
		"Predictive", 2,
		"GroundSlam",
	}}
	
	if self.AttackPatternRandomized then
		self.AttackPattern.Index = math.random(1, #self.AttackPattern.Pattern)
	end
	
	Super.OnCreated(self)
	
	if not self.MusicDisabled then
		self:GetService("MusicService"):PlayPlaylist{"Strength of the Orcs"}
	end
end

function EnemyOrcBoss:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	self.StateMachine:Run(dt)
end

EnemyOrcBoss.DetectionRange = 128
EnemyOrcBoss.AttackRange = 12

function EnemyOrcBoss:IsTargetValid()
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

function EnemyOrcBoss:AttackPosition(position, duration)
	self:FaceTowards(position)
	
	self:AnimationPlay("BigOrcAttack1", nil, nil, 1 / duration)
	
	self:AttackCircle{
		Position = position,
		Radius = 8,
		Duration = duration,
		OnHit = function(legend)
			self:GetService"DamageService":Damage{
				Source = self,
				Target = legend,
				Amount = self.Damage,
				Type = "Bludgeoning",
			}
		end,
	}
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Chasing",
		Duration = 1,
	})
end

function EnemyOrcBoss:AttackBasic()
	local position = self.Target:GetFootPosition()
	self:AttackPosition(position, 0.75)
end

function EnemyOrcBoss:AttackPredictive()
	local position = self.Target:GetFootPosition()
	local velocity = self.Target.Root.Velocity * Vector3.new(1, 0, 1)
	local duration = 0.75
	local predictedPosition = position + velocity * duration
	local here = self:GetFootPosition()
	local delta = (predictedPosition - here) * Vector3.new(1, 0, 1)
	local distance = delta.Magnitude
	if distance > self.AttackRange then
		predictedPosition = here + (delta / distance) * self.AttackRange
	end
	self:AttackPosition(predictedPosition, duration)
end

function EnemyOrcBoss:Jump(position, speed)
	local initialDelay = 0.5 / speed
	local airDelay = 1 / 6 / speed
	local hangTime = 0.5 / speed
	
	self:AnimationPlay("BigOrcJump", nil, nil, speed)
	
	delay(initialDelay, function()
		local start = self.Root.CFrame
		local delta = (position - start.Position) * Vector3.new(1, 0, 1)
		local apex = start + Vector3.new(0, 64, 0)
		
		self.Root.Anchored = true
		self:TweenNetwork{
			Object = self.Root,
			Goals = {CFrame = apex},
			Duration = airDelay,
			Direction = Enum.EasingDirection.In,
		}.Completed:Connect(function()
			self.Root.CFrame = apex + delta
			
			local track = self.Tracks["BigOrcJump"]
			local speed = track.Speed
			track:AdjustSpeed(0)
			
			wait(hangTime)
			
			track:AdjustSpeed(speed)
			self:TweenNetwork{
				Object = self.Root,
				Goals = {CFrame = start + delta},
				Duration = airDelay,
				Direction = Enum.EasingDirection.Out,
			}.Completed:Connect(function()
				self.Root.Anchored = false
			end)
		end)
	end)
	
	return initialDelay + (airDelay * 2) + hangTime
end

function EnemyOrcBoss:AttackGroundSlam()
	local position = self:GetFootPosition()
	local duration = self:Jump(position, 1)
	
	self:AttackCircle{
		Position = position,
		Radius = 20,
		Duration = duration,
		OnHit = function(legend)
			self:GetService"DamageService":Damage{
				Source = self,
				Target = legend,
				Amount = self.Damage,
				Type = "Bludgeoning",
			}
		end,
		Sound = self.EnemyData.Sounds.Explosion1,
	}
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Chasing",
		Duration = duration + 0.5,
	})
end

function EnemyOrcBoss:AttackLeap()
	local position = self.Target:GetFootPosition()
	local duration = self:Jump(position, 2)
	
	self:AttackCircle{
		Position = position,
		Radius = 8,
		Duration = duration,
		OnHit = function(legend)
			self:GetService"DamageService":Damage{
				Source = self,
				Target = legend,
				Amount = self.Damage,
				Type = "Bludgeoning",
			}
		end,
		Sound = self.EnemyData.Sounds.Explosion1,
	}
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Chasing",
		Duration = duration + 0.5,
	})
end

function EnemyOrcBoss:AttackShockwave()
	local duration = 2
	local lineCount = 6
	local explosionCount = 4
	local spacing = 14
	local pause = 0.1
	local radius = 8
	
	self:AnimationPlay("BigOrcAttack1", nil, nil, 1 / duration)
	
	local position = self:GetFootPosition()
	local startTheta = math.pi * 2 * math.random()
	
	for step = 1, lineCount do
		local theta = startTheta + math.pi * 2 / lineCount * step
		for explosion = 1, explosionCount do
			delay((explosion - 1) * pause, function()
				local r = explosion * spacing
				local delta = Vector3.new(math.cos(theta) * r, 0, math.sin(theta) * r)
				self:AttackCircle{
					Position = position + delta,
					Radius = radius,
					Duration = duration,
					OnHit = function(legend)
						self:GetService"DamageService":Damage{
							Source = self,
							Target = legend,
							Amount = self.Damage,
							Type = "Bludgeoning",
						}
					end,
					Sound = self.Storage.Sounds.Silence,
				}
			end)
		end
	end
	
	self:AttackCircle{
		Position = position,
		Radius = radius,
		Duration = duration,
		OnHit = function(legend)
			self:GetService"DamageService":Damage{
				Source = self,
				Target = legend,
				Amount = self.Damage,
				Type = "Bludgeoning",
			}
		end,
		Sound = self.EnemyData.Sounds.Explosion2,
	}
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Chasing",
		Duration = 3,
	})
end

function EnemyOrcBoss:CreateStateMachine()
	self.StateMachine = self:CreateNew"StateMachine"()
	
	self.StateMachine:AddState{
		Name = "Waiting",
		Run = function(state, machine)
			self.Target = self:GetNearestTarget(self.DetectionRange)
			if self:IsTargetValid() then
				machine:ChangeState("Chasing")
			end
		end,
	}
	
	self.StateMachine:AddState{
		Name = "Chasing",
		OnStateChanged = function()
			self:AnimationPlay("GenericRun", nil, nil, 0.5)
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
			
			if attack == "GroundSlam" then
				range = 20
			elseif attack == "Leap" then
				range = 64
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

return EnemyOrcBoss