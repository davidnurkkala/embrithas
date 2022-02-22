local Super = require(script.Parent)
local AbilityStrikeEarth = Super:Extend()

AbilityStrikeEarth.Type = "Offense"

AbilityStrikeEarth.UsesMana = true
AbilityStrikeEarth.ManaCost = 30
AbilityStrikeEarth.Range = 64

function AbilityStrikeEarth:OnCreated()
	Super.OnCreated(self)
	
	self.Cooldown.Time = 1
end

function AbilityStrikeEarth:GetDamage()
	return self:GetPowerHelper("Dominance") * 0.6
end

function AbilityStrikeEarth:GetRadius()
	return self:Lerp(6, 12, self:GetUpgrades() / 10)
end

function AbilityStrikeEarth:GetDescription(level, itemData)
	return string.format(
		"Hurl a stone at the nearest enemy which shatters, dealing %d damage, stunning, and interrupting enemies within %4.1f range. Costs %d mana.",
		self:GetDamage(),
		self:GetRadius(),
		self.ManaCost
	)
end

function AbilityStrikeEarth:OnActivatedServer()
	local manaCost = self.ManaCost

	if not self.Legend:CanUseMana(manaCost) then return false end
	self.Legend:UseMana(manaCost)

	self.Legend:AnimationPlay("MagicCast", 0)

	delay(0.1, function()
		self.Legend:SoundPlayByObject(self.Storage.Sounds.Throw2)

		self:GetClass("Projectile").CreateGenericProjectile{
			Model = self.Storage.Models.EarthStrikeProjectile,
			CFrame = self.Legend:GetAimCFrame(),
			Speed = 96,
			Width = 4,
			Range = 128,
			OnEnded = function(projectile)
				local here = projectile.CFrame.Position
				local radius = self:GetRadius()

				local effectsService = self:GetService("EffectsService")
				effectsService:RequestEffectAll("Sound", {
					Sound = self.Storage.Sounds.RockImpact1,
					Position = here,
				})
				effectsService:RequestEffectAll("AirBlast", {
					Position = here,
					Color = Color3.fromRGB(108, 88, 75),
					Radius = radius,
					Duration = 0.5,
				})
				
				local targeting = self:GetService("TargetingService")
				targeting:TargetCircle(targeting:GetEnemies(), {
					Position = here,
					Range = radius,
					Callback = function(target)
						if not target.Resilient then
							target:AddStatus("StatusStunned", {
								Time = 1,
							})
						end

						self:GetService("DamageService"):Damage{
							Source = self.Legend,
							Target = target,
							Amount = self:GetDamage(),
							Weapon = self,
							Type = "Bludgeoning",
							Tags = {"Magical"},
						}
					end
				})
			end
		}
	end)

	self.Legend.InCombatCooldown:Use()

	return true
end

return AbilityStrikeEarth