local Super = require(script.Parent)
local EnemyRangerBasic = Super:Extend()

EnemyRangerBasic.DamageType = "Piercing"

function EnemyRangerBasic:OnCreated()
	self.Target = nil
	self:CreateStateMachine()
	
	Super.OnCreated(self)
end

function EnemyRangerBasic:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	if self:IsStunned() then return end
	
	self.StateMachine:Run(dt)
end

EnemyRangerBasic.DetectionRange = 128
EnemyRangerBasic.AttackRange = 32
EnemyRangerBasic.FleeRange = 12

EnemyRangerBasic.ProjectileSpeed = 20
EnemyRangerBasic.ProjectileModel = Super.Storage.Models.Arrow

EnemyRangerBasic.Tracking = false

function EnemyRangerBasic:IsTargetValid()
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

function EnemyRangerBasic:CreateStateMachine()
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
			self:AnimationPlay("GenericRun", nil, nil, 2)
		end,
		
		Run = function(state, machine)
			if not self:IsTargetValid() then
				self.Target = nil
				return machine:ChangeState("Waiting")
			end
			
			local targetPosition = self.Target:GetPosition()
			local distance = self:DistanceTo(targetPosition)
			
			self:MoveTo(targetPosition)
			
			if distance < self.FleeRange then
				machine:ChangeState("Retreating")
				
			elseif distance < self.AttackRange then
				machine:ChangeState("Attacking")
			
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
		Name = "Retreating",
		
		OnStateChanged = function(state, machine)
			state.Duration = 1
			state.StrafeFactor = self:RandomSign()
			state.DistanceFactor = self:RandomFloat(0.75, 1.25)
			
			self:AnimationPlay("GenericRun", nil, nil, 2)
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
			
			state.Duration = state.Duration - dt
			if state.Duration <= 0 then
				machine:ChangeState("Waiting")
			end
		end,
		
		OnStateWillChange = function()
			self:MoveStop()
			self:AnimationStop("GenericRun")
		end,
	}
	
	self.StateMachine:AddState{
		Name = "Attacking",
		Run = function(state, machine)
			if not self:IsTargetValid() then
				self.Target = nil
				return machine:ChangeState("Waiting")
			end
			
			local targetPosition = self.Target:GetPosition()
			
			self:FaceTowards(targetPosition)
			
			local duration = 1
			self:AnimationPlay("BowShoot", nil, nil, 0.5 / duration)
			
			local function getTelegraphCFrame()
				local here = self:GetFootPosition()
				local there = targetPosition
				local delta = (there - here) * Vector3.new(1, 0, 1)
				return CFrame.new(here, here + delta) * CFrame.new(0, 0, -4)
			end
			
			self:TelegraphDirectional{
				Duration = duration,
				
				Length = 4,
				Width = 2,
				CFrame = getTelegraphCFrame(),
				
				OnTicked = function(t)
					if not self.Tracking then return end
					if not self.Target then return end

					targetPosition = self.Target:GetPosition()
					self:FaceTowards(targetPosition)
					
					t:UpdateCFrame(getTelegraphCFrame())
				end,
				
				Callback = function()
					local delta = (targetPosition - self:GetPosition()) * Vector3.new(1, 0, 1)

					local projectile = self:CreateNew"Projectile"{
						Model = self.ProjectileModel:Clone(),
						CFrame = CFrame.new(self:GetPosition()),
						Velocity = delta.Unit * self.ProjectileSpeed,
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
										Type = self.DamageType,
									}
								else
									return
								end
							end

							projectile:Deactivate()
						end
					}
					self:GetWorld():AddObject(projectile)
					self:GetService("EffectsService"):RequestEffectAll("ShowProjectile", {Projectile = projectile.Model, Width = 2})
				end,
			}
			
			machine:ChangeState("Resting", {
				NextState = "Retreating",
				Duration = 1
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

return EnemyRangerBasic