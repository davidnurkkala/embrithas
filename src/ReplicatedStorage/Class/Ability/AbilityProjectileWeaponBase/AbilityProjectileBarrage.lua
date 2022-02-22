local Super = require(script.Parent)
local Ability = Super:Extend()

Ability.Type = "Offense"

Ability.ProjectileCount = 30
Ability.Duration = 4
Ability.Range = 128
Ability.Speed = 96

function Ability:OnCreated()
	Super.OnCreated(self)
	
	self.Cooldown.Time = 90
end

function Ability:GetDamage()
	return self:GetPowerHelper("Agility") * 0.75
end

function Ability:GetDescription()
	return string.format(
		"Requires a bow, crossbow, or musket.\n\nChannel for up to %d seconds, firing up to %d projectiles in quick succession, each dealing %d piercing damage to the first target hit.",
		self.Duration,
		self.ProjectileCount,
		self:GetDamage()
	)
end

function Ability:OnActivatedServer()
	local weapon = self.Legend.Weapon
	
	if not self:IsProjectileWeapon(weapon) then return end
	
	local duration = self.Duration
	local projectileCount = self.ProjectileCount
	local interval = duration / projectileCount
	
	spawn(function()
		self.Legend:Channel(duration, "Projectile Barrage", "Normal", {
			Interval = interval,
			CustomOnTicked = function(t, dt)
				if self.Legend.Weapon ~= weapon then
					return t:Fail()
				end
				
				weapon:ShootAnimation()
				weapon:ShootSound()
				weapon:RangedWeaponSlow()

				self:GetClass("Projectile").CreateGenericProjectile{
					Model = weapon:GetProjectileModel(),
					CFrame = self.Legend:GetAimCFrame(),
					Speed = self.Speed,
					Width = 4,
					Range = self.Range,
					OnHitTarget = function(enemy)
						self:GetService("DamageService"):Damage({
							Source = self.Legend,
							Target = enemy,
							Amount = self:GetDamage(),
							Weapon = self,
							Type = "Piercing",
							DamageTags = weapon.DamageTags,
						})

						weapon:HitEffects(enemy, false)
						enemy:SoundPlayByObject(weapon:GetProjectileHitSound())
					end,
				}
			end,
		})
	end)
	
	self.Legend.InCombatCooldown:Use()
	return true
end

return Ability