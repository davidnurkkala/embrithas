local Super = require(script.Parent)
local EnemyElementalCorruption = Super:Extend()

EnemyElementalCorruption.DamageType = "Bludgeoning"
EnemyElementalCorruption.ProjectileDamageType = "Heat"

function EnemyElementalCorruption:OnCreated()
	self.Target = nil
	self:CreateStateMachine()
	
	self.ProjectileCooldown = self:CreateNew"Cooldown"{
		Time = self.ProjectileCooldownTime,
	}
	
	Super.OnCreated(self)
end

function EnemyElementalCorruption:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	if self:IsStunned() then return end
	
	self.StateMachine:Run(dt)
end

EnemyElementalCorruption.DetectionRange = 128
EnemyElementalCorruption.RetreatDuration = 1

EnemyElementalCorruption.MeleeAttackDelay = 0.8
EnemyElementalCorruption.MeleeAttackRadius = 8
EnemyElementalCorruption.MeleeRange = 10

EnemyElementalCorruption.ProjectileRange = 30
EnemyElementalCorruption.ProjectileAttackDelay = 1
EnemyElementalCorruption.ProjectileSpeed = 40
EnemyElementalCorruption.ProjectileCooldownTime = 8
EnemyElementalCorruption.ProjectileModel = Super.Storage.Models.FireBolt
EnemyElementalCorruption.ProjectileSound = "FireCast"
EnemyElementalCorruption.ProjectileHitSound = "FireHit"

function EnemyElementalCorruption:IsTargetValid()
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

function EnemyElementalCorruption:FireProjectile(direction, position)
	local projectile = self:CreateNew"Projectile"{
		Model = self.ProjectileModel:Clone(),
		CFrame = CFrame.new(position or self:GetPosition()),
		Velocity = direction * self.ProjectileSpeed,
		FaceTowardsVelocity = true,
		ShouldIgnoreFunc = function(part)
			if part:IsDescendantOf(self.Model) then return true end
			if part:IsDescendantOf(workspace.Enemies) then return true end
		end,
		OnHitPart = function(projectile, part)
			if part:IsDescendantOf(self.Model) then return end
			
			local character = self:GetService("TargetingService"):GetMortalFromPart(part)
			if character then
				if projectile:IsHittingCharacter(character) then
					self:GetService"DamageService":Damage{
						Source = self,
						Target = character,
						Amount = self.Damage,
						Type = self.ProjectileDamageType,
						Tags = {"Magical"},
					}
					character:SoundPlay(self.ProjectileHitSound)
					
					if self.OnProjectileHit then
						self:OnProjectileHit(projectile, character)
					end
				else
					return
				end
			end
			
			projectile:Deactivate()
		end
	}
	self:GetWorld():AddObject(projectile)
	self:GetService("EffectsService"):RequestEffectAll("ShowProjectile", {Projectile = projectile.Model, Width = 2})
end

function EnemyElementalCorruption:CreateStateMachine()
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
			
			if distance < self.ProjectileRange and self.ProjectileCooldown:IsReady() then
				machine:ChangeState("ProjectileAttacking")
				
			elseif distance < self.MeleeRange then
				machine:ChangeState("Attacking")
			end
		end,
		
		OnStateWillChange = function()
			self:MoveStop()
			self:AnimationStop("FieryCorruptionRun")
		end,
	}
	
	self.StateMachine:AddState{
		Name = "Retreating",
		
		OnStateChanged = function(state, machine)
			state.Duration = self.RetreatDuration
			state.StrafeFactor = self:RandomSign()
			state.DistanceFactor = self:RandomFloat(0.8, 1.2)
			
			self:AnimationPlay("FieryCorruptionRun")
		end,
		
		Run = function(state, machine, dt)
			if not self:IsTargetValid() then
				self.Target = nil
				return machine:ChangeState("Waiting")
			end
			
			local targetPosition = self.Target:GetPosition()
			local myPosition = self:GetPosition()
			local cframe = CFrame.new(targetPosition, myPosition)
			
			local range = self.MeleeRange
			local runPoint = cframe.Position + (cframe.LookVector * range * state.DistanceFactor) + (cframe.RightVector * state.StrafeFactor * range)
			
			self:MoveTo(runPoint)
			
			state.Duration = state.Duration - dt
			if state.Duration <= 0 then
				machine:ChangeState("Waiting")
			end
		end,
		
		OnStateWillChange = function()
			self:MoveStop()
			self:AnimationStop("FieryCorruptionRun")
		end,
	}
	
	self.StateMachine:AddState{
		Name = "ProjectileAttacking",
		Run = function(state, machine)
			if not self:IsTargetValid() then
				self.Target = nil
				return machine:ChangeState("Waiting")
			end
			
			self.ProjectileCooldown:Use()
			
			local targetPosition = self.Target:GetPosition()
			
			self:FaceTowards(targetPosition)
			
			local duration = self.ProjectileAttackDelay
			self:AnimationPlay("FieryCorruptionRange", nil, nil, 1 / duration)
			
			local function getCFrame()
				local here = self:GetFootPosition()
				local there = targetPosition
				local delta = (there - here) * Vector3.new(1, 0, 1)
				return CFrame.new(here, here + delta) * CFrame.new(0, 0, -4)
			end
			
			self:TelegraphDirectional{
				Duration = duration,
				
				Length = 4,
				Width = 2,
				CFrame = getCFrame(),
				
				OnTicked = function(t)
					if not self.Target then return end
					
					targetPosition = self.Target:GetPosition()
					local delta = (targetPosition - self:GetPosition()) * Vector3.new(1, 0, 1)
					local distance = delta.Magnitude
					local travelTime = distance / self.ProjectileSpeed
					targetPosition = targetPosition + self.Target:GetFlatVelocity() * travelTime

					self:FaceTowards(targetPosition)
					
					t:UpdateCFrame(getCFrame())
				end,
				
				Callback = function()
					self:SoundPlay(self.ProjectileSound)

					local delta = (targetPosition - self:GetPosition()) * Vector3.new(1, 0, 1)
					self:FireProjectile(delta.Unit)
				end,
			}
			
			machine:ChangeState("Resting", {
				NextState = "Waiting",
				Duration = duration,
			})
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
			
			self:FaceTowards(targetPosition)
			
			local duration = self.MeleeAttackDelay
			self:AnimationPlay("FieryCorruptionMelee", nil, nil, 1 / duration)
			
			self:AttackCircle{
				Position = targetPosition,
				Radius = self.MeleeAttackRadius,
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
			
			machine:ChangeState("Resting", {
				NextState = "Retreating",
				Duration = duration
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

return EnemyElementalCorruption