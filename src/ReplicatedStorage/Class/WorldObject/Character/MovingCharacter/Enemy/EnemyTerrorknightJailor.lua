local Super = require(script.Parent)
local EnemyTerrorknightJailor = Super:Extend()

function EnemyTerrorknightJailor:OnCreated()
	self.Target = nil
	self:CreateStateMachine()
	
	Super.OnCreated(self)
	
	self:AnimationPlay(self.IdleAnimation)
	
	self.Speed.Base = 10
	
	self.BasicCooldown = self:CreateNew"Cooldown"{Time = 1.5}
	self.CageCooldown = self:CreateNew"Cooldown"{Time = 20}
end

function EnemyTerrorknightJailor:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	if self:IsStunned() then return end
	
	self.StateMachine:Run(dt)
end

EnemyTerrorknightJailor.DetectionRange = 128
EnemyTerrorknightJailor.HoverRange = 32
EnemyTerrorknightJailor.ProjectileSpeed = 16

EnemyTerrorknightJailor.IdleAnimation = "TK_Idle"
EnemyTerrorknightJailor.RunAnimation = "TK_Run"

EnemyTerrorknightJailor.CageDuration = 15

function EnemyTerrorknightJailor:AttackCage()
	if not self.BasicCooldown:IsReady() then return end
	if not self.CageCooldown:IsReady() then return end
	self.BasicCooldown:Use()
	
	-- use all cage cooldowns in an area to prevent cage spam
	for _, enemy in pairs(self:GetClass("Enemy").Instances) do
		if enemy:IsA(EnemyTerrorknightJailor) and enemy:DistanceTo(self:GetPosition()) < 256 then
			enemy.CageCooldown:Use()
		end
	end
	
	self:AnimationPlay("TK_Cast")
	
	delay(1, function()
		self:SoundPlay("Hit")
		
		if not self.Active then return end
		if not self.Target then return end
		
		local targetPosition = self.Target:GetFootPosition()
		local cframe = CFrame.new(targetPosition) * CFrame.Angles(0, math.pi * 2 * math.random(), 0)
		local size = 40
		local duration = 1
		
		self:GetService("EffectsService"):RequestEffectAll("LobProjectile", {
			Start = self.Model.RightHand.Position,
			Finish = targetPosition,
			Height = 12,
			Duration = duration,
			Model = self.Storage.Models.Terrorsquare,
		})
		
		local function cage()
			local model = Instance.new("Model")
			model.Name = "TerrorknightJailorCage"
			model.Parent = workspace.Enemies
			
			local part = Instance.new("Part")
			part.Anchored = true
			part.TopSurface = Enum.SurfaceType.Smooth
			part.BottomSurface = Enum.SurfaceType.Smooth
			part.Material = "Neon"
			part.Color = Color3.new(0.5, 0, 0)
			
			local distance = size / 2
			
			for step = 0, 3 do
				local c = cframe * CFrame.Angles(0, math.pi / 2 * step, 0)
				
				local pillar = part:Clone()
				pillar.CFrame = c * CFrame.new(distance, 4.5, distance)
				pillar.Parent = model
				do
					local s = Vector3.new(3, 9, 3)
					pillar.Size = s * Vector3.new(1, 0, 1)
					self:TweenNetwork{
						Object = pillar,
						Goals = {Size = s},
						Duration = 0.25,
					}
				end
				
				local rail = part:Clone()
				rail.CFrame = c * CFrame.new(0, 4, distance)
				rail.Parent = model
				do
					local s = Vector3.new(size - 3, 6, 1.5)
					rail.Size = s * Vector3.new(0, 1, 1)
					self:TweenNetwork{
						Object = rail,
						Goals = {Size = s},
						Duration = 0.25,
					}
				end
			end
			
			local collectionService = game:GetService("CollectionService")
			local physicsService = game:GetService("PhysicsService")
			for _, part in pairs(model:GetChildren()) do
				collectionService:AddTag(part, "InvisibleWall")
				physicsService:SetPartCollisionGroup(part, "EnemyPassable")
			end
			
			self:Sustain(self.CageDuration, nil, function()
				self:GetService("EffectsService"):RequestEffectAll("FadeModel", {
					Model = model,
					Duration = 1,
				})
				wait(1)
				model:Destroy()
			end)
		end
		
		self:AttackSquare{
			CFrame = cframe,
			Width = size,
			Length = size,
			Duration = duration,
			Color = Color3.new(1, 1/3, 0),
			OnHit = function() end,
		}
		
		self:Channel(duration, nil, cage)
	end)
end

function EnemyTerrorknightJailor:AttackBasic()
	if not self.BasicCooldown:IsReady() then return end
	self.BasicCooldown:Use()
	
	self:AnimationPlay("TK_Cast")
	
	delay(1, function()
		self:SoundPlay("Hit")
		
		if not self.Target then return end
		
		local here = self:GetPosition()
		local there = self.Target:GetPosition()
		local delta = (there - here) * Vector3.new(1, 0, 1)
		
		local projectile = self:CreateNew"Projectile"{
			Model = self.Storage.Models.Terrorbolt:Clone(),
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
							Type = "Piercing",
							Tags = {"Magical"},
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
	end)
end

function EnemyTerrorknightJailor:Flinch()
	-- don't
end

function EnemyTerrorknightJailor:IsTargetValid()
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

function EnemyTerrorknightJailor:CreateStateMachine()
	self.StateMachine = self:CreateNew"StateMachine"()
	
	self.StateMachine:AddState{
		Name = "Waiting",
		Run = function(state, machine, dt)
			self.Target = self:GetNearestTarget(self.DetectionRange)
			if self:IsTargetValid() then
				machine:ChangeState("Hovering")
			end
			self:StuckCheck(dt)
		end,
		OnStateWillChange = function()
			self:StuckReset()
		end
	}
	
	self.StateMachine:AddState{
		Name = "Hovering",
		Run = function(state, machine, dt)
			self.Target = self:GetNearestTarget(self.DetectionRange)
			if not self:IsTargetValid() then
				self.Target = nil
				return machine:ChangeState("Waiting")
			end
			
			local here = self.Target:GetPosition()
			local there = self:GetPosition()
			local delta = (there - here) * Vector3.new(1, 0, 1)
			local position = here + (delta.Unit * self.HoverRange)
			
			self:MoveTo(position)
			self.FacingPoint = here
			
			self:AttackCage()
			self:AttackBasic()
		end
	}
end

return EnemyTerrorknightJailor