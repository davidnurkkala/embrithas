local Super = require(script.Parent)
local WeaponCrossbowAndShortsword = Super:Extend()

WeaponCrossbowAndShortsword.PrimaryStatName = "Agility"

WeaponCrossbowAndShortsword.ProjectileSpeed = 160
WeaponCrossbowAndShortsword.ProjectileModel = Super.Storage.Models.Arrow
WeaponCrossbowAndShortsword.DisplayName = "Crossbow & Shortsword"
WeaponCrossbowAndShortsword.DescriptionLight = "Slash enemies."
WeaponCrossbowAndShortsword.DescriptionHeavy = "Reload. If loaded, fire a piercing bolt."

WeaponCrossbowAndShortsword.CooldownLightTime = 0.5
WeaponCrossbowAndShortsword.CooldownHeavyTime = 1.5

WeaponCrossbowAndShortsword.ShootTime = 0.5
WeaponCrossbowAndShortsword.ReloadTime = 1.5

function WeaponCrossbowAndShortsword:OnCreated()
	Super.OnCreated(self)
	
	self.AttackNumber = 0
	
	if self.Legend.WeaponCrossbowAndShortswordLoaded then
		self.Loaded = self.Legend.WeaponCrossbowAndShortswordLoaded
	else
		self.Loaded = false
	end
end

function WeaponCrossbowAndShortsword:SwitchModels(mode)
	if self.ModelMode == mode then return end
	self.ModelMode = mode
	
	if mode == "Melee" then
		self.Sword.Transparency = 0
		self.SheathedSword.Transparency = 1
		self.Crossbow.Transparency = 1
		self.Crossbow.String.Visible = false
		self.SlungCrossbow.Transparency = 0
		self.SlungCrossbow.String.Visible = true
		
		self.Legend:SetRunAnimation("SingleWeapon")
		
	elseif mode == "Ranged" then
		self.Sword.Transparency = 1
		self.SheathedSword.Transparency = 0
		self.Crossbow.Transparency = 0
		self.Crossbow.String.Visible = true
		self.SlungCrossbow.Transparency = 1
		self.SlungCrossbow.String.Visible = false
		
		self.Legend:SetRunAnimation("SingleWeapon")
		
	elseif mode == "None" then
		self.Sword.Transparency = 1
		
		self.Crossbow.Transparency = 1
		self.Crossbow.String.Visible = false
		
		self.SheathedSword.Transparency = 0
		
		self.SlungCrossbow.Transparency = 0
		self.SlungCrossbow.String.Visible = false
		
		self.Legend:SetRunAnimation("NoWeapons")
	end
end

function WeaponCrossbowAndShortsword:OnDealtDamage(damage)
	if self.CustomOnDealtDamage then
		self:CustomOnDealtDamage(damage)
	end
end

function WeaponCrossbowAndShortsword:OnUpdated(dt)
	self:FireRemote("AmmoUpdated", self.Legend.Player, {
		Type = "Update",
		Ammo = self.Loaded and 1 or 0,
		AmmoMax = 1,
		AmmoType = "Bolts",
		AmmoImage = "rbxassetid://5267330837",
	})
end

function WeaponCrossbowAndShortsword:Shoot()
	self.CooldownHeavy:Use(self.ShootTime)
	self.CooldownLight:Use()
	
	self:SwitchModels("Ranged")
	self:ShootAnimation()
	self:ShootSound()
	
	self:RangedWeaponSlow()
	
	local cframe = self.Legend:GetAimCFrame()
	
	self:CreateGenericProjectile{
		Model = self.ProjectileModel:Clone(),
		CFrame = cframe,
		Speed = self.ProjectileSpeed,
		DeactivationType = "Wall",
		Width = 4,
		OnHitTarget = function(target)
			self:GetService("DamageService"):Damage{
				Source = self.Legend,
				Target = target,
				Amount = self:GetDamage() * 4,
				Weapon = self,
				Type = "Piercing",
			}

			self:HitEffects(target, false)

			local sounds = self.Assets.Sounds:FindFirstChild("HitArrow")
			if not sounds then
				sounds = self.Assets.Sounds.Hit
			end
			local sound = self:Choose(sounds:GetChildren())

			target:SoundPlayByObject(sound)
			
			if target:IsDead() then
				self:GetService("QuestService"):ProcessGameplayEvent(self.Legend.Player, {Type = "KillWithProjectile"})
			end
		end,
	}
	
	self.Loaded = false
end

function WeaponCrossbowAndShortsword:GetProjectileHitSound()
	local sounds = self.Assets.Sounds.Hit:GetChildren()
	return sounds[math.random(1, #sounds)]
end

function WeaponCrossbowAndShortsword:ShootAnimation()
	self:SwitchModels("Ranged")
	self.Legend:AnimationPlay("CrossbowShoot", 0)
end

function WeaponCrossbowAndShortsword:ShootHighAnimation()
	self:SwitchModels("Ranged")
	self.Legend:AnimationPlay("CrossbowShootHigh", 0)
end

function WeaponCrossbowAndShortsword:ShootSound()
	self.Legend:SoundPlayByObject(self.Assets.Sounds.Shot)
end

function WeaponCrossbowAndShortsword:Reload()
	local speed = 1
	if self:HasModifier("Loaded") then
		speed = 2
	end
	
	self.CooldownHeavy:Use(self.ReloadTime / speed)
	self.CooldownLight:Use()
	
	self:SwitchModels("Ranged")
	self.Legend:AnimationPlay("CrossbowReload", nil, nil, speed)
	
	local sound = self.Legend:SoundPlayByObject(self.Assets.Sounds.Reload)
	sound.PlaybackSpeed = speed
	
	self:RangedWeaponSlow()
	self.Loaded = true
end

function WeaponCrossbowAndShortsword:AttackHeavy()
	if not self.CooldownHeavy:IsReady() then return end
	
	if self.Loaded then
		self:Shoot()
	else
		self:Reload()
	end
	
	return true
end

function WeaponCrossbowAndShortsword:AttackLight()
	if not self.CooldownLight:IsReady() then return end
	self.CooldownLight:Use()
	self.CooldownHeavy:UseMinimum(self.CooldownLight.Time)

	self:AttackSound()
	self.Legend:AnimationPlay("SwordShieldAttackLight"..self.AttackNumber, 0)
	self.AttackNumber = (self.AttackNumber + 1) % 2
	
	self:SwitchModels("Melee")

	local didAttack = false

	self.Targeting:TargetCone(self.Targeting:GetEnemies(), {
		CFrame = self.Legend:GetAimCFrame(),
		Angle = 110,
		Range = 10,
		Callback = function(enemy)
			local damage = self:GetService"DamageService":Damage{
				Source = self.Legend,
				Target = enemy,
				Amount = self:GetDamage(),
				Weapon = self,
				Type = "Slashing",
			}

			self:HitEffects(enemy)

			didAttack = true
		end
	})

	if didAttack then
		self.Attacked:Fire()
	end

	return true
end

function WeaponCrossbowAndShortsword:GetProjectileModel()
	return self.ProjectileModel
end

function WeaponCrossbowAndShortsword:Equip()
	local sword = self.Assets.Sword:Clone()
	sword.Parent = self.Legend.Model
	sword.Weld.Part0 = self.Legend.Model.RightHand
	self.Sword = sword
	
	local crossbow = self.Assets.Crossbow:Clone()
	crossbow.Parent = self.Legend.Model
	crossbow.Weld.Part0 = self.Legend.Model.RightHand
	self.Crossbow = crossbow
	
	local sheathedSword = self.Assets.SheathedSword:Clone()
	sheathedSword.Parent = self.Legend.Model
	sheathedSword.Weld.Part0 = self.Legend.Model.LowerTorso
	self.SheathedSword = sheathedSword
	
	local slungCrossbow = self.Assets.SlungCrossbow:Clone()
	slungCrossbow.Parent = self.Legend.Model
	slungCrossbow.Weld.Part0 = self.Legend.Model.UpperTorso
	self.SlungCrossbow = slungCrossbow
	
	self:SwitchModels("Ranged")
	
	self:FireRemote("AmmoUpdated", self.Legend.Player, {Type = "Show"})
end

function WeaponCrossbowAndShortsword:Unequip()
	self.Legend.WeaponCrossbowAndShortswordLoaded = self.Loaded
	
	self.Sword:Destroy()
	self.Crossbow:Destroy()
	self.SheathedSword:Destroy()
	self.SlungCrossbow:Destroy()
	
	self:FireRemote("AmmoUpdated", self.Legend.Player, {Type = "Hide"})
end

function WeaponCrossbowAndShortsword:Sheath()
	self:SwitchModels("None")
end

function WeaponCrossbowAndShortsword:Unsheath()
	-- do nothing, handled elsewhere
end

return WeaponCrossbowAndShortsword