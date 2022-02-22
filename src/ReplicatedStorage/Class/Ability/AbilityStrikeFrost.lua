local Super = require(script.Parent)
local AbilityStrikeFrost = Super:Extend()

AbilityStrikeFrost.Type = "Offense"

AbilityStrikeFrost.UsesMana = true
AbilityStrikeFrost.ManaCost = 25
AbilityStrikeFrost.Range = 64

function AbilityStrikeFrost:OnCreated()
	Super.OnCreated(self)
	
	self.Cooldown.Time = 1
end

function AbilityStrikeFrost:GetDamage()
	local multiplier = self:Lerp(1, 2, self:GetUpgrades() / 10)
	local damage = self:GetPowerHelper("Dominance") * multiplier
	local boltCount = self:GetBoltCount()
	local damagePerBolt = damage / boltCount
	return damagePerBolt
end

function AbilityStrikeFrost:GetBoltCount()
	return math.floor(self:Lerp(2, 4, self:GetUpgrades() / 10))
end

function AbilityStrikeFrost:GetDescription()
	return string.format(
		"Hurl %d icicles at nearby enemies, dealing %d damage to each. Costs %d mana.",
		self:GetBoltCount(),
		self:GetDamage(),
		self.ManaCost
	)
end

function AbilityStrikeFrost:OnActivatedServer()
	local manaCost = self.ManaCost

	if not self.Legend:CanUseMana(manaCost) then return false end
	self.Legend:UseMana(manaCost)

	self.Legend:AnimationPlay("MagicCast", 0)
	
	local boltCount = self:GetBoltCount()
	
	for boltNumber = 1, boltCount do
		delay(boltNumber * 0.1, function()
			self.Legend:SoundPlayByObject(self.Storage.Sounds.IceCast)

			self:GetClass("Projectile").CreateGenericProjectile{
				Model = self.Storage.Models.FrostStrikeProjectile,
				CFrame = self.Legend:GetAimCFrame(),
				Speed = 64,
				Width = 4,
				Range = 128,
				OnHitTarget = function(target)
					self:GetService("DamageService"):Damage{
						Source = self.Legend,
						Target = target,
						Amount = self:GetDamage(),
						Weapon = self,
						Type = "Piercing",
						Tags = {"Magical"},
					}
				end,
				OnEnded = function(projectile)
					self:GetService("EffectsService"):RequestEffectAll("Sound", {
						Position = projectile.CFrame.Position,
						Sound = self.Storage.Sounds.IceShatter2,
					})
				end
			}
		end)
	end

	self.Legend.InCombatCooldown:Use()

	return true
end

return AbilityStrikeFrost