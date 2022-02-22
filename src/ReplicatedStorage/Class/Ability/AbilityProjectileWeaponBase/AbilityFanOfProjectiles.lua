local Super = require(script.Parent)
local Ability = Super:Extend()

Ability.Type = "Offense"

Ability.ProjectileCount = 7
Ability.Angle = math.pi / 6
Ability.Range = 128
Ability.Speed = 96
Ability.Falloff = 0.2

function Ability:OnCreated()
	Super.OnCreated(self)
	
	self.Cooldown.Time = 6
end

function Ability:GetDamage()
	return self:GetPowerHelper("Agility")
end

function Ability:GetDescription()
	return string.format(
		"Requires a bow, crossbow, or musket.\n\nFire %d projectiles in a fan, each dealing %d piercing damage. Projectiles that hit a target that's already been hit deal %d%% damage.",
		self.ProjectileCount,
		self:GetDamage(),
		self.Falloff * 100
	)
end

function Ability:OnActivatedServer()
	local weapon = self.Legend.Weapon
	
	if not self:IsProjectileWeapon(weapon) then return end
	
	weapon:ShootAnimation()
	weapon:ShootSound()
	weapon:RangedWeaponSlow()
	
	local start = -self.Angle / 2
	local step = self.Angle / self.ProjectileCount
	local aimCFrame = self.Legend:GetAimCFrame()
	
	local victims = {}
	
	for projectileNumber = 0, self.ProjectileCount - 1 do
		local theta = start + step * projectileNumber
		local cframe = aimCFrame * CFrame.Angles(0, theta, 0)
		
		self:GetClass("Projectile").CreateGenericProjectile{
			Model = weapon:GetProjectileModel(),
			CFrame = cframe,
			Speed = self.Speed,
			Width = 4,
			Range = self.Range,
			OnHitTarget = function(target)
				local damage = self:GetDamage()
				if table.find(victims, target) then
					damage *= 0.2
				end
				
				self:GetService("DamageService"):Damage({
					Source = self.Legend,
					Target = target,
					Amount = self:GetDamage(),
					Weapon = self,
					Type = "Piercing",
					Tags = weapon.DamageTags,
				})
				weapon:HitEffects(target, false)
				target:SoundPlayByObject(weapon:GetProjectileHitSound())
				
				table.insert(victims, target)
				
				if target:IsDead() then
					self:GetService("QuestService"):ProcessGameplayEvent(self.Legend.Player, {
						Type = "KillWithAbility",
						Id = self.Data.Id,
					})
				end
			end,
		}
	end
	
	self.Legend.InCombatCooldown:Use()
	return true
end

return Ability