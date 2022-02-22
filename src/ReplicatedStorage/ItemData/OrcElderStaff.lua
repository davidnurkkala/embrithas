return {
	Name = "Orc Elder's Staff",
	Class = "WeaponStaff",
	AssetsName = "OrcElderStaff",
	Description = "The staff of an orc that was in touch with the elements around them. Attuned to magic in a strange but familiar way.",
	Image = "rbxassetid://5925020010",
	UpgradeMaterials = {Iskith = 0.1, MetallicCorruption = 0.01},
	Rarity = "Mythic",
	Perks = {
		"Whenever mana is expended to use an ability, earn charge based upon how much mana was expended. Charge drains over time, faster when charge is high.",
	},
	Args = {
		DescriptionHeavy = function(self)
			return string.format("Expend all charge and unleash a torrent of firebolts based upon how much charge was expended. Each deals at least %d damage, increasing for the total number of bolts in the torrent.", self:GetFireboltDamage())
		end,
		
		CooldownHeavyTime = 4,
		AttackHeavyChargeCost = 20,
		
		Equip = function(self)
			self:GetSuper().Equip(self)
			
			self.Charge = 0
			self:FireRemote("AimAmmoUpdated", self.Legend.Player, {Type = "Show"})
		end,
		
		Unequip = function(self)
			self:GetSuper().Unequip(self)
			
			self:FireRemote("AimAmmoUpdated", self.Legend.Player, {Type = "Hide"})
		end,
		
		GetFireboltDamage = function(self)
			return self:GetPowerHelper("Dominance") * 0.6
		end,
		
		AttackHeavy = function(self)
			if not self.CooldownHeavy:IsReady() then return end
			if self.Charge < self.AttackHeavyChargeCost then return end
			
			local count = math.floor(self.Charge / self.AttackHeavyChargeCost)
			self.Charge = 0
			
			local pause = 0.2
			
			local duration = pause * count
			self.CooldownHeavy:Use(duration)
			self.CooldownLight:Use(duration)
			
			local bonus = 1 + (count * 0.1)
			
			for step = 1, count do
				delay(pause * (step - 1), function()
					self.Legend:AnimationPlay("MagicCast")
					self.Legend:SoundPlay("FireCast")
					
					self:CreateGenericProjectile{
						Model = self.Storage.Models.FireBolt,
						CFrame = self.Legend:GetAimCFrame(),
						Speed = 64,
						Width = 4,
						OnHitTarget = function(target)
							self:GetService("DamageService"):Damage{
								Source = self.Legend,
								Target = target,
								Amount = self:GetFireboltDamage() * bonus,
								Weapon = self,
								Type = "Heat",
								Tags = {"Magical"},
							}
						end,
						OnEnded = function(projectile)
							self:GetService("EffectsService"):RequestEffectAll("Sound", {
								Position = projectile.CFrame.Position,
								Sound = self.Storage.Sounds.FireHit,
							})
						end
					}
				end)
			end

			return true
		end,
		
		OnUpdated = function(self, dt)
			local charges = self.Charge / self.AttackHeavyChargeCost
			local count = math.floor(charges)
			local leftover = charges - count
			
			local drainRate = self.Charge * 0.05
			self.Charge -= drainRate * dt
			
			self:FireRemote("AimAmmoUpdated", self.Legend.Player, {
				Type = "Update",
				Ammo = count,
				AimWord = "Firebolt Torrent",
				AmmoWord = "Charges",
				Ratio = leftover,
			})
		end,
		
		OnManaUsed = function(self, amount)
			self.Charge += amount
		end,
	}
}