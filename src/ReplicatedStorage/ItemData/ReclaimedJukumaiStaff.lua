return {
	Name = "Reclaimed Jukumai Staff",
	Class = "WeaponStaff",
	AssetsName = "ReclaimedJukumaiStaff",
	Description = "The reclaimed staff of a Jukumai necromancer with an affinity for the chill of death.",
	Image = "rbxassetid://5733087280",
	UpgradeMaterials = {MetallicCorruption = 0.1, Worldstone = 0.01},
	Rarity = "Mythic",
	Perks = {
		"Combat Teleport costs no mana.",
	},
	Args = {
		DescriptionHeavy = function(self)
			return string.format("Use mana to cast a small blast of icicles towards the targeted location. Each deals %d damage.", self:GetIcicleDamage())
		end,
		
		GetIcicleDamage = function(self)
			return self:GetPowerHelper("Dominance") * 0.4
		end,
		
		CooldownHeavyTime = 1,
		AttackHeavyManaCost = 20,
		
		AttackHeavy = function(self)
			if not self.CooldownHeavy:IsReady() then return end
			
			local manaCost = self.AttackHeavyManaCost
			if not self.Legend:CanUseMana(manaCost) then return end
			
			self.Legend:UseMana(manaCost)
		
			self.CooldownHeavy:Use()
			self.CooldownLight:Use()
			
			-- effects
			self.Legend:SoundPlay("IceCast")
			self.Legend:AnimationPlay("MagicCast", 0)
			
			-- shoot projectiles
			local angle = math.rad(45)
			local count = 5
			for step = 0, count - 1 do
				local theta = (-angle / 2) + (angle / count) * (step + 0.5)
				local cframe = self.Legend:GetAimCFrame() * CFrame.Angles(0, theta, 0)
				
				self:CreateGenericProjectile{
					Model = self.Storage.Models.FrostStrikeProjectile,
					CFrame = cframe,
					Speed = 48,
					Width = 4,
					OnHitTarget = function(target)
						self:GetService("DamageService"):Damage{
							Source = self.Legend,
							Target = target,
							Amount = self:GetIcicleDamage(),
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
			end

			return true
		end
	}
}