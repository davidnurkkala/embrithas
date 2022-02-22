local Super = require(script.Parent)
local EnemyOrcJuggernaut = Super:Extend()

EnemyOrcJuggernaut.Resilient = true

function EnemyOrcJuggernaut:OnCreated()
	self.Traps = {}
	
	self.Target = nil
	self:CreateStateMachine()
	
	self.AttackPattern = self:CreateNew"AttackPattern"{Pattern = {
		"Basic", 3,
		"Shoot", 5,
		"Sweep",
		"Basic", 3,
		"ShootCeiling", 5,
		"Shoot", 5,
		"Sweep",
		"Basic", 3,
		"Shoot", 5,
		"Sweep",
		"Basic", 3,
		"ShootCeiling", 5,
	}}
	
	Super.OnCreated(self)
	
	self:AnimationPlay("OrcJuggernautIdle")
	self:GetService("MusicService"):PlayPlaylist{"When the Bad Guys have the Good Guys' Guns"}
	
	self.Speed.Base = 24
end

function EnemyOrcJuggernaut:OnDestroyed()
	for _, trap in pairs(self.Traps) do
		trap.Active = false
	end
	
	Super.OnDestroyed(self)
end

function EnemyOrcJuggernaut:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	self.StateMachine:Run(dt)
end

EnemyOrcJuggernaut.RangeByAttack = {
	Basic = 12,
	Shoot = 128,
	ShootCeiling = 128,
	Sweep = 28,
}

EnemyOrcJuggernaut.WalkAnimation = "OrcJuggernautWalk"

EnemyOrcJuggernaut.DetectionRange = 128

EnemyOrcJuggernaut.Frustration = 0
EnemyOrcJuggernaut.FrustrationLimit = 2

function EnemyOrcJuggernaut:CannonAnimation(callback)
	local animationTime = 10/30
	
	self:AnimationPlay("OrcJuggernautAttackCannon")
	
	self:Channel(animationTime, nil, function()
		local cannon = self.Model.Cannon
		local offset = -(cannon.Size.X / 2 + 2)
		local barrelPosition = cannon.CFrame:PointToWorldSpace(Vector3.new(offset, 0, 0))
		
		cannon.MuzzleFlashAttachment.Emitter:Emit(32)

		local light = cannon.MuzzleFlashAttachment.Light
		light.Enabled = true
		delay(0.1, function() light.Enabled = false end)

		self:SoundPlay("Shoot")

		callback(barrelPosition, animationTime)
	end)
end

function EnemyOrcJuggernaut:AttackSweep()
	local speed = 1
	
	local duration = 2 / speed
	local radius = 32
	
	self:Channel(duration - 1, nil, function()
		self:AnimationPlay("OrcJuggernautAttackSweep")
	end)
	
	self:AttackCircle{
		Position = self:GetFootPosition(),
		Radius = radius,
		Duration = duration,
		OnHit = self:DamageFunc(2, "Bludgeoning"),
	}
	
	self.StateMachine:ChangeState("Resting", {
		Duration = duration,
		NextState = "Waiting",
	})
end

function EnemyOrcJuggernaut:AttackShootCeiling()
	local targets = self:GetService("TargetingService"):GetMortals()
	local target = self:Choose(targets)
	local position = target:GetFootPosition()
	
	self:CannonAnimation(function(barrelPosition)
		local duration = 0.5
		
		local effectsService = self:GetService("EffectsService")
		local ceilingPosition = position + Vector3.new(0, 64, 0)
		effectsService:RequestEffectAll("LobProjectile", {
			Start = barrelPosition,
			Finish = ceilingPosition,
			Height = (barrelPosition.Y + ceilingPosition.Y) / 2,
			Duration = duration,
			Model = self.Storage.Models.Grenade,
		})
		
		delay(duration, function()
			effectsService:RequestEffectAll("Sound", {
				Position = ceilingPosition,
				Sound = self.EnemyData.Sounds.Explosion,
			})
			
			local trap = self:CreateNew"TrapFallingRocks"{
				StartCFrame = CFrame.new(position),
				StartParent = self:GetRun().Dungeon.Model,
			}
			table.insert(self.Traps, trap)
		end)
	end)
	
	self.StateMachine:ChangeState("Resting", {
		Duration = 0.5,
		NextState = "Waiting",
	})
end

function EnemyOrcJuggernaut:AttackShoot()
	local duration = 1
	local radius = 10
	
	local targets = self:GetService("TargetingService"):GetMortals()
	local target = self:Choose(targets)
	
	local position = target:GetFootPosition() + target:GetFlatVelocity() * duration
	self:FaceTowards(position)
	
	self:AttackCircle{
		Position = position,
		Radius = radius,
		Duration = duration,
		OnHit = self:DamageFunc(1, "Bludgeoning"),
		Sound = self.EnemyData.Sounds.Explosion,
	}
	
	self:CannonAnimation(function(barrelPosition, animationTime)
		self:GetService("EffectsService"):RequestEffectAll("LobProjectile", {
			Start = barrelPosition,
			Finish = position,
			Height = 6,
			Duration = duration - animationTime,
			Model = self.Storage.Models.Grenade,
		})
	end)
	
	self.StateMachine:ChangeState("Resting", {
		Duration = 0.5,
		NextState = "Waiting",
	})
end

function EnemyOrcJuggernaut:AttackBasic()
	local speed = 1
	
	local startRadius = 12
	local endRadius = 28
	local expandCount = 6
	local expandTime = 1.75
	
	local duration = 1 / speed
	
	local here = self:GetFootPosition()
	local there = self.Target:GetFootPosition()
	local delta = (there - here) * Vector3.new(1, 0, 1)
	local position = here + delta.Unit * startRadius
	
	self:AnimationPlay("OrcJuggernautAttackSwing", nil, nil, speed)
	
	self:AttackCircle{
		Position = position,
		Radius = startRadius,
		Duration = duration,
		OnHit = self:DamageFunc(1, "Bludgeoning"),
	}
	
	local tStep = expandTime / expandCount
	for step = 1, expandCount do
		local radius = self:Lerp(startRadius, endRadius, step / expandCount)
		local t = tStep * step
		self:Channel(duration + t - tStep, nil, function()
			self:AttackCircle{
				Position = position,
				Radius = radius,
				Duration = tStep,
				OnHit = self:DamageFunc(1 / expandCount, "Bludgeoning"),
				Sound = (step ~= expandCount) and self.Storage.Sounds.Silence,
			}
		end)
	end
	
	self.StateMachine:ChangeState("Resting", {
		Duration = 1,
		NextState = "Waiting",
	})
end

function EnemyOrcJuggernaut:Flinch()
	-- don't
end

function EnemyOrcJuggernaut:IsTargetValid()
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

function EnemyOrcJuggernaut:CreateStateMachine()
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
			self:AnimationPlay(self.WalkAnimation)
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

return EnemyOrcJuggernaut