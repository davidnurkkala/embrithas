local Super = require(script.Parent)
local AbilityStrikeFire = Super:Extend()

AbilityStrikeFire.Type = "Offense"

AbilityStrikeFire.UsesMana = true
AbilityStrikeFire.ManaCost = 30
AbilityStrikeFire.Range = 64

function AbilityStrikeFire:OnCreated()
	Super.OnCreated(self)
	
	self.Cooldown.Time = 1
end

function AbilityStrikeFire:GetDamage()
	local dps = self:GetPowerHelper("Dominance") * 0.4
	return dps * self:GetDuration()
end

function AbilityStrikeFire:GetDuration()
	return self:Lerp(3, 6, self:GetUpgrades() / 10)
end

function AbilityStrikeFire:GetDescription()
	return string.format(
		"Hurl a bolt of fire at the nearest enemy, setting them ablaze to deal %d damage over %d seconds. Costs %d mana.",
		self:GetDamage(),
		self:GetDuration(),
		self.ManaCost
	)
end

function AbilityStrikeFire:OnActivatedServer()
	local manaCost = self.ManaCost

	if not self.Legend:CanUseMana(manaCost) then return false end
	self.Legend:UseMana(manaCost)

	self.Legend:AnimationPlay("MagicCast", 0)

	delay(0.1, function()
		self.Legend:SoundPlayByObject(self.Storage.Sounds.FireCast)

		self:GetClass("Projectile").CreateGenericProjectile{
			Model = self.Storage.Models.FireBolt,
			CFrame = self.Legend:GetAimCFrame(),
			Speed = 96,
			Width = 4,
			Range = 128,
			OnHitTarget = function(target)
				target:AddStatus("StatusBurning", {
					Time = self:GetDuration(),
					Damage = self:GetDamage(),
					Source = self.Legend,
					Weapon = self,
					Tags = {"Magical"},
				})
			end,
			OnEnded = function(projectile)
				self:GetService("EffectsService"):RequestEffectAll("Sound", {
					Position = projectile.CFrame.Position,
					Sound = self.Storage.Sounds.FireHit,
				})
			end
		}
	end)

	self.Legend.InCombatCooldown:Use()

	return true
end

return AbilityStrikeFire