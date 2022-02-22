local Super = require(script.Parent)
local EnemyGhost = Super:Extend()

function EnemyGhost:OnCreated()
	self.Target = nil
	self:CreateStateMachine()
	
	Super.OnCreated(self)
end

function EnemyGhost:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	if self:IsStunned() then return end
	
	self.StateMachine:Run(dt)
end

EnemyGhost.DetectionRange = 128
EnemyGhost.RetreatDuration = 1

EnemyGhost.AttackRange = 32
EnemyGhost.DrainRate = 20

EnemyGhost.AttackAnimation = "GhostAttack"
EnemyGhost.AttackDelay = 0.7
EnemyGhost.AttackRest = 0.5
EnemyGhost.AttackRadius = 5
EnemyGhost.Predictive = true

function EnemyGhost:IsTargetValid()
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

function EnemyGhost:OnDestroyed()
	if self.ManaBeam then
		self.ManaBeam:Destroy()
		self.ManaBeam = nil
	end
	
	Super.OnDestroyed(self)
end

function EnemyGhost:CreateStateMachine()
	self.StateMachine = self:CreateNew"StateMachine"()
	
	self.StateMachine:AddState{
		Name = "Waiting",
		Run = function(state, machine, dt)
			self.Target = self:GetNearestTarget(self.DetectionRange, function(target)
				return (target.Mana ~= nil) and (target.Mana > 0)
			end)
			if not self.Target then
				self.Target = self:GetNearestTarget(self.DetectionRange)
			end
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
			self:AnimationPlay("FieryCorruptionRun")
		end,
		
		Run = function(state, machine, dt)
			if not self:IsTargetValid() then
				self.Target = nil
				return machine:ChangeState("Waiting")
			end
			
			local targetPosition = self.Target:GetPosition()
			local distance = self:DistanceTo(targetPosition)
			
			self:MoveTo(targetPosition)
			
			if distance < self.AttackRange then
				if (self.Target.Mana ~= nil) and (self.Target.Mana > 0) and (not self.Target:HasStatusType("ManaBurning")) then
					machine:ChangeState("Draining")
				else
					machine:ChangeState("Attacking")
				end
			end
		end,
		
		OnStateWillChange = function()
			self:MoveStop()
			self:AnimationStop("FieryCorruptionRun")
		end,
	}
	
	self.StateMachine:AddState{
		Name = "Attacking",
		
		Run = function(state, machine, dt)
			if not self:IsTargetValid() then
				self.Target = nil
				return machine:ChangeState("Waiting")
			end
			
			local targetPosition = self.Target:GetFootPosition()
			
			local duration = self.AttackDelay
			if self.Predictive then
				targetPosition = targetPosition + self.Target:GetFlatVelocity() * duration
				
				local here = self:GetFootPosition()
				local delta = (targetPosition - here) * Vector3.new(1, 0, 1)
				local distance = delta.Magnitude
				if distance > self.AttackRange then
					targetPosition = here + (delta / distance) * self.AttackRange
				end
			end
			
			self:FaceTowards(targetPosition)
			
			self:AnimationPlay(self.AttackAnimation, nil, nil, 1 / duration)
			
			self:AttackCircle{
				Position = targetPosition,
				Radius = self.AttackRadius,
				Duration = duration,
				OnHit = function(legend)
					self:GetService"DamageService":Damage{
						Source = self,
						Target = legend,
						Amount = self.Damage,
						Type = "Disintegration",
						Tags = {"Magical"},
					}
				end
			}
			
			machine:ChangeState("Resting", {
				NextState = "Waiting",
				Duration = duration + self.AttackRest,
			})
		end
	}
	
	self.StateMachine:AddState{
		Name = "Draining",
		
		OnStateChanged = function(state)
			self.Target:AddStatus("StatusManaBurning", {
				Time = 5,
				Drain = self.Target.MaxMana:Get() * 0.25,
			})
			
			self:GetService("EffectsService"):RequestEffectAll("AirBlast", {
				Position = self.Target:GetPosition(),
				Color = Color3.new(0, 0, 1),
				Radius = 8,
				Duration = 0.25,
			})
			
			self.Target:SoundPlayByObject(self.Storage.Sounds.Curse)
			
			state.Duration = 1.5
			
			local beam = self.Storage.Models.GhostBeam:Clone()
			beam.Attachment1 = self.Model.Head.SuckAttachment
			beam.Attachment0 = self.Target.Model.UpperTorso.ChestAttachment
			beam.Parent = self.Model
			self.ManaBeam = beam
			
			self:AnimationPlay("GhostSuck")
		end,
		
		Run = function(state, machine, dt)
			if not self:IsTargetValid() then
				self.Target = nil
				return machine:ChangeState("Waiting")
			end
			
			local targetPosition = self.Target:GetPosition()
			local distance = self:DistanceTo(targetPosition)
			
			if distance > self.AttackRange then
				return machine:ChangeState("Chasing")
			end
			
			self:FaceTowards(targetPosition)
			
			state.Duration -= dt
			if state.Duration <= 0 then
				machine:ChangeState("Waiting")
			end
		end,
		
		OnStateWillChange = function(state)
			self.ManaBeam:Destroy()
			self.ManaBeam = nil
			
			self:AnimationStop("GhostSuck")
		end
	}
	
	self.StateMachine:AddState{
		Name = "Retreating",
		
		OnStateChanged = function(state, machine)
			state.Duration = self.RetreatDuration
			state.StrafeFactor = self:RandomSign()
			state.DistanceFactor = self:RandomFloat(0.25, 0.5)
			
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
			
			local range = self:GetShockwaveRange()
			local runPoint = cframe.Position + (cframe.LookVector * range * state.DistanceFactor) + (cframe.RightVector * state.StrafeFactor * range)
			
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

return EnemyGhost