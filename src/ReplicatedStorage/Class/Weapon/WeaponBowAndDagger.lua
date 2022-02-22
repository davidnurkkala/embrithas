local Super = require(script.Parent)
local WeaponBowAndDagger = Super:Extend()

WeaponBowAndDagger.PrimaryStatName = "Agility"

WeaponBowAndDagger.Range = 32
WeaponBowAndDagger.PointBlankRange = WeaponBowAndDagger.Range / 2
WeaponBowAndDagger.MeleeRange = 8
WeaponBowAndDagger.AttackLightDamageMultiplier = 1
WeaponBowAndDagger.ProjectileSpeed = 96
WeaponBowAndDagger.ProjectileCount = 1
WeaponBowAndDagger.ProjectileAngle = 0
WeaponBowAndDagger.ProjectileHoming = false
WeaponBowAndDagger.ProjectileHomingRotationSpeed = math.pi
WeaponBowAndDagger.ProjectileHomingRange = 16
WeaponBowAndDagger.ProjectileModel = Super.Storage.Models.Arrow
WeaponBowAndDagger.DisplayName = "Bow & Dagger"
WeaponBowAndDagger.DescriptionLight = "Shoot arrows."
WeaponBowAndDagger.DescriptionHeavy = "Stab enemies."

WeaponBowAndDagger.CooldownLightTime = 0.6
WeaponBowAndDagger.CooldownHeavyTime = 0.3

function WeaponBowAndDagger:OnCreated()
	Super.OnCreated(self)
end

function WeaponBowAndDagger:SwitchModels(mode)
	if self.ModelMode == mode then return end
	self.ModelMode = mode
	
	if mode == "Melee" then
		self.Dagger.Transparency = 0
		self.SheathedDagger.Transparency = 1
		self.Bow.Transparency = 1
		self.Bow.String.Visible = false
		self.SlungBow.Transparency = 0
		self.SlungBow.String.Visible = true
		
		self.Legend:SetRunAnimation("SingleWeapon")
		
	elseif mode == "Ranged" then
		self.Dagger.Transparency = 1
		self.SheathedDagger.Transparency = 0
		self.Bow.Transparency = 0
		self.Bow.String.Visible = true
		self.SlungBow.Transparency = 1
		self.SlungBow.String.Visible = false
		
		self.Legend:SetRunAnimation("LeftHanded")
	elseif mode == "None" then
		self.Dagger.Transparency = 1
		
		self.Bow.Transparency = 1
		self.Bow.String.Visible = false
		
		self.SheathedDagger.Transparency = 0
		
		self.SlungBow.Transparency = 0
		self.SlungBow.String.Visible = true
		
		self.Legend:SetRunAnimation("NoWeapons")
	end
end

function WeaponBowAndDagger:FireProjectile(cframe, speed, onHitCallback)
	self:CreateGenericProjectile{
		Model = self.ProjectileModel:Clone(),
		CFrame = cframe,
		Speed = speed,
		Width = 4,
		OnHitTarget = function(target)
			self:GetService("DamageService"):Damage{
				Source = self.Legend,
				Target = target,
				Amount = self:GetDamage() * self.AttackLightDamageMultiplier,
				Weapon = self,
				Type = "Piercing",
				Tags = self.DamageTags,
			}
			
			self:HitEffects(target, false)

			local sounds = self.Assets.Sounds:FindFirstChild("HitArrow")
			if not sounds then
				sounds = self.Assets.Sounds.Hit
			end
			local sound = self:Choose(sounds:GetChildren())

			target:SoundPlayByObject(sound)

			onHitCallback(target)
			
			if target:IsDead() then
				self:GetService("QuestService"):ProcessGameplayEvent(self.Legend.Player, {Type = "KillWithProjectile"})
			end
		end,
		OnTicked = function(projectile, dt)
			if self.ProjectileHoming then
				local here = projectile.CFrame.Position
				local there

				local targeting = self:GetService("TargetingService")
				targeting:TargetCircleNearest(targeting:GetEnemies(), {
					Position = here,
					Range = self.ProjectileHomingRange,
					Callback = function(target)
						there = target:GetPosition()
					end,
				})

				if not there then return end

				local delta = projectile.CFrame:PointToObjectSpace(there)
				local angle = math.atan2(delta.X, -delta.Z)

				local rotation = self.ProjectileHomingRotationSpeed * -math.sign(angle) * dt
				if math.abs(rotation) > math.abs(angle) then
					rotation = angle
				end

				local cframe = projectile.CFrame * CFrame.Angles(0, rotation, 0)
				projectile.Velocity = cframe.LookVector * projectile.Velocity.Magnitude
			end
		end,
	}
end

function WeaponBowAndDagger:OnUpdated(dt)
	if self.CustomOnUpdated then
		self:CustomOnUpdated(dt)
	end
end

function WeaponBowAndDagger:AttackHeavy()
	if not self.CooldownHeavy:IsReady() then return end
	self.CooldownHeavy:Use()
	self.CooldownLight:Use(self.CooldownHeavy.Time)
	
	self:SwitchModels("Melee")
	self:AttackSound()
	self.Legend:AnimationPlay("BowDaggerStab", 0)
	
	local didAttack = false
	
	self.Targeting:TargetMelee(self.Targeting:GetEnemies(), {
		CFrame = self.Legend:GetAimCFrame(),
		Width = 6,
		Length = 10,
		Callback = function(enemy)
			local damage = self:GetService"DamageService":Damage{
				Source = self.Legend,
				Target = enemy,
				Amount = self:GetDamage() * 0.5,
				Weapon = self,
				Type = "Piercing",
			}

			self:HitEffects(enemy)

			didAttack = true
		end
	})
	
	if didAttack then
		self.Attacked:Fire()
		
		if self.OnAttackedHeavy then
			self:OnAttackedHeavy()
		end
	end
	
	return true
end

function WeaponBowAndDagger:AttackLight()
	if not self.CooldownLight:IsReady() then return end
	
	if self.CustomAttackLightAble then
		if not self:CustomAttackLightAble() then return end
	end
	
	local speed = 1
	if self:HasModifier("Loaded") then
		speed = 1.5
	end
	
	self.CooldownLight:Use(self.CooldownLight.Time / speed)
	self.CooldownHeavy:Use()

	self:SwitchModels("Ranged")
	self:ShootSound()
	self:ShootAnimation()
	
	self:RangedWeaponSlow()

	local cframe = self.Legend:GetAimCFrame()

	local count = self.ProjectileCount
	local start = -self.ProjectileAngle / 2
	
	local step = 0
	if count > 1 then
		step = self.ProjectileAngle / (count - 1)
	end
	
	local didAttack = false

	for number = 1, count do
		local theta = math.rad(start + step * (number - 1))
		local rotated = cframe * CFrame.Angles(0, theta, 0)

		self:FireProjectile(rotated, self.ProjectileSpeed, function(enemy)
			if self.OnLightHitEnemy then
				self:OnLightHitEnemy(enemy)
			end
			
			if not didAttack then
				didAttack = true
				self.Attacked:Fire()
			end
		end)
	end
	
	if self.OnAttackedLight then
		self:OnAttackedLight()
	end

	return true
end

function WeaponBowAndDagger:GetProjectileHitSound()
	local sounds = self.Assets.Sounds.Hit:GetChildren()
	return sounds[math.random(1, #sounds)]
end

function WeaponBowAndDagger:ShootAnimation()
	self:SwitchModels("Ranged")
	self.Legend:AnimationPlay("BowShoot", 0)
end

function WeaponBowAndDagger:ShootHighAnimation()
	self:SwitchModels("Ranged")
	self.Legend:AnimationPlay("BowShootHigh", 0)
end

function WeaponBowAndDagger:ShootSound()
	self.Legend:SoundPlayByObject(self.Assets.Sounds.Shot)
end

function WeaponBowAndDagger:Equip()
	local dagger = self.Assets.Dagger:Clone()
	dagger.Parent = self.Legend.Model
	dagger.Weld.Part1 = dagger
	dagger.Weld.Part0 = self.Legend.Model.RightHand
	self.Dagger = dagger
	
	local bow = self.Assets.Bow:Clone()
	bow.Parent = self.Legend.Model
	bow.Weld.Part1 = bow
	bow.Weld.Part0 = self.Legend.Model.LeftHand
	self.Bow = bow
	
	local sheathedDagger = self.Assets.SheathedDagger:Clone()
	sheathedDagger.Parent = self.Legend.Model
	sheathedDagger.Weld.Part1 = sheathedDagger
	sheathedDagger.Weld.Part0 = self.Legend.Model.LowerTorso
	self.SheathedDagger = sheathedDagger
	
	local slungBow = self.Assets.SlungBow:Clone()
	slungBow.Parent = self.Legend.Model
	slungBow.Weld.Part1 = slungBow
	slungBow.Weld.Part0 = self.Legend.Model.UpperTorso
	self.SlungBow = slungBow
	
	self:SwitchModels("Ranged")
end

function WeaponBowAndDagger:Unequip()
	self.Legend.WeaponBowAndDaggerAmmunition = self.Ammunition
	
	self.Dagger:Destroy()
	self.Bow:Destroy()
	self.SheathedDagger:Destroy()
	self.SlungBow:Destroy()
end

function WeaponBowAndDagger:GetProjectileModel()
	return self.ProjectileModel
end

function WeaponBowAndDagger:Sheath()
	self:SwitchModels("None")
end

function WeaponBowAndDagger:Unsheath()
	-- do nothing handled elsewhere
end

return WeaponBowAndDagger