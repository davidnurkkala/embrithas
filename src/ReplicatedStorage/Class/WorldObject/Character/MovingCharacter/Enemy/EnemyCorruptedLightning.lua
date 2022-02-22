local Super = require(script.Parent)
local Enemy = Super:Extend()

Enemy.DetectionRange = 256

Enemy.FleeRange = 20
Enemy.FleeSpeed = 64
Enemy.FleeAngle = math.pi / 6

Enemy.BlastLength = 32
Enemy.BlastWidth = 8
Enemy.BlastAnimation = "LightningElementalBlast"

Enemy.CastRange = 64
Enemy.CastRadius = 10
Enemy.CastAnimation = "LightningElementalCast"

Enemy.RunAnimation = "LightningElementalWalk"

function Enemy:OnCreated()
	self.Target = nil
	self:CreateStateMachine()
	
	Super.OnCreated(self)
end

function Enemy:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	self:ValidateTarget()
	
	if self:IsStunned() then return end
	
	self.StateMachine:Run(dt)
end

function Enemy:IsTargetValid()
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

function Enemy:ValidateTarget()
	if not self:IsTargetValid() then
		self.Target = nil
	end
end

function Enemy:ReactToTarget()
	if not self:IsTargetValid() then
		self.StateMachine:ChangeState("Waiting")
		return
	end
	
	local distance = self:DistanceTo(self.Target:GetPosition())

	if distance < self.FleeRange then
		local fleeDistance = math.random(64, 128)
		local fleeDuration = fleeDistance / self.FleeSpeed
		
		local here = self.Target:GetPosition()
		local there = self:GetPosition()
		local delta = (there - here) * Vector3.new(1, 0, 1)
		local cframe = CFrame.new(here, here + delta)
		cframe *= CFrame.Angles(0, self:RandomFloat(-self.FleeAngle, self.FleeAngle), 0)
		local fleeDirection = cframe.LookVector
		
		self.StateMachine:ChangeState("Fleeing", {
			Direction = fleeDirection,
			Duration = fleeDuration,
		})
	elseif distance < self.CastRange then
		self.StateMachine:ChangeState("Casting")
	else
		self.StateMachine:ChangeState("Chasing")
	end
end

function Enemy:CreateStateMachine()
	self.StateMachine = self:CreateNew"StateMachine"()
	
	self.StateMachine:AddState{
		Name = "Waiting",
		Run = function(state, machine, dt)
			self.Target = self:GetNearestTarget(self.DetectionRange)
			if self:IsTargetValid() then
				self:ReactToTarget()
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
			self.Target = self:GetNearestTarget(self.DetectionRange)
			
			self:ValidateTarget()
			if not self.Target then
				return machine:ChangeState("Waiting")
			end
			
			local targetPosition = self.Target:GetPosition()
			
			self:MoveTo(targetPosition)
			self:ReactToTarget()
		end,
		
		OnStateWillChange = function()
			self:MoveStop()
			self:AnimationStop(self.RunAnimation)
		end,
	}
	
	self.StateMachine:AddState{
		Name = "Fleeing",
		
		OnStateChanged = function(state)
			self:AnimationPlay(self.RunAnimation)
			
			state.SpeedDelta = self.FleeSpeed - self.Speed:Get()
			self.Speed.Flat += state.SpeedDelta
		end,
		
		Run = function(state, machine, dt)
			local length = 6
			
			-- potentially bounce off hazards
			local ray = Ray.new(self:GetPosition(), state.Direction * length)
			local part, point, normal = self:Raycast(ray)
			if part then
				state.Direction = state.Direction - 2 * state.Direction:Dot(normal) * normal
			end
			
			self:MoveTo(self:GetPosition() + state.Direction * length)
			state.Duration -= dt
			
			if state.Duration <= 0 then
				machine:ChangeState("Blasting")
			end
		end,
		
		OnStateWillChange = function(state)
			self:MoveStop()
			self:AnimationStop(self.RunAnimation)
			
			self.Speed.Flat -= state.SpeedDelta
		end,
	}
	
	self.StateMachine:AddState{
		Name = "Casting",
		
		Run = function(state, machine)
			self:ValidateTarget()
			if not self.Target then
				return machine:ChangeState("Waiting")
			end
			
			local attackDuration = 1 / self.AttackSpeed
			local restDuration = 0.5 / self.RestSpeed
			
			local position = self.Target:GetFootPosition() + self.Target:GetFlatVelocity() * attackDuration + self:InaccuracyDelta(self.CastRadius / 2)
			
			self:AttackCircle{
				Position = position,
				Radius = self.CastRadius,
				Duration = attackDuration,
				OnHit = self:DamageFunc(1, "Electrical"),
				Sound = self.Storage.Sounds.Silence,
				
				OnEnded = function()
					self:GetService("EffectsService"):RequestEffectAll("Thunderstrike", {
						Position = position,
					})
				end,
			}
			
			self:FaceTowards(position)
			self:AnimationPlay(self.CastAnimation, nil, nil, self.AttackSpeed)
			
			machine:ChangeState("Resting", {
				Duration = attackDuration + restDuration,
				NextState = "Waiting",
			})
		end,
	}
	
	self.StateMachine:AddState{
		Name = "Blasting",
		
		Run = function(state, machine)
			self:ValidateTarget()
			if not self.Target then
				return machine:ChangeState("Waiting")
			end
			
			local attackDuration = 1 / self.AttackSpeed
			local restDuration = 0.5 / self.RestSpeed
			
			local there = self.Target:GetFootPosition()
			local here = self:GetFootPosition()
			local delta = (there - here) * Vector3.new(1, 0, 1)
			local cframe = CFrame.new(here, here + delta) * CFrame.new(0, 0, -self.BlastLength / 2)
			
			self:AttackSquare{
				CFrame = cframe,
				Width = self.BlastWidth,
				Length = self.BlastLength,
				Duration = attackDuration,
				OnHit = self:DamageFunc(1, "Electrical"),
				Sound = self.Storage.Sounds.ElectricSpark,
				
				OnEnded = function()
					local start = here + Vector3.new(0, 3, 0)
					local finish = start + cframe.LookVector * self.BlastLength
					
					self:GetService("EffectsService"):RequestEffectAll("ElectricSpark", {
						Start = start,
						Finish = finish,
						SegmentCount = 8,
						Radius = self.BlastWidth / 2,
						Duration = 0.5,
						PartArgs = {
							BrickColor = BrickColor.new("Electric blue"),
							Material = Enum.Material.Neon,
						}
					})
				end,
			}
			
			self:FaceTowards(there)
			self:AnimationPlay(self.BlastAnimation, nil, nil, self.AttackSpeed)
			
			machine:ChangeState("Resting", {
				Duration = attackDuration + restDuration,
				NextState = "Waiting",
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

return Enemy