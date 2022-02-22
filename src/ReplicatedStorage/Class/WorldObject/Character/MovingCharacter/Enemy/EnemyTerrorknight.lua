local Super = require(script.Parent)
local EnemyTerrorknight = Super:Extend()

function EnemyTerrorknight:OnCreated()
	self.Target = nil
	self:CreateStateMachine()
	
	Super.OnCreated(self)
	
	self.AttackPattern = self:CreateNew"AttackPattern"{Pattern = {
		"Basic", 4,
		"Spin",
	}}
	self.AttackPattern:Randomize()
	
	self:AnimationPlay(self.IdleAnimation)
end

function EnemyTerrorknight:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	if self:IsStunned() then return end
	
	self.StateMachine:Run(dt)
end

EnemyTerrorknight.RangeByAttack = {
	Basic = 10,
	Spin = 128,
}

EnemyTerrorknight.DetectionRange = 128
EnemyTerrorknight.AttackRange = 6
EnemyTerrorknight.AttackDelay = 1
EnemyTerrorknight.RetreatDuration = 0.6
EnemyTerrorknight.RetreatSpeed = 40

EnemyTerrorknight.IdleAnimation = "TK_Idle"
EnemyTerrorknight.RunAnimation = "TK_Run"

function EnemyTerrorknight:AttackSpin()
	local duration = 1
	local radius = 10
	
	local position, targetPosition = self:GetAmbushPosition(self.Target, duration, radius / 2)
	
	local function effect()
		self:GetService("EffectsService"):RequestEffectAll("AirBlast", {
			Position = self:GetPosition(),
			Radius = 8,
			Color = Color3.new(0.333333, 0, 0.498039),
			Duration = 0.25,
		})
	end
	
	effect()
	self.Root.CFrame = CFrame.new(position)
	self:FaceTowards(targetPosition)
	effect()
	
	self:SoundPlayByObject(self.Storage.Sounds.DarkTeleport)
	
	self:AttackCircle{
		Position = self:GetFootPosition(),
		Radius = radius,
		Duration = duration,
		OnHit = self:DamageFunc(1, "Slashing"),
	}
	
	local animLength = 0.4
	delay(duration - animLength, function()
		self:AnimationPlay("GreatswordSpin")
	end)
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Waiting",
		Duration = duration
	})
end

function EnemyTerrorknight:AttackBasic()
	local targetPosition = self.Target:GetFootPosition() + self.Target:GetFlatVelocity()
	self:FaceTowards(targetPosition)
	
	local duration = self.AttackDelay
	local length = 16
	local width = 4
	local radius = 6
	
	local here = self:GetFootPosition()
	local there = targetPosition
	local delta = (there - here) * Vector3.new(1, 0, 1)
	local cframe = CFrame.new(here, here + delta)
	
	for _, angle in pairs{-45, 0, 45} do
		local theta = math.rad(angle)
		local c = cframe * CFrame.Angles(0, theta, 0) * CFrame.new(0, 0, -length / 2 - (radius - 1))
		self:AttackSquare{
			CFrame = c,
			Length = length,
			Width = width,
			Duration = duration,
			OnHit = self:DamageFunc(1, "Slashing"),
			Sound = self.Storage.Sounds.Silence,
		}
	end
	
	self:AttackCircle{
		Position = here,
		Radius = radius,
		Duration = duration,
		OnHit = self:DamageFunc(1, "Slashing"),
	}
	
	self:AnimationPlay("GreatswordAttack0", nil, nil, 0.5 / duration)
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Retreating",
		Duration = duration
	})
end

function EnemyTerrorknight:Flinch()
	-- don't
end

function EnemyTerrorknight:IsTargetValid()
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

function EnemyTerrorknight:CreateStateMachine()
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
		OnStateChanged = function(state)
			self:AnimationPlay(self.RunAnimation, nil, nil, 2)
			
			state.Frustration = 0
			state.FrustrationLimit = 2
		end,
		
		Run = function(state, machine, dt)
			if not self:IsTargetValid() then
				self.Target = nil
				return machine:ChangeState("Waiting")
			end
			
			state.Frustration += dt
			if state.Frustration >= state.FrustrationLimit then
				return self:AttackSpin()
			end
			
			local targetPosition = self.Target:GetPosition()
			local distance = self:DistanceTo(targetPosition)
			
			self:MoveTo(targetPosition)
			
			local attack = self.AttackPattern:Get()
			local range = self.RangeByAttack[attack]
			
			if distance < range then
				self["Attack"..attack](self)
				self.AttackPattern:Next()
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
			state.DistanceFactor = 0.75
			
			self:AnimationPlay(self.RunAnimation, nil, nil, 2)
			
			state.MaxDuration = state.Duration
			state.SpeedBonus = 0
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
			
			local progress = state.Duration / state.MaxDuration
			self.Speed.Flat -= state.SpeedBonus
			state.SpeedBonus = self.RetreatSpeed * progress
			self.Speed.Flat += state.SpeedBonus
			
			state.Duration = state.Duration - dt
			if state.Duration <= 0 then
				machine:ChangeState("Waiting")
			end
		end,
		
		OnStateWillChange = function(state)
			self:MoveStop()
			self:AnimationStop(self.RunAnimation)
			
			self.Speed.Flat -= state.SpeedBonus
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

return EnemyTerrorknight