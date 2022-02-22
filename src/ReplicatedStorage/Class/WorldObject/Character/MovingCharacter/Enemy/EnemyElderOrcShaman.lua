local Super = require(script.Parent)
local EnemyElderOrcShaman = Super:Extend()

EnemyElderOrcShaman.Resilient = true

function EnemyElderOrcShaman:OnCreated()
	self.Target = nil
	self:CreateStateMachine()
	
	self.AttackPattern = self:CreateNew"AttackPattern"{Pattern = {
		"Cast",
		"Swipe", 3,
		"Combo", 3,
		"Swipe", 3,
		"Combo",
		"Swipe",
		"Combo",
		"Swipe",
		"Combo", 3,
		"Summon",
		"Swipe", 2,
		"Combo", 3,
	}}
	
	Super.OnCreated(self)
	
	self:AnimationPlay("OrcElderShamanIdle")
	self:GetService("MusicService"):PlayPlaylist{"Wild Magic"}
	
	self.Speed.Base = 24
end

function EnemyElderOrcShaman:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	self.StateMachine:Run(dt)
end

EnemyElderOrcShaman.RangeByAttack = {
	Cast = 128,
	Summon = 128,
	Swipe = 12,
	Combo = 32,
}

EnemyElderOrcShaman.WalkAnimation = "OrcElderShamanWalk"

EnemyElderOrcShaman.DetectionRange = 128

EnemyElderOrcShaman.Frustration = 0
EnemyElderOrcShaman.FrustrationLimit = 2

function EnemyElderOrcShaman:AttackCast()
	local function seeker(cframe)
		local turnRate = math.pi * 0.75
		local speed = 48
		
		local telegraphTime = 0.75
		
		local timeline = self:CreateNew"Timeline"{
			Time = 15,
			Interval = 0.25,
			Cancel = function(t)
				t.Active = false
			end,
			OnTicked = function(t, dt)
				local target = self:GetNearestTarget(128, nil, false, cframe.Position)
				if target then
					local delta = cframe:PointToObjectSpace(target:GetPosition()) * Vector3.new(1, 0, 1)
					
					local angle = math.atan2(delta.X, -delta.Z)
					local rotation = math.min(math.abs(angle), turnRate * dt)
					local rotationDirection = -math.sign(angle)
					
					cframe *= CFrame.Angles(0, rotation * rotationDirection, 0)
					cframe *= CFrame.new(0, 0, -speed * dt)
					
					local position = cframe.Position
					self:AttackCircle{
						Position = position,
						Radius = 8,
						Duration = telegraphTime,
						OnHit = self:DamageFunc(1, "Electrical"),
						Sound = self.EnemyData.Sounds.Lightning,
					}
					delay(telegraphTime, function()
						self:GetService("EffectsService"):RequestEffectAll("Thunderstrike", {
							Position = position,
							SoundEnabled = false,
						})
					end)
				end
			end,
		}
		table.insert(self.Telegraphs, timeline)
		timeline:Start()
	end
	
	local windup = 18/30
	
	self:AnimationPlay("OrcElderShamanCast")
	
	delay(windup, function()
		self:SoundPlay("Cast")
		
		local count = 3
		local theta = math.pi * 2 * math.random()
		for step = 1, count do
			local here = self:GetFootPosition()
			local cframe = CFrame.new(here) * CFrame.Angles(0, theta + (math.pi * 2 / count) * step, 0)
			seeker(cframe)
		end
	end)
	
	self.StateMachine:ChangeState("Resting", {
		Duration = 1,
		NextState = "Waiting"
	})
end

function EnemyElderOrcShaman:AttackCombo()
	local pause = 0.4
	
	local speed = 0.7
	local meleeWindup = 10/30 / speed
	local rangeWindup = 21/30 / speed
	
	local function projectile(cframe)
		local projectileSpeed = 16
		
		local projectile = self:CreateNew"Projectile"{
			Model = self.Storage.Models.FireBolt:Clone(),
			CFrame = cframe,
			Velocity = cframe.LookVector * projectileSpeed,
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
							Type = "Heat",
							Tags = {"Magical"},
						}
						character:SoundPlayByObject(self.Storage.Sounds.FireHit)

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
	
	local here = self:GetFootPosition() + Vector3.new(0, 2, 0)
	local there = self.Target:GetPosition()
	local delta = (there - here) * Vector3.new(1, 0, 1)
	local cframe = CFrame.new(here, here + delta)
	
	delay(pause, function()
		self:AnimationPlay("OrcElderShamanSmashThenSweep", nil, nil, speed)
		
		wait(rangeWindup)
		
		local angle = math.pi
		local count = 9
		for step = 0, count - 1 do
			local theta = (-angle / 2) + (angle / count) * (step + 0.5)
			local c = cframe * CFrame.Angles(0, theta, 0)
			projectile(c)
		end
		self:SoundPlayByObject(self.Storage.Sounds.FireCast)
	end)
	
	self:AttackCircle{
		Position = self:GetFootPosition(),
		Radius = 12,
		Duration = pause + meleeWindup,
		OnHit = self:DamageFunc(1, "Bludgeoning"),
	}
	
	self.StateMachine:ChangeState("Resting", {
		Duration = pause + 32/30 / speed,
		NextState = "Waiting",
	})
end

function EnemyElderOrcShaman:AttackSwipe()
	local speed = 0.6
	local windup = 12/30 / speed
	local swipeDuration = 5/30 / speed
	
	local radius = 8
	
	local here = self:GetFootPosition()
	local there = self.Target:GetPosition()
	local delta = (there - here) * Vector3.new(1, 0, 1)
	there = here + delta
	self:FaceTowards(there)
	
	local cframe = CFrame.new(here, here + delta)
	
	local count = 5
	local angle = math.pi * 1.5
	
	for step = 0, count - 1 do
		local theta = (-angle / 2) + (angle / count) * (step + 0.5)
		local c = cframe * CFrame.Angles(0, theta, 0) * CFrame.new(0, 0, -radius)
		
		local pause = (swipeDuration / count) * step
		delay(pause, function()
			self:AttackCircle{
				Position = c.Position,
				Radius = radius,
				Duration = windup,
				OnHit = self:DamageFunc(1, "Piercing"),
			}
		end)
	end
	
	self:AnimationPlay("OrcElderShamanSwipe", nil, nil, speed)
	
	self.StateMachine:ChangeState("Resting", {
		NextState = "Waiting",
		Duration = 1 / speed,
	})
end

function EnemyElderOrcShaman:AttackSummon()
	local windup = 20/30
	
	local center = self:GetRun().Dungeon.Model.Center.Position
	local radius = 80
	local count = 3
	local angle = math.pi * 2 * math.random()
	
	local function summon(position)
		local enemyService = self:GetService("EnemyService")
		
		local function effect()
			local effects = self:GetService("EffectsService")
			effects:RequestEffectAll("Sound", {
				Position = position,
				Sound = self.EnemyData.Sounds.Cast,
			})
			effects:RequestEffectAll("AirBlast", {
				Position = position,
				Color = Color3.fromRGB(61, 21, 133),
				Radius = 32,
				Duration = 1,
			})
		end
		
		local crystal = self:CreateNew"Enemy"{
			Name = "Corruption Crystal",
			EnemyData = self.Storage.Enemies["Corruption Crystal"],
			StartCFrame = CFrame.new(position),
		}
		crystal.MaxHealth.Base = enemyService:GetHealthFromTimeToDie(5, self.Level)
		crystal.Health = crystal.MaxHealth:Get()
		self:GetWorld():AddObject(crystal)
		
		local billboard = self.Storage.UI.CountdownBillboard:Clone()
		billboard.Adornee = crystal.Root
		billboard.Parent = crystal.Model
		crystal:Channel(10, function(t, dt)
			billboard.Text.Text = math.ceil(t.Time)
		end, function()
			crystal:Deactivate()
			
			local enemy = enemyService:CreateEnemy("Orc Lieutenant", self.Level, false){
				StartCFrame = CFrame.new(position) + Vector3.new(0, 8, 0)
			}
			enemyService:ApplyDifficultyToEnemy(enemy)
			self:GetWorld():AddObject(enemy)
			
			effect()
		end)
		
		effect()
	end
	
	self:AnimationPlay("OrcElderShamanSummon")
	
	for step = 0, count - 1 do
		local theta = angle + (math.pi * 2 / count) * step
		local dx = math.cos(theta) * radius
		local dz = math.sin(theta) * radius
		local position = center + Vector3.new(dx, 0, dz)
		
		delay(windup + step * 0.3, function()
			summon(position)
		end)
	end
	
	self.StateMachine:ChangeState("Resting", {
		Duration = 37/30,
		NextState = "Waiting",
	})
end

function EnemyElderOrcShaman:Flinch()
	-- don't
end

function EnemyElderOrcShaman:IsTargetValid()
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

function EnemyElderOrcShaman:CreateStateMachine()
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

return EnemyElderOrcShaman