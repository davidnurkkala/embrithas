local Super = require(script.Parent)
local Ability = Super:Extend()

Ability.Type = "Offense"

Ability.Radius = 18
Ability.Range = 128
Ability.Speed = 96

function Ability:OnCreated()
	Super.OnCreated(self)
	
	self.Cooldown.Time = 5
end

function Ability:GetDamage()
	return self:GetPowerHelper("Agility")
end

function Ability:GetDescription()
	return string.format(
		"Requires a bow, crossbow, or musket.\n\nFire a projectile which explodes, dealing %d bludgeoning damage to all enemies struck.",
		self:GetDamage()
	)
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
		OnEnded = function(projectile)
			local here = projectile.CFrame.Position
			local radius = self.Radius
			
			self.Targeting:TargetCircle(self.Targeting:GetEnemies(), {
				Position = here,
				Range = radius,
				Callback = function(enemy)
					self:GetService("DamageService"):Damage({
						Source = self.Legend,
						Target = enemy,
						Amount = self:GetDamage(),
						Weapon = self,
						Type = "Bludgeoning",
						Tags = self.DamageTags,
					})

					weapon:HitEffects(enemy, false)
					
					if enemy:IsDead() then
						self:GetService("QuestService"):ProcessGameplayEvent(self.Legend.Player, {
							Type = "KillWithAbility",
							Id = self.Data.Id,
						})
					end
				end,
			})
			
			local effectsService = self:GetService("EffectsService")
			
			for _, durationColorPair in pairs{{0.25, Color3.new(1, 0, 0)}, {0.5, Color3.new(1, 0.5, 0)}, {0.75, Color3.new(1, 1, 0)}} do
				effectsService:RequestEffectAll("AirBlast", {
					Position = here,
					Radius = radius,
					Duration = durationColorPair[1],
					Color = durationColorPair[2],
					PartArgs = {
						Material = Enum.Material.Neon,
					}
				})
			end
			
			effectsService:RequestEffectAll("Sound", {
				Position = here,
				Sound = self.Storage.Sounds.ExplosionQuick,
			})
			
			effectsService:RequestEffectAll("Shockwave", {
				CFrame = CFrame.new(here),
				StartSize = Vector3.new(),
				EndSize = Vector3.new(radius * 2.5, 4, radius * 2.5),
				Duration = 0.25,
				PartArgs = {
					Color = Color3.new(1, 1, 1),
					Material = Enum.Material.Neon,
				}
			})
		end,
	}
	
	self.Legend.InCombatCooldown:Use()
	return true
end

return Ability