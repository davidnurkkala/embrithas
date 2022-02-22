local Super = require(script.Parent)
local EnemyTurretBasic = Super:Extend()

EnemyTurretBasic.DamageType = "Piercing"

function EnemyTurretBasic:OnCreated()
	self.Target = nil
	self:CreateStateMachine()
	
	Super.OnCreated(self)
end

function EnemyTurretBasic:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	if self:IsStunned() then return end
	
	self.StateMachine:Run(dt)
end

EnemyTurretBasic.DetectionRange = 128

EnemyTurretBasic.ProjectileSpeed = 20
EnemyTurretBasic.RestDuration = 2.5
EnemyTurretBasic.ProjectileModel = Super.Storage.Models.ShadowBolt
EnemyTurretBasic.AnimationName = "MagicCast"

function EnemyTurretBasic:IsTargetValid()
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

function EnemyTurretBasic:CreateStateMachine()
	self.StateMachine = self:CreateNew"StateMachine"()
	
	self.StateMachine:AddState{
		Name = "Waiting",
		Run = function(state, machine, dt)
			self.Target = self:GetNearestTarget(self.DetectionRange)
			if self:IsTargetValid() then
				machine:ChangeState("Attacking")
			end
			self:StuckCheck(dt)
		end,
		OnStateWillChange = function()
			self:StuckReset()
		end
	}
	
	self.StateMachine:AddState{
		Name = "Attacking",
		Run = function(state, machine)
			if not self:IsTargetValid() then
				self.Target = nil
				return machine:ChangeState("Waiting")
			end
			
			local targetPosition = self.Target:GetPosition()
			
			local function getTelegraphCFrame()
				local here = self:GetFootPosition()
				local there = targetPosition
				local delta = (there - here) * Vector3.new(1, 0, 1)
				return CFrame.new(here, here + delta) * CFrame.new(0, 0, -4)
			end
			
			self:FaceTowards(targetPosition)
			
			local duration = 0.5
			
			self:TelegraphDirectional{
				Duration = duration,
				
				Length = 4,
				Width = 2,
				CFrame = getTelegraphCFrame(),
				
				OnTicked = function(t)
					if not self.Target then return end
					
					targetPosition = self.Target:GetPosition()
					self:FaceTowards(targetPosition)
					
					t:UpdateCFrame(getTelegraphCFrame())
				end,
				
				Callback = function()
					self:AnimationPlay(self.AnimationName)
					
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

					self:SoundPlay("Shot")
				end,
			}
			
			local restDuration = self.RestDuration
			if typeof(restDuration) == "table" then
				local min, max = unpack(restDuration)
				restDuration = min + (max * min) * math.random()
			end
			
			machine:ChangeState("Resting", {
				NextState = "Attacking",
				Duration = restDuration,
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

return EnemyTurretBasic