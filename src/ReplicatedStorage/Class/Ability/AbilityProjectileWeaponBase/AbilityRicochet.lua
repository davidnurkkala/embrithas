local Super = require(script.Parent)
local Ability = Super:Extend()

Ability.Type = "Offense"

Ability.BounceCount = 6
Ability.BounceRange = 28
Ability.BounceRangeSq = Ability.BounceRange ^ 2
Ability.Range = 64
Ability.Speed = 96

function Ability:OnCreated()
	Super.OnCreated(self)
	
	self.Cooldown.Time = 6
end

function Ability:GetDamage()
	return self:GetPowerHelper("Agility")
end

function Ability:GetDescription()
	return string.format(
		"Requires a bow, crossbow, or musket.\n\nFire a projectile that will ricochet off of up to %d enemies, dealing %d piercing damage to each.",
		self.BounceCount,
		self:GetDamage()
	)
end

function Ability:HitTarget(enemy, bounceNumber, victims, weapon)
	self:GetService("DamageService"):Damage{
		Source = self.Legend,
		Target = enemy,
		Amount = self:GetDamage(),
		Weapon = self,
		Type = "Piercing",
		Tags = weapon.DamageTags,
	}
	weapon:HitEffects(enemy, false)
	enemy:SoundPlayByObject(weapon:GetProjectileHitSound())
	
	if enemy:IsDead() then
		self:GetService("QuestService"):ProcessGameplayEvent(self.Legend.Player, {
			Type = "KillWithAbility",
			Id = self.Data.Id,
		})
	end
	
	if bounceNumber >= self.BounceCount then return end
	
	table.insert(victims, enemy)
	
	local here = enemy:GetPosition()
	local targetDistancePairs = {}
	
	self.Targeting:TargetCircle(self.Targeting:GetEnemies(), {
		Position = here,
		Range = self.BounceRange,
		Callback = function(target, data)
			if target == enemy then return end
			
			local distance = data.DistanceSq
			if table.find(victims, target) then
				distance += self.BounceRangeSq
			end
			
			local pair = {
				Target = target,
				DistanceSq = distance,
			}
			table.insert(targetDistancePairs, pair)
		end,
	})
	
	if #targetDistancePairs == 0 then return end
	
	table.sort(targetDistancePairs, function(a, b)
		return a.DistanceSq < b.DistanceSq
	end)
	
	local newTarget = targetDistancePairs[1].Target
	local there = newTarget:GetPosition()
	local distance = (there - here).Magnitude
	local duration = distance / self.Speed
	
	self:GetService("EffectsService"):RequestEffectAll("Ricochet", {
		Position = here,
		Target = newTarget.Root,
		Duration = duration,
		ProjectileModel = weapon:GetProjectileModel(),
	})
	
	delay(duration, function()
		if not newTarget.Active then return end
		
		self:HitTarget(newTarget, bounceNumber + 1, victims, weapon)
	end)
end

function Ability:OnActivatedServer()
	local weapon = self.Legend.Weapon
	
	if not self:IsProjectileWeapon(weapon) then return end
	
	weapon:ShootAnimation()
	weapon:ShootSound()
	weapon:RangedWeaponSlow()
	
	self:GetClass("Projectile").CreateGenericProjectile{
		Model = weapon:GetProjectileModel(),
		CFrame = self.Legend:GetAimCFrame(),
		Speed = self.Speed,
		Width = 4,
		Range = self.Range,
		OnHitTarget = function(target)
			self:HitTarget(target, 1, {}, weapon)
		end,
	}
	
	self.Legend.InCombatCooldown:Use()
	return true
end

return Ability