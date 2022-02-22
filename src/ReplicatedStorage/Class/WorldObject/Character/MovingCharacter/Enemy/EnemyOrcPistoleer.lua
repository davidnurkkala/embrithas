local Super = require(script.Parent)
local EnemyOrcPistoleer = Super:Extend()

function EnemyOrcPistoleer:OnCreated()
	self.Target = nil
	self:CreateStateMachine()
	
	self.AttackPattern = self:CreateNew"AttackPattern"{Pattern = {
		"Shoot", 2,
		"Dodge",
	}}
	
	Super.OnCreated(self)
	
	self.Speed.Base = 18
end

function EnemyOrcPistoleer:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	if self:IsStunned() then return end
	
	self.StateMachine:Run(dt)
end

EnemyOrcPistoleer.DetectionRange = 128

EnemyOrcPistoleer.DodgeSpeed = 32
EnemyOrcPistoleer.DodgeDuration = 1

EnemyOrcPistoleer.ShootRange = 48
EnemyOrcPistoleer.ShootLength = 64
EnemyOrcPistoleer.ShootWidth = 6
EnemyOrcPistoleer.ShootDelay = 1

function EnemyOrcPistoleer:AttackDodge()
	local direction = CFrame.Angles(0, math.pi * 2 * math.random(), 0).LookVector
	local velocity = direction * self.DodgeSpeed
	local duration = self.DodgeDuration
	self:FaceTowards(self:GetPosition() + velocity)
	self:Dash(velocity, duration)
	self:AnimationPlay("CombatRoll", nil, nil, 1 / duration)

	self.StateMachine:ChangeState("Resting", {
		Duration = duration,
		NextState = "Waiting",
	})
end

function EnemyOrcPistoleer:AttackShoot()
	local here = self:GetFootPosition()
	local there = self.Target:GetFootPosition() + self.Target:GetFlatVelocity() * self.ShootDelay
	local delta = (there - here) * Vector3.new(1, 0, 1)
	local cframe = CFrame.new(here, here + delta)
	
	self:FaceTowards(there)
	
	local shotRightWindup = 6/30
	local shotLeftWindup = 14/30
	
	delay(self.ShootDelay - shotRightWindup, function()
		self:AnimationPlay("OrcPistoleerShoot")
	end)
	
	local function effect(pistol)
		local a = pistol.MuzzleFlashAttachment
		a.Emitter:Emit(32)
		a.Light.Enabled = true
		delay(0.1, function() a.Light.Enabled = false end)
	end
	
	self:AttackSquare{
		CFrame = cframe * CFrame.new(self.ShootWidth * 0.3, 0, -self.ShootLength/2),
		Length = self.ShootLength,
		Width = self.ShootWidth,
		Duration = self.ShootDelay,
		OnHit = self:DamageFunc(1, "Piercing"),
		Sound = self:Choose(self.EnemyData.Sounds.Shot:GetChildren()),
	}
	delay(self.ShootDelay, function()
		effect(self.Model.Pistol1)
	end)
	
	delay(shotRightWindup, function()
		self:AttackSquare{
			CFrame = cframe * CFrame.new(-self.ShootWidth * 0.3, 0, -self.ShootLength/2),
			Length = self.ShootLength,
			Width = self.ShootWidth,
			Duration = self.ShootDelay,
			OnHit = self:DamageFunc(1, "Piercing"),
			Sound = self:Choose(self.EnemyData.Sounds.Shot:GetChildren()),
		}
		delay(self.ShootDelay, function()
			effect(self.Model.Pistol2)
		end)
	end)
	
	self.StateMachine:ChangeState("Resting", {
		Duration = self.ShootDelay + 0.2,
		NextState = "Waiting",
	})
end

function EnemyOrcPistoleer:Flinch()
	-- don't
end

function EnemyOrcPistoleer:IsTargetValid()
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

function EnemyOrcPistoleer:CreateStateMachine()
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
			self:AnimationPlay("RunDualWield")
		end,
		
		Run = function(state, machine, dt)
			if not self:IsTargetValid() then
				self.Target = nil
				return machine:ChangeState("Waiting")
			end
			
			local targetPosition = self.Target:GetPosition()
			local distance = self:DistanceTo(targetPosition)
			
			self:MoveTo(targetPosition)
			
			local attack = self.AttackPattern:Get()
			local range
			if attack == "Shoot" then
				range = self.ShootRange
			elseif attack == "Dodge" then
				range = self.DetectionRange
			end
			
			if distance < range then
				self["Attack"..attack](self)
				self.AttackPattern:Next()
			end
		end,
		
		OnStateWillChange = function()
			self:MoveStop()
			self:AnimationStop("RunDualWield")
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

return EnemyOrcPistoleer