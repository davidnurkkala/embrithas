local Super = require(script.Parent)
local Ability = Super:Extend()

Ability.Type = "Offense"

Ability.Range = 96
Ability.Radius = 12
Ability.Duration = 5

function Ability:OnCreated()
	Super.OnCreated(self)
	
	self.Cooldown.Time = 12
end

function Ability:GetDamage()
	return self:GetPowerHelper("Agility")
end

function Ability:GetDescription()
	return string.format(
		"Requires a bow, crossbow, or musket.\n\nUnleash a hail of projectiles on the targeted area, dealing %d piercing damage per second to enemies in the area for %d seconds.",
		self:GetDamage(),
		self.Duration
	)
end

function Ability:OnActivatedServer()
	local weapon = self.Legend.Weapon
	
	if not self:IsProjectileWeapon(weapon) then return end
	
	local position = self.Targeting:GetClampedAimPosition(self.Legend, self.Range)
	position = self.Legend:GetFootPosition(position)
	
	weapon:ShootHighAnimation()
	weapon:ShootSound()
	weapon:RangedWeaponSlow()
	
	self:GetService("EffectsService"):RequestEffectAll("RainOfProjectiles", {
		Position = position,
		Duration = self.Duration,
		Radius = self.Radius,
		ProjectileModel = weapon:GetProjectileModel(),
		StartPosition = self.Legend:GetPosition(),
	})
	
	local interval = 0.5
	
	self:CreateNew"Timeline"{
		Time = self.Duration,
		Interval = interval,
		OnTicked = function(t, dt)
			local enemiesHit = {}
			
			self.Targeting:TargetCircle(self.Targeting:GetEnemies(), {
				Position = position,
				Range = self.Radius,
				Callback = function(enemy)
					table.insert(enemiesHit, enemy)
				end,
			})
			
			local count = #enemiesHit
			for index, enemy in pairs(enemiesHit) do
				local ratio = (index - 1) / count
				delay(interval * ratio, function()
					self:GetService("DamageService"):Damage{
						Source = self.Legend,
						Target = enemy,
						Amount = self:GetDamage() * dt,
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
				end)
			end
		end,
	}:Start()
	
	self.Legend.InCombatCooldown:Use()
	return true
end

return Ability