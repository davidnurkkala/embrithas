local Super = require(script.Parent)
local Weapon = Super:Extend()

Weapon.DisplayName = "Wand"

Weapon.DescriptionLight = function(self)
	return string.format("Shoot a mana projectile. Costs %d mana.", self.ManaCostLight)
end

Weapon.DescriptionHeavy = function(self)
	return string.format("Shoot a large mana projectile that explodes. If this explosion kills an enemy, start your mana regeneration. Costs %d mana.", self.ManaCostHeavy)
end

Weapon.PrimaryStatName = "Dominance"

Weapon.ManaCostLight = 5
Weapon.ManaCostHeavy = 20

Weapon.CooldownLightTime = 0.35
Weapon.CooldownHeavyTime = 3

Weapon.ProjectileModel = Weapon.Storage.Models.ManaDartProjectile
Weapon.ProjectileSpeed = 96
Weapon.ProjectileRange = 96

Weapon.HeavyRadius = 14
Weapon.HeavyColor = Color3.fromRGB(0, 170, 255)

Weapon.ProjectileModelHeavy = Weapon.Storage.Models.ManaDartProjectileLarge
Weapon.ProjectileSpeedHeavy = 48
Weapon.ProjectileRangeHeavy = 96

function Weapon:OnCreated()
	Super.OnCreated(self)
	
	self.AttackNumber = 0
end

function Weapon:GetDamage()
	return Super.GetDamage(self) * 1.2
end

function Weapon:GetLightDamage(enemy)
	return self:GetDamage()
end

function Weapon:GetHeavyDamage(enemy)
	return self:GetDamage() * 2
end

function Weapon:AttackLight()
	if not self.CooldownLight:IsReady() then return end
	self.CooldownLight:Use()
	self.CooldownHeavy:UseMinimum(self.CooldownLight.Time)
	
	self:AttackSound()
	self.Legend:AnimationPlay("WandAttackLight"..self.AttackNumber, 0)
	self.AttackNumber = (self.AttackNumber + 1) % 2
	
	if not self.Legend:CanUseMana(self.ManaCostLight) then return end
	self.Legend:UseMana(self.ManaCostLight)
	
	self.Legend:SoundPlayByObject(self.Assets.Sounds.Shot)
	
	self:GetClass("Projectile").CreateGenericProjectile{
		Model = self.ProjectileModel,
		CFrame = self.Legend:GetAimCFrame(),
		Speed = self.ProjectileSpeed,
		Width = 4,
		Range = self.ProjectileRange,
		OnHitTarget = function(enemy)
			self:GetService("DamageService"):Damage{
				Source = self.Legend,
				Target = enemy,
				Amount = self:GetLightDamage(enemy),
				Weapon = self,
				Type = "Piercing",
				Tags = {"Magical"},
			}
			
			if self.OnLightHit then
				self:OnLightHit(enemy)
			end
			
			self.Attacked:Fire()
		end,
	}
	
	self:RangedWeaponSlow()

	return true
end

function Weapon:AttackHeavy()
	if not self.CooldownHeavy:IsReady() then return end
	self.CooldownHeavy:Use()
	self.CooldownLight:Use()
	
	self:AttackSound()
	self.Legend:AnimationPlay("WandAttackHeavy", 0)
	
	if not self.Legend:CanUseMana(self.ManaCostHeavy) then return end
	self.Legend:UseMana(self.ManaCostHeavy)

	self.Legend:SoundPlayByObject(self.Assets.Sounds.Shot)

	self:GetClass("Projectile").CreateGenericProjectile{
		Model = self.ProjectileModelHeavy,
		CFrame = self.Legend:GetAimCFrame(),
		Speed = self.ProjectileSpeedHeavy,
		Width = 4,
		Range = self.ProjectileRangeHeavy,
		OnEnded = function(projectile)
			local here = projectile.CFrame.Position
			local radius = self.HeavyRadius
			
			local didAttack = false

			self.Targeting:TargetCircle(self.Targeting:GetEnemies(), {
				Position = here,
				Range = radius,
				Callback = function(enemy)
					self:GetService("DamageService"):Damage({
						Source = self.Legend,
						Target = enemy,
						Amount = self:GetHeavyDamage(enemy),
						Weapon = self,
						Type = "Bludgeoning",
						Tags = {"Magical"},
					})
					
					if self.OnHeavyHit then
						self:OnHeavyHit(enemy)
					end
					
					if enemy:IsDead() then
						self.Legend.ManaRegenCooldown:Use(0)
					end
					
					didAttack = true
				end,
			})
			
			if didAttack then
				self.Attacked:Fire()
			end

			local effectsService = self:GetService("EffectsService")
			local color = self.HeavyColor

			effectsService:RequestEffectAll("AirBlast", {
				Position = here,
				Radius = radius,
				Duration = 0.25,
				Color = color,
				PartArgs = {
					Material = Enum.Material.Neon,
				}
			})

			effectsService:RequestEffectAll("Sound", {
				Position = here,
				Sound = self.Assets.Sounds.Explosion,
			})

			effectsService:RequestEffectAll("Shockwave", {
				CFrame = CFrame.new(here),
				StartSize = Vector3.new(),
				EndSize = Vector3.new(radius * 2.5, 4, radius * 2.5),
				Duration = 0.25,
				PartArgs = {
					Color = color,
					Material = Enum.Material.Neon,
				}
			})
		end,
	}
	
	self:RangedWeaponSlow()
	
	return true
end

function Weapon:ClearParts()
	self:ClearPartsHelper(self.Wand)
end

function Weapon:AddParts()
	local wand = self.Assets.Wand:Clone()
	wand.Parent = self.Legend.Model
	wand.Weld.Part0 = self.Legend.Model.RightHand
	wand.Weld.Part1 = wand
	self.Wand = wand
end

function Weapon:Equip()
	self:Unsheath()
end

function Weapon:Unequip()
	self:ClearParts()
end

function Weapon:Sheath()
	self:ClearParts()
	self:AddParts()
	
	self:RebaseWeld(self.Wand.Weld, self.Legend.Model.LowerTorso,
		CFrame.new(-1, 0, 0),
		CFrame.Angles(-math.pi * 3 / 4, 0, 0)
	)
	
	self.Legend:SetRunAnimation("NoWeapons")
end

function Weapon:Unsheath()
	self:ClearParts()
	self:AddParts()

	self.Legend:SetRunAnimation("SingleWeapon")
end

return Weapon