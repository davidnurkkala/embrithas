local Super = require(script.Parent)
local EnemyGreatsword = Super:Extend()

EnemyGreatsword.DamageType = "Slashing"

function EnemyGreatsword:OnCreated()
	self.Target = nil
	self:CreateStateMachine()
	
	self.AttackPattern = self:CreateNew"AttackPattern"{Pattern = {
		"Jump",
		"Spin",
		"Slash", 3,	
	}}
	
	Super.OnCreated(self)
end

function EnemyGreatsword:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	if self:IsStunned() then return end
	
	self.StateMachine:Run(dt)
end

EnemyGreatsword.DetectionRange = 128
EnemyGreatsword.RetreatDuration = 1

EnemyGreatsword.JumpRadius = 10
EnemyGreatsword.JumpRange = 64
EnemyGreatsword.JumpDelay = 1
EnemyGreatsword.JumpFrustrationLimit = 2
EnemyGreatsword.JumpFrustration = 0

EnemyGreatsword.SpinRange = 8
EnemyGreatsword.SpinRadius = 12
EnemyGreatsword.SpinDelay = 1.25

EnemyGreatsword.SlashRange = 16
EnemyGreatsword.SlashLength = 24
EnemyGreatsword.SlashWidth = 5
EnemyGreatsword.SlashDelay = 0.75

function EnemyGreatsword:AttackJump()
	local targetPosition = self.Target:GetFootPosition()
	local position
	self:Attempt(8, function()
		local theta = math.pi * 2 * math.random()
		local dx = math.cos(theta) * self.JumpRadius / 2
		local dz = math.sin(theta) * self.JumpRadius / 2
		position = Vector3.new(
			targetPosition.X + dx,
			0,
			targetPosition.Z + dz
		)
		return self:DoesPointHaveFloor(position, 2)
	end)
	
	local here = self:GetFootPosition()
	local delta = (position - here) * Vector3.new(1, 0, 1)
	position = here + delta
	
	self:AttackCircle{
		Position = position,
		Radius = self.JumpRadius,
		Duration = self.JumpDelay,
		OnHit = function(legend)
			self:GetService"DamageService":Damage{
				Source = self,
				Target = legend,
				Amount = self.Damage,
				Type = self.DamageType,
			}
		end,
	}
	
	self:FaceTowards(position)
	
	delay(self.JumpDelay - 0.5, function()
		self:AnimationPlay("GreatswordAttack0")
		
		self:TweenNetwork{
			Object = self.Root,
			Goals = {CFrame = self.Root.CFrame + delta},
			Duration = 0.5,
			Direction = Enum.EasingDirection.In,
			Style = Enum.EasingStyle.Quint,
		}
	end)
	
	self.StateMachine:ChangeState("Resting", {
		Duration = self.JumpDelay + 0.5,
		NextState = "Waiting",
	})
end

function EnemyGreatsword:AttackSpin()
	self:AttackCircle{
		Position = self:GetFootPosition(),
		Radius = self.SpinRadius,
		Duration = self.SpinDelay,
		OnHit = function(legend)
			self:GetService"DamageService":Damage{
				Source = self,
				Target = legend,
				Amount = self.Damage,
				Type = self.DamageType,
			}
		end
	}
	
	local animLength = 0.4
	
	delay(self.SpinDelay - animLength, function()
		self:AnimationPlay("GreatswordSpin")
	end)
	
	self.StateMachine:ChangeState("Resting", {
		Duration = self.SpinDelay,
		NextState = "Retreating",
	})
end

function EnemyGreatsword:AttackSlash()
	local here = self:GetFootPosition()
	local there = self.Target:GetFootPosition() + (self.Target.Root.Velocity * self.SlashDelay)
	local delta = (there - here) * Vector3.new(1, 0, 1)
	local cframe = CFrame.new(here, here + delta) * CFrame.new(0, 0, -self.SlashLength / 2)
	
	self:FaceTowards(there)
	
	self:AttackSquare{
		CFrame = cframe,
		Width = self.SlashWidth,
		Length = self.SlashLength,
		Duration = self.SlashDelay,
		OnHit = function(legend)
			self:GetService"DamageService":Damage{
				Source = self,
				Target = legend,
				Amount = self.Damage,
				Type = self.DamageType,
			}
		end
	}
	
	delay(self.SlashDelay - 0.5, function()
		self:AnimationPlay("GreatswordAttack0")
	end)
	
	self.StateMachine:ChangeState("Resting", {
		Duration = self.SlashDelay,
		NextState = "Waiting",
	})
end

function EnemyGreatsword:IsTargetValid()
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

function EnemyGreatsword:CreateStateMachine()
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
			
			self.JumpFrustration = self.JumpFrustration + dt
			if self.JumpFrustration > self.JumpFrustrationLimit then
				self.AttackPattern:Reset()
				self.JumpFrustration = 0
			end
			
			local attack = self.AttackPattern:Get()
			local range
			if attack == "Jump" then
				range = self.JumpRange
			elseif attack == "Spin" then
				range = self.SpinRange
			elseif attack == "Slash" then
				range = self.SlashRange
			end
			
			if distance < range then
				self["Attack"..attack](self)
				self.AttackPattern:Next()
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
			state.DistanceFactor = self:RandomFloat(0.5, 1)
			
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
			
			local runPoint = cframe.Position + (cframe.LookVector * self.SlashRange * state.DistanceFactor) + (cframe.RightVector * state.StrafeFactor * self.SlashRange)
			
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

return EnemyGreatsword