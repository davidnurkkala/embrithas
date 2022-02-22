local Super = require(script.Parent)
local EnemyBaseBoss = Super:Extend()

EnemyBaseBoss.Resilient = true

function EnemyBaseBoss:OnCreated()
	self.Target = nil
	self:CreateStateMachine()
	
	self.AttackPattern = self:CreateNew"AttackPattern"{Pattern = {
		"Basic",
	}}
	
	Super.OnCreated(self)
	
	self:AnimationPlay("IDLE_ANIMATION_HERE")
	self:GetService("MusicService"):PlayPlaylist{"SOUNDTRACK_HERE"}
	
	self.Speed.Base = 24
end

function EnemyBaseBoss:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	self.StateMachine:Run(dt)
end

EnemyBaseBoss.RangeByAttack = {
	Basic = 12,
}

EnemyBaseBoss.WalkAnimation = "WALK_ANIMATION_HERE"

EnemyBaseBoss.DetectionRange = 128

EnemyBaseBoss.Frustration = 0
EnemyBaseBoss.FrustrationLimit = 2

function EnemyBaseBoss:AttackBasic()
	
end

function EnemyBaseBoss:Flinch()
	-- don't
end

function EnemyBaseBoss:IsTargetValid()
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

function EnemyBaseBoss:CreateStateMachine()
	self.StateMachine = self:CreateNew"StateMachine"()
	
	self.StateMachine:AddState{
		Name = "Waiting",
		Run = function(state, machine, dt)
			self.Target = self:GetNearestTarget(self.DetectionRange)
			if self:IsTargetValid() then
				self:FaceTowards(self.Target:GetPosition())
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
			self:AnimationPlay(self.WalkAnimation, nil, nil, 2)
		end,
		
		Run = function(state, machine, dt)
			self.Frustration = self.Frustration + dt
			if self.Frustration > self.FrustrationLimit then
				self.Frustration = 0
				self.Target = self:GetNearestTarget(self.DetectionRange)
			end
			
			if not self:IsTargetValid() then
				self.Target = nil
				return machine:ChangeState("Waiting")
			end
			
			local targetPosition = self.Target:GetPosition()
			local distance = self:DistanceTo(targetPosition)
			
			self:MoveTo(targetPosition)
			
			local attack = self.AttackPattern:Get()
			local range = self.RangeByAttack[attack]
			
			if distance < range then
				self["Attack"..attack](self)
				self.AttackPattern:Next()
			
			elseif distance > self.DetectionRange then
				self.Target = nil
				machine:ChangeState("Waiting")
			end
		end,
		
		OnStateWillChange = function()
			self.Frustration = 0
			self:MoveStop()
			self:AnimationStop(self.WalkAnimation)
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

return EnemyBaseBoss