-- Kensai666 was here

local Super = require(script.Parent)
local WeaponMusket = Super:Extend()

WeaponMusket.PrimaryStatName = "Agility"

WeaponMusket.Range = 10
WeaponMusket.RangedRange = 60
WeaponMusket.DisplayName = "Musket"
WeaponMusket.DescriptionLight = "Stab enemies with bayonet."
WeaponMusket.DescriptionHeavy = "Shoot a piercing bullet."

WeaponMusket.CooldownLightTime = 1
WeaponMusket.ReloadTime = 2
WeaponMusket.CooldownHeavyTime = 1
WeaponMusket.RangedDamageMultiplier = 3

function WeaponMusket:OnCreated()
	Super.OnCreated(self)
	
	if self.Legend.WeaponMusketLoaded then
		self.Loaded = self.Legend.WeaponMusketLoaded
	else
		self.Loaded = false
	end
end

function WeaponMusket:AttackLight()
	if not self.CooldownLight:IsReady() then return end
	
	if self.Loaded then
		self:Shoot()
	else
		self:Reload()
	end
end

function WeaponMusket:Reload()
	local speed = 1
	if self:HasModifier("Loaded") then
		speed = 1.5
	end
	
	self.CooldownLight:Use(self.ReloadTime / speed)
	self.CooldownHeavy:Use()

	self.Legend:AnimationPlay("MusketReload", nil, nil, speed)
	local sound = self.Legend:SoundPlayByObject(self.Assets.Sounds.Reload)
	sound.PlaybackSpeed = speed

	self:RangedWeaponSlow()
	self.Loaded = true
end

function WeaponMusket:Shoot()
	self.CooldownLight:Use()
	self.CooldownHeavy:Use()

	local length = 64
	local width = 4

	local cframe = self.Legend:GetAimCFrame() * CFrame.new(0, 0, -length / 2)

	self:ShootAnimation()

	self:GetService("EffectsService"):RequestEffectAll("Pierce", {
		CFrame = cframe,
		Tilt = 8,
		Length = length,
		Width = 1,
		Duration = 0.1,
	})

	local damageBonus = self.RangedDamageMultiplier
	if self:HasModifier("Magnum") then
		damageBonus *= 4/3
	end

	local didAttack = false

	local targets = self:GetService("TargetingService"):GetEnemies()
	self.Targeting:TargetSquare(self.Targeting:GetEnemies(), {
		CFrame = cframe,
		Length = length,
		Width = width,
		Callback = function(enemy)
			self:GetService"DamageService":Damage{
				Source = self.Legend,
				Target = enemy,
				Amount = self:GetDamage() * damageBonus,
				Weapon = self,
				Type = "Piercing",
			}

			self:HitEffects(enemy, false)

			didAttack = true
			
			if enemy:IsDead() then
				self:GetService("QuestService"):ProcessGameplayEvent(self.Legend.Player, {Type = "KillWithProjectile"})
			end
		end
	})

	self:RangedWeaponSlow()

	self:ShootSound()

	if didAttack then
		self.Attacked:Fire()
	end
	
	self.Loaded = false

	return true
end

function WeaponMusket:GetProjectileHitSound()
	local sounds = self.Assets.Sounds.ProjectileHit:GetChildren()
	return sounds[math.random(1, #sounds)]
end

function WeaponMusket:ShootSound()
	self.Legend:SoundPlayByObject(self:Choose(self.Assets.Sounds.Shot:GetChildren()))
end

function WeaponMusket:ShootAnimation()
	self.Legend:AnimationPlay("MusketAttackLight", 0)
end

function WeaponMusket:ShootHighAnimation()
	self.Legend:AnimationPlay("MusketShootHigh", 0)
end

function WeaponMusket:AttackHeavy()
	if not self.CooldownHeavy:IsReady() then return end

	self.CooldownHeavy:Use()
	self.CooldownLight:Use()

	self:AttackSound()
	self.Legend:AnimationPlay("MusketAttackHeavy", 0)

	local length = 14
	local width = 6
	local cframe = self.Legend:GetAimCFrame() * CFrame.new(0, 0, -length / 2)

	self:GetService("EffectsService"):RequestEffectAll("Pierce", {
		CFrame = cframe,
		Tilt = 4,
		Length = length,
		Width = width - 2,
		Duration = 0.1,
	})

	local didAttack = false

	self.Targeting:TargetSquare(self.Targeting:GetEnemies(), {
		CFrame = cframe,
		Length = length,
		Width = width,
		Callback = function(enemy)
			self:GetService"DamageService":Damage{
				Source = self.Legend,
				Target = enemy,
				Amount = self:GetDamage(),
				Weapon = self,
				Type = "Piercing",
			}

			self:HitEffects(enemy)

			didAttack = true
		end,
	})

	if didAttack then
		self.Attacked:Fire()
	end

	return true
end

function WeaponMusket:GetProjectileModel()
	return self.Storage.Models.Bullet
end

function WeaponMusket:AddParts()
	local musket = self.Assets.Musket:Clone()
	musket.Parent = self.Legend.Model
	musket.Motor.Part0 = self.Legend.Model.RightHand
	musket.Motor.Part1 = musket
	self.Musket = musket
end

function WeaponMusket:ClearParts()
	self:ClearPartsHelper(self.Musket)
end

function WeaponMusket:Equip()
	self:Unsheath()
end

function WeaponMusket:Unequip()
	self.Legend.WeaponMusketLoaded = self.Loaded
	
	self:ClearParts()
end

function WeaponMusket:Sheath()
	self:ClearParts()
	self:AddParts()
	
	self:RebaseWeld(self.Musket.Motor, self.Legend.Model.UpperTorso,
		CFrame.new(0, 0, 1),
		CFrame.Angles(0, 0, math.pi / 4),
		CFrame.Angles(0, math.pi / 2, 0)
	)
	
	self.Legend:SetRunAnimation("NoWeapons")
end

function WeaponMusket:Unsheath()
	self:ClearParts()
	self:AddParts()
	
	self.Legend:SetRunAnimation("SingleWeapon")
end

return WeaponMusket