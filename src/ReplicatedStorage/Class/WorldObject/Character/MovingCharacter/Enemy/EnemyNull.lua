local Super = require(script.Parent)
local EnemyNull = Super:Extend()

EnemyNull.DamageType = "Piercing"

function EnemyNull:OnCreated()
	self.Target = nil
	self:CreateStateMachine()
	
	self.FieldCooldown = self:CreateNew"Cooldown"{Time = 10}
	
	Super.OnCreated(self)
end

function EnemyNull:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	if self:IsStunned() then return end
	
	if self.FieldCooldown:IsReady() then
		self.FieldCooldown:Use()
		
		self:AttackActiveCircle{
			Position = self:GetFootPosition(),
			Radius = self.FieldRadius,
			Duration = self.FieldCooldown.Time,
			Interval = 0.2,

			OnHit = function(legend, dt)
				self:GetService"DamageService":Damage{
					Source = self,
					Target = legend,
					Amount = self.Damage * dt,
					Type = "Bludgeoning",
				}
			end,
		}
	end
	
	self.StateMachine:Run(dt)
end

EnemyNull.DetectionRange = 256

EnemyNull.RestDuration = 2.5
EnemyNull.ProjectileModel = Super.Storage.Models.ShadowBolt

EnemyNull.FieldRadius = 20

function EnemyNull:IsTargetValid()
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

function EnemyNull:CreateStateMachine()
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
					local radius = 6
					local speed = 32
					local duration = 0.5
					
					local blastCooldown = self:CreateNew"Cooldown"{Time = radius * 1.5 / speed}
					
					self:GetClass("Projectile").CreateHostileProjectile{
						CFrame = CFrame.new(self:GetPosition(), targetPosition),
						Speed = speed,
						Model = self.Storage.Models.ShadowBolt,
						DeactivationType = "Wall",
						Width = 4,
						Range = 256,
						
						OnTicked = function(projectile)
							if not self.Active then
								projectile:Deactivate()
								return
							end
							
							if not blastCooldown:IsReady() then return end
							blastCooldown:Use()
							
							self:AttackCircle{
								Position = self:GetFootPosition(projectile.CFrame.Position),
								Duration = duration,
								Radius = radius,
								OnHit = self:DamageFunc(1, "Disintegration", {"Magical"}),
								Effect = {
									Type = "AirBlast",
									Args = {
										Position = projectile.CFrame.Position,
										Radius = radius,
										Duration = 0.25,
										PartArgs = {
											Material = Enum.Material.Neon,
											Color = Color3.new(0, 0, 0),
										}
									}
								}
							}
						end,
					}
				end,
			}
			
			machine:ChangeState("Resting", {
				NextState = "Attacking",
				Duration = 3,
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

return EnemyNull