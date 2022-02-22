return {
	Name = "Purified Jukumai Staff",
	Class = "WeaponStaffHealing",
	AssetsName = "PurifiedJukumaiStaff",
	Description = "A Jukumai necromancer's staff, utterly purged of all corruption. Now a tool for healing, not undeath.",
	Image = "rbxassetid://5754320597",
	UpgradeMaterials = {Steel = 0.1, Worldstone = 0.01},
	Rarity = "Mythic",
	Args = {
		DescriptionHeavy = function(self)
			return string.format("Use mana to fire a projectile that heals allies %d health and deals %d damage to enemies.", self:GetHealing(), self:GetHeavyDamage())
		end,
		
		GetHeavyDamage = function(self)
			return self:GetPowerHelper("Compassion") * 0.25
		end,
		
		CooldownHeavyTime = 2,
		AttackHeavyManaCost = 25,
		
		AttackHeavy = function(self)
			if not self.CooldownHeavy:IsReady() then return end
			
			local manaCost = self.AttackHeavyManaCost
			if not self.Legend:CanUseMana(manaCost) then return end
			
			self.Legend:UseMana(manaCost)
			
			self.CooldownHeavy:Use()
			self.CooldownLight:Use()
			
			self.Legend:SoundPlayByObject(self.Assets.Sounds.Cast)
			self.Legend:AnimationPlay("MagicCast", 0)
			
			self:CreateGenericProjectile{
				Model = self.Storage.Models.LightBolt,
				CFrame = self.Legend:GetAimCFrame(),
				Speed = 40,
				Width = 12,
				DeactivationType = "Wall",
				OnHitTarget = function(target)
					self:GetService("DamageService"):Damage{
						Source = self.Legend,
						Target = target,
						Amount = self:GetHeavyDamage(),
						Weapon = self,
						Type = "Disintegration",
						Tags = {"Magical"},
					}
				end,
				OnHitAlly = function(target)
					self:GetService("DamageService"):Heal{
						Source = self.Legend,
						Target = target,
						Amount = self:GetHealing() * 1.5,
					}
				end,
			}

			return true
		end,
	}
}