local Super = require(script.Parent)
local EnemyBlasterConstruct = Super:Extend()

function EnemyBlasterConstruct:OnCreated()
	self.Target = nil
	self:CreateStateMachine()
	
	Super.OnCreated(self)
	
	self.AttackPattern = self:CreateNew"AttackPattern"{Pattern = {
		"Blast",
		"Teleport",
	}}
	self.AttackPattern:Randomize()
	
	self:AnimationPlay(self.IdleAnimation)
end

function EnemyBlasterConstruct:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	if self:IsStunned() then return end
	
	self.StateMachine:Run(dt)
end

EnemyBlasterConstruct.RangeByAttack = {
	Blast = 64,
	Teleport = 128,
}

EnemyBlasterConstruct.DetectionRange = 128
EnemyBlasterConstruct.AttackLength = 64
EnemyBlasterConstruct.AttackWidth = 8
EnemyBlasterConstruct.AttackDelay = 1

EnemyBlasterConstruct.IdleAnimation = "AssassinIdle"
EnemyBlasterConstruct.RunAnimation = "RunNoWeapons"

function EnemyBlasterConstruct:AttackTeleport()
	local position = self:GetAmbushPosition(self, 0, 32)
	
	local function effect()
		self:GetService("EffectsService"):RequestEffectAll("AirBlast", {
			Position = self:GetPosition(),
			Radius = 8,
			Color = Color3.fromRGB(0, 170, 255),
			Duration = 0.25,
			PartArgs = {
				Material = Enum.Material.Neon,
			}
		})
	end

	effect()
	self.Root.CFrame = CFrame.new(position)
	effect()
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Chasing",
		Duration = 1,
	})
end

function EnemyBlasterConstruct:AttackBlast()
	local duration = self.AttackDelay
	local length = self.AttackLength
	local width = self.AttackWidth
	
	local targetPosition = self.Target:GetFootPosition() + self.Target:GetFlatVelocity() * duration
	self:FaceTowards(targetPosition)
	
	local here = self:GetFootPosition()
	local there = targetPosition
	local delta = (there - here) * Vector3.new(1, 0, 1)
	local cframe = CFrame.new(here, here + delta) * CFrame.new(0, 0, -length / 2)
	
	self:AttackSquare{
		CFrame = cframe,
		Length = length,
		Width = width,
		Duration = duration,
		Sound = self.Storage.Sounds.MagicEerie2,
		OnHit = self:DamageFunc(1, "Disintegration", {"Magical"}),
		OnEnded = function()
			self:GetService("EffectsService"):RequestEffectAll("LinearBlast", {
				CFrame = cframe + Vector3.new(0, 2.5, 0),
				Length = length,
				Width = width,
				Duration = 0.25,
				PartArgs = {
					Material = Enum.Material.Neon,
					Transparency = 0.5,
					Color = Color3.fromRGB(0, 170, 255),
				}
			})
		end,
	}
	
	self:SoundPlayByObject(self.Storage.Sounds.MagicCharge)
	self:AnimationPlay("TwoHandBlast", nil, nil, 0.5 / duration)
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Chasing",
		Duration = duration + 0.5,
	})
end

function EnemyBlasterConstruct:IsTargetValid()
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

function EnemyBlasterConstruct:CreateStateMachine()
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
				state.Frustration = 0
				return self:AttackTeleport()
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

return EnemyBlasterConstruct