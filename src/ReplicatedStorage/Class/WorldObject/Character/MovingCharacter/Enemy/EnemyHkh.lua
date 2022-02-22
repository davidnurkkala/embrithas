local Super = require(script.Parent)
local Enemy = Super:Extend()

local Projectile = Super:GetClass("Projectile")
local Effects = Super:GetService("EffectsService")
local function effect(...)
	Effects:RequestEffectAll(...)
end

local Sounds = Super.Storage.Sounds

Enemy.Resilient = true

Enemy.RangeByAttack = {
	Basic = 16,
	Basic2 = 16,
	DarkCage = 256,
	Projectile = 256,
	CenterLeap = 256,
	Carousel = 256,
	Slam = 256,
}

Enemy.WalkAnimation = "HkhWalk"

Enemy.DetectionRange = 128

Enemy.Frustration = 0
Enemy.FrustrationLimit = 3

Enemy.DialogueByDamageType = {
	Slashing = "So you prefer to slice your enemies to ribbons?",
	Piercing = "So you prefer to pierce your enemies' hearts?",
	Bludgeoning = "So you prefer to beat your enemies to a pulp?",
	Heat = "So you prefer to burn your enemies alive?",
	Cold = "So you prefer to freeze your enemies to death?",
	Internal = "So you prefer to bleed your enemies out?",
	Disintegration = "So you prefer to wither your enemies to dust?",
	Psychic = "So you prefer to break your enemies' minds?",
	Electrical = "So you prefer to shock your enemies with lightning?",
}

function Enemy:OnCreated()
	self.Target = nil
	self:CreateStateMachine()
	
	self.AttackPattern = self:CreateNew"AttackPattern"{Pattern = {
		"Projectile",
		"Basic", 3,
		"Basic2",
		"DarkCage",
		
		"CenterLeap",
		"Carousel",
		"Projectile",
		
		"Basic", 3,
		"Basic2", 3,
		"Slam", 2,
		
		"DarkCage", 2,
		
		"Basic", 2,
		"Basic2", 2,
		"Slam",
		"DarkCage",
		
		"CenterLeap",
		"Projectile", 3,
		
		"Slam", 5,
		
		"Basic", 4,
		"Basic2", 2,
		"Slam",
		"DarkCage", 3,
	}}
	
	Super.OnCreated(self)
	
	self:AnimationPlay("HkhIdle")
	self:GetService("MusicService"):PlayPlaylist{"Her Eternal Duty"}
	
	self.Speed.Base = 32
	
	self.DamageByType = {}
	self.ResistanceApplied = false
	self.ResistanceThreshold = 0.5
	
	self.DesperationApplied = false
	self.DesperationThreshold = 0.25
	
	self.CrystalThreshold = 0.85
	self.CrystalCooldown = self:CreateNew"Cooldown"{Time = 3}
	
	self.IntroStage = "Waiting"
	self:EpicEntrance()
end

function Enemy:OnDamaged(damage)
	self.DamageByType[damage.Type] = (self.DamageByType[damage.Type] or 0) + damage.Amount
end

function Enemy:OnUpdated(dt)
	Super.OnUpdated(self, dt)
	
	if self.Target and (not self.Target.Active) then
		self.Target = nil
	end
	
	local ratio = self.Health / self.MaxHealth:Get()
	
	if (not self.ResistanceApplied) and (ratio < self.ResistanceThreshold) then
		self:ApplyResistance()
	end
	
	if (not self.DesperationApplied) and (ratio < self.DesperationThreshold) then
		self.DesperationApplied = true
		self:Dialogue("Perhaps I have underestimated you...")
	end
	
	if self.CrystalCooldown:IsReady() and (ratio < self.CrystalThreshold) then
		self:CrystalAttack()
	end
	
	self.StateMachine:Run(dt)
end

function Enemy:GetCrystalCooldownTime()
	local ratio = self.Health / self.MaxHealth:Get()
	if ratio < 0.25 then
		return 0.75
	elseif ratio < 0.5 then
		return 1
	elseif ratio < 0.75 then
		return 1.25
	else
		return 1.5
	end
end

function Enemy:CrystalAttack()
	local speed = self:GetAttackSpeed()
	
	self.CrystalCooldown:Use(self:GetCrystalCooldownTime())
	
	local crystals = self:GetRun().Dungeon.Model.Crystals:GetChildren()
	local a = table.remove(crystals, math.random(1, #crystals)).Position
	local b = crystals[math.random(1, #crystals)].Position
	
	local cframe = CFrame.new((a + b) / 2, b)
	local length = (b - a).Magnitude
	local width = 12
	
	local duration = 1 / speed
	
	self:AttackSquare{
		CFrame = cframe,
		Length = length,
		Width = width,
		Duration = duration,
		OnHit = self:DamageFunc(1, "Disintegration", {"Magical"}),
		Sound = Sounds.MagicEerie2,
	}
end

function Enemy:ApplyResistance()
	self.ResistanceApplied = true
	
	local bestDamage = nil
	local bestAmount = 0
	for damage, amount in pairs(self.DamageByType) do
		if amount > bestAmount then
			bestDamage = damage
			bestAmount = amount
		end
	end
	
	self.Resistances[bestDamage].Base = 0.95
	
	local dialogue = self.DialogueByDamageType[bestDamage]
	self:Dialogue(dialogue.." So be it.")
	
	self.Invulnerable += 1
	delay(5, function()
		self:SoundPlayByObject(Sounds.CastDark2)
		effect("AirBlast", {
			StartRadius = 20,
			Radius = 0,
			Duration = 2,
			Position = self:GetPosition(),
			PartArgs = {
				Material = Enum.Material.Neon,
				Color = Color3.new(0, 0, 0),
			}
		})
		wait(2)
		self.Invulnerable -= 1
	end)
	
	self:Rest(7)
end

function Enemy:Dialogue(text)
	effect("OminousDialogue", {
		TweenDuration = 1,
		Duration = 3,
		FadeDuration = 1,
		TextArgs = {
			TextColor3 = Color3.new(0.333333, 0, 0.498039),
			TextSize = 20,
			Text = "<i>"..text.."</i>",
		}
	})
end

function Enemy:EpicEntrance()
	self.Target = self:GetNearestTarget(self.DetectionRange)
	if self:IsTargetValid() then
		self:FaceTowards(self.Target:GetPosition())
	end
	
	effect("Shockwave", {
		CFrame = CFrame.new(self:GetFootPosition()),
		StartSize = Vector3.new(16, 256, 16),
		EndSize = Vector3.new(16, 0, 16),
		Duration = 1,
		PartArgs = {
			Material = Enum.Material.Neon,
			Color = Color3.new(0, 0, 0),
		}
	})
	
	effect("AirBlast", {
		Position = self:GetPosition(),
		StartRadius = 20,
		Radius = 60,
		Duration = 2,
		PartArgs = {
			Material = Enum.Material.Neon,
			Color = Color3.new(0, 0, 0),
		}
	})
	
	-- epic appearance
	self:SoundPlayByObject(Sounds.LightningHeavy)
	self:SoundPlayByObject(Sounds.LightningMedium)
	
	-- kill lives
	self:GetRun():DestroyLives()
	
	-- swag
	self.Invulnerable += 1
	delay(3, function()
		self:Dialogue("I will grant you the first blow.")
		
		wait(5)
		
		self.Invulnerable -= 1
	end)
end

function Enemy:Rest(duration)
	self.StateMachine:ChangeState("Resting", {
		Duration = duration,
		NextState = "Chasing",
	}, true)
end

function Enemy:GetAttackSpeed()
	local base = 1
	if self.Health / self.MaxHealth:Get() <= 0.5 then
		base = 1.2
	end
	if self.DesperationApplied then
		base = 1.35
	end
	return base * self.AttackSpeed
end

function Enemy:DarkSphere(position, radius, duration, sound)
	self:AttackCircle{
		Position = position,
		Radius = radius,
		Duration = duration,
		OnHit = self:DamageFunc(1, "Disintegration", {"Magical"}),
		Effect = {Type = "AirBlast", Args = {
			Position = position,
			Radius = radius,
			Duration = 0.2,
			PartArgs = {
				Material = Enum.Material.Neon,
				Color = Color3.new(0, 0, 0),
			}
		}},
		Sound = sound,
	}
	
	effect("AirBlast", {
		Position = position,
		StartRadius = radius,
		Radius = 0,
		Duration = duration,
		PartArgs = {
			Material = Enum.Material.Neon,
			Color = Color3.new(0, 0, 0),
		}
	})
end

function Enemy:AttackSlam()
	local speed = self:GetAttackSpeed()
	local radius = 16
	local attackDuration = 0.8 / speed
	
	local targetPosition = self.Target:GetPosition() + self.Target:GetFlatVelocity() * attackDuration
	local cframe = self:GetFootCFrameTo(targetPosition)
	
	self:FaceTowards(targetPosition)
	self:AnimationPlay("HkhSlam", nil, nil, 27/30 / attackDuration)
	
	local length = 16
	local width = 8
	
	self:TelegraphDirectional{
		CFrame = cframe * CFrame.new(0, 0, -length),
		Length = length,
		Width = width,
		Duration = attackDuration,
		Callback = function()
			self:SoundPlayByObject(Sounds.ExplosionMassive)
			
			for step = 0, 9 do
				delay(step * 0.2, function()
					local dz = radius * 0.6 * step
					local position = (cframe * CFrame.new(0, 0, -dz)).Position
					
					self:AttackCircle{
						Position = position,
						Radius = radius,
						Duration = 0.1,
						OnHit = self:DamageFunc(1, "Bludgeoning"),
						Sound = Sounds.ExplosionQuick,
					}
				end)
			end
		end,
	}
	
	self:Rest(attackDuration)
end

function Enemy:AttackCarousel()
	local speed = self:GetAttackSpeed()
	
	local centerCFrame = self:GetFootCFrameTo(self.Target:GetPosition())
	local length = 64
	local width = 16
	local stepDuration = 0.2 / speed
	local attackDuration = 0.6 / speed
	
	local function swing(theta, animationName)
		local cframe = centerCFrame * CFrame.Angles(0, theta, 0) * CFrame.new(0, 0, -length / 2)
		local animationSpeed = 6
		local windUpDuration = 17/30 / animationSpeed
		local waitDuration = attackDuration - windUpDuration
		
		self:AttackSquare{
			CFrame = cframe,
			Length = length,
			Width = width,
			Duration = attackDuration,
			OnHit = self:DamageFunc(1, "Slashing"),
		}
		
		wait(waitDuration)
		
		self:FaceTowards(cframe.Position)
		self:AnimationPlay("Hkh"..animationName, nil, nil, animationSpeed)
	end
	
	local stepCount = 30
	local offset = -math.pi / 2
	for step = 0, stepCount - 1 do
		local theta = offset + (math.pi * 2) * (step / stepCount)
		
		delay(stepDuration * step, function()
			swing(theta, "Slash1")
		end)
		delay(stepDuration * (step + 0.5), function()
			swing(theta + math.pi, "Slash2")
		end)
	end
	
	local totalDuration = stepDuration * stepCount + attackDuration
	
	self:Rest(totalDuration)
end

function Enemy:AttackCenterLeap()
	local speed = self:GetAttackSpeed()
	
	local center = self:GetRun().Dungeon.Model.Center.Position
	
	local jumpDuration = 0.9 / speed
	local jumpRadius = 40
	
	self:AnimationPlay("HkhDash", nil, nil, 32/30 / jumpDuration)
	self:FaceTowards(center)
	
	self:AttackCircle{
		Position = center,
		Radius = jumpRadius,
		Duration = jumpDuration,
		OnHit = self:DamageFunc(1, "Bludgeoning"),
		Sound = Sounds.ExplosionMassive,
		Effect = {Type = "AirBlast", Args ={
			Position = center,
			Radius = jumpRadius,
			Duration = 0.25,
			PartArgs = {Material = Enum.Material.Neon, Color = Color3.new(0, 0, 0)},
		}},
	}
	
	local windUpDuration = jumpDuration * 12/30
	local airDuration = jumpDuration * 10/30
	
	delay(windUpDuration, function()
		local here = self:GetPosition()
		local delta = (center - here) * Vector3.new(1, 0, 1)
		local cframe = self.Root.CFrame + delta
		
		self:TweenNetwork{
			Object = self.Root,
			Goals = {CFrame = cframe},
			Duration = airDuration,
			Style = Enum.EasingStyle.Linear,
		}
	end)
	
	local crystalDuration = 0.4 / speed
	
	delay(jumpDuration, function()
		local crystals = self:GetRun().Dungeon.Model.Crystals:GetChildren()
		local width = 12
		for _, crystal in pairs(crystals) do
			local there = crystal.Position
			local delta = there - center
			local length = delta.Magnitude - jumpRadius
			local cframe = CFrame.new(center, there) * CFrame.new(0, 0, -jumpRadius - length / 2)
			
			self:AttackSquare{
				CFrame = cframe,
				Length = length,
				Width = width,
				Duration = crystalDuration,
				Sound = Sounds.Silence,
				OnHit = self:DamageFunc(1, "Disintegration", {"Magical"}),
			}
		end
	end)
	
	self:Rest(jumpDuration + crystalDuration)
end

function Enemy:AttackProjectile()
	local speed = self:GetAttackSpeed()
	
	local attackDuration = 0.5 / speed
	local restDuration = 0.5 / self.RestSpeed
	
	self:AnimationPlay("HkhCast", nil, nil, 10/30 / attackDuration)
	
	local there = self.Target:GetPosition()
	
	local stepCount = 9
	for step = 0, stepCount - 1 do
		local theta = math.pi * 2 * (step / stepCount)
		local angle = CFrame.Angles(0, theta, 0)
		
		self:TelegraphDirectional{
			Duration = attackDuration,
			CFrame = self:GetFootCFrameTo(there) * angle * CFrame.new(0, 0, -8),
			Length = 8,
			Width = 4,
			Callback = function()
				if step == 0 then
					self:SoundPlayByObject(Sounds.CastDark)
				end
				
				Projectile.CreateHostileProjectile{
					CFrame = self:GetCFrameTo(there) * angle,
					Speed = 16 * speed,
					Range = 128 + (8 * step),
					Width = 2,
					Model = self.Storage.Models.ShadowBoltLarge,
					DeactivationType = "Enemy",
					
					OnTicked = function(projectile, dt)
						if self:IsTargetValid() then
							there = self.Target:GetPosition()
						end
						projectile:TiltTowards(there, math.pi / 3 * speed, dt)
					end,
					
					OnEnded = function(projectile)
						self:DarkSphere(self:GetFootPosition(projectile.CFrame.Position), 8, 0.25, Sounds.MagicEerie)
					end,
				}
			end,
		}
	end
	
	self:Rest(attackDuration / restDuration)
end

function Enemy:AttackStopThat()
	self:Dialogue("I have no interest in dueling cowards. Stand and fight!")
	self:DarkSphere(self.Target:GetPosition(), 16, 0.2, Sounds.MagicEerie2)
end

function Enemy:AttackDarkCage()
	local speed = self:GetAttackSpeed()
	
	local attackDuration = 0.5 / speed
	local restDuration = 0.5 / self.RestSpeed
	
	local durationOuter = 0.7 / speed
	local pause = 0.5 / speed
	local durationInner = 0.7 / speed
	
	self:AnimationPlay("HkhCast", nil, nil, 10/30 / attackDuration)
	
	local radiusInner = 16
	local radiusOuter = 10
	
	local position = self.Target:GetFootPosition()
	
	local stepCount = 7
	for step = 0, stepCount - 1 do
		local theta = math.pi * 2 * (step / stepCount)
		local r = radiusInner + (radiusOuter / 2)
		local outerPosition = position + Vector3.new(math.cos(theta) * r, 0, math.sin(theta) * r)
		local sound = (step == 0) and Sounds.MagicEerie or Sounds.Silence
		self:DarkSphere(outerPosition, radiusOuter, durationOuter, sound)
	end
	
	delay(pause, function()
		self:DarkSphere(position, radiusInner, durationInner, Sounds.MagicEerie2)
	end)
	
	self:Rest(attackDuration + restDuration)
end

function Enemy:AttackBasic()
	local speed = self:GetAttackSpeed()
	
	local attackDuration = 0.7 / speed
	local restDuration = 0.1 / self.RestSpeed
	
	local length = 32
	local width = 12
	
	local here = self:GetFootPosition()
	local there = self.Target:GetFootPosition()
	local delta = (there - here) * Vector3.new(1, 0, 1)
	local cframe = CFrame.new(here, here + delta) * CFrame.new(0, 0, -length / 2)
	
	self:AttackSquare{
		CFrame = cframe,
		Duration = attackDuration,
		Length = length,
		Width = width,
		OnHit = self:DamageFunc(1, "Slashing"),
	}
	
	self:FaceTowards(there)
	self:AnimationPlay("HkhSlash1", nil, nil, 17/30 / attackDuration)
	
	self:Rest(attackDuration + restDuration)
end

function Enemy:AttackBasic2()
	local speed = self:GetAttackSpeed()

	local attackDuration = 0.7 / speed
	local restDuration = 0.1 / self.RestSpeed

	local length = 24
	local overlap = 8
	local width = 20

	local here = self:GetFootPosition()
	local there = self.Target:GetFootPosition()
	local delta = (there - here) * Vector3.new(1, 0, 1)
	local cframe = CFrame.new(here, here + delta) * CFrame.new(0, 0, -length / 2 + overlap / 2)

	self:AttackSquare{
		CFrame = cframe,
		Duration = attackDuration,
		Length = length + overlap,
		Width = width,
		OnHit = self:DamageFunc(1, "Slashing"),
	}

	self:FaceTowards(there)
	self:AnimationPlay("HkhSlash2", nil, nil, 17/30 / attackDuration)

	self:Rest(attackDuration + restDuration)
end

function Enemy:Flinch()
	-- don't
end

function Enemy:Ragdoll()
	-- don't
end

function Enemy:IsTargetValid()
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

function Enemy:CreateStateMachine()
	self.StateMachine = self:CreateNew"StateMachine"()
	
	self.StateMachine:AddState{
		Name = "Waiting",
		Run = function(state, machine, dt)
			if self.IntroStage == "Waiting" then
				if self.Health < self.MaxHealth:Get() then
					self.IntroStage = "Talking"
					
					delay(3, function()
						self:Dialogue("Weak. This will be over quickly.")
						wait(5)
						self.IntroStage = "Finished"
					end)
				end
				return
			end
			
			if self.IntroStage == "Talking" then
				return
			end
			
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
				self.AttackPattern.Index = 5
				self:AttackStopThat()
				return
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

return Enemy