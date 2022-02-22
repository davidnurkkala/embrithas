return {
	[1] = {
		Name = "Amulet of Purity",
		Image = "rbxassetid://5910223918",
		Description = "Often worn by members of the Order of Purifiers. Increases Constitution.",
		UpgradeMaterials = {Gold = 0.01, Gemstones = 0.01},

		Args = {
			GetDescription = function(self)
				return string.format("%s\n\n+%d Constitution", self.Data.Description, self:GetBuffAmount())
			end,

			GetBuffAmount = function(self)
				return self:Lerp(5, 50, self.Upgrades / 10)
			end,

			Equip = function(self)
				self.BuffAmount = self:GetBuffAmount()

				self.Legend.Constitution.Flat += self.BuffAmount
			end,
			Unequip = function(self)
				self.Legend.Constitution.Flat -= self.BuffAmount
			end,
		},
	},
	[2] = {
		Name = "Amulet of Magic",
		Image = "rbxassetid://5910224018",
		Description = "Often worn by members of the College of Reclamation. Increases Perseverance.",
		UpgradeMaterials = {Gold = 0.01, Gemstones = 0.01},
		
		Args = {
			GetDescription = function(self)
				return string.format("%s\n\n+%d Perseverance", self.Data.Description, self:GetBuffAmount())
			end,
			
			GetBuffAmount = function(self)
				return self:Lerp(5, 50, self.Upgrades / 10)
			end,
			
			Equip = function(self)
				self.BuffAmount = self:GetBuffAmount()
				
				self.Legend.Perseverance.Flat += self.BuffAmount
			end,
			Unequip = function(self)
				self.Legend.Perseverance.Flat -= self.BuffAmount
			end
		},
	},
	[3] = {
		Name = "Amulet of Valor",
		Image = "rbxassetid://5910223836",
		Description = "Often worn by members of the League of Valor. Increases Agility.",
		UpgradeMaterials = {Gold = 0.01, Gemstones = 0.01},
		
		Args = {
			GetDescription = function(self)
				return string.format("%s\n\n+%d Agility", self.Data.Description, self:GetBuffAmount())
			end,
			
			GetBuffAmount = function(self)
				return self:Lerp(5, 50, self.Upgrades / 10)
			end,

			Equip = function(self)
				self.BuffAmount = self:GetBuffAmount()

				self.Legend.Agility.Flat += self.BuffAmount
			end,
			Unequip = function(self)
				self.Legend.Agility.Flat -= self.BuffAmount
			end
		},
	},
	[4] = {
		Name = "Gilded Branch",
		Image = "rbxassetid://5910646016",
		Description = "A curious creation of the Druids of Iskis that connects one more closely with the power of all living things. Increases Compassion.",
		UpgradeMaterials = {Gold = 0.01, Iskith = 0.01},
		
		Args = {
			GetDescription = function(self)
				return string.format("%s\n\n+%d Compassion", self.Data.Description, self:GetBuffAmount())
			end,
			
			GetBuffAmount = function(self)
				return self:Lerp(5, 50, self.Upgrades / 10)
			end,

			Equip = function(self)
				self.BuffAmount = self:GetBuffAmount()

				self.Legend.Compassion.Flat += self.BuffAmount
			end,
			Unequip = function(self)
				self.Legend.Compassion.Flat -= self.BuffAmount
			end
		}
	},
	[5] = {
		Name = "Iron Armor",
		Image = "rbxassetid://5910930876",
		Description = "Heavy armor which slows the user down but dramatically increases survivability.",
		UpgradeMaterials = {Iron = 0.1},
		
		Args = {
			GetDescription = function(self)
				return string.format("%s\n\nBlocks %d%% of damage\n-%d movement speed", self.Data.Description, self:GetBuffAmount() * 100, self:GetSlowAmount())
			end,
			
			GetSlowAmount = function(self)
				return 1
			end,
			GetBuffAmount = function(self)
				return self:Lerp(0.02, 0.15, self.Upgrades / 10)
			end,

			Equip = function(self)
				self.BuffAmount = self:GetBuffAmount()
				self.SlowAmount = self:GetSlowAmount()

				self.Legend.Armor.Flat += self.BuffAmount
				self.Legend.Speed.Flat -= self.SlowAmount
			end,
			Unequip = function(self)
				self.Legend.Armor.Flat -= self.BuffAmount
				self.Legend.Speed.Flat += self.SlowAmount
			end
		}
	},
	[6] = {
		Name = "Whetstone",
		Image = "rbxassetid://5910985796",
		Description = "Keeps your weapons sharp. Slightly increases damage.",

		Args = {
			GetDescription = function(self)
				return string.format("%s\n\n+%d%% damage", self.Data.Description, self:GetBuffAmount() * 100)
			end,

			GetBuffAmount = function(self)
				return 0.05
			end,

			Equip = function(self)
				self.BuffAmount = self:GetBuffAmount()

				self.Legend.Power.Flat += self.BuffAmount
			end,
			Unequip = function(self)
				self.Legend.Power.Flat -= self.BuffAmount
			end
		}
	},
	[7] = {
		Name = "NOTHING",
		Image = "",
		Description = "Does nothing.",

		Args = {
			GetDescription = function(self)
				return "Does nothing."
			end,
		}
	},
	[8] = {
		Name = "Orc Totem",
		Image = "rbxassetid://7096266994",
		Description = "A magical device that orcs wear to amplify their physical strength. Easily appropriated by slayers and can be improved with metallic corruption, but the Order generally disapproves of this. Increases Strength.",
		UpgradeMaterials = {MetallicCorruption = 0.01, Gemstones = 0.01},

		Args = {
			GetDescription = function(self)
				return string.format("%s\n\n+%d Strength", self.Data.Description, self:GetBuffAmount())
			end,

			GetBuffAmount = function(self)
				return self:Lerp(5, 50, self.Upgrades / 10)
			end,

			Equip = function(self)
				self.BuffAmount = self:GetBuffAmount()

				self.Legend.Strength.Flat += self.BuffAmount
			end,
			Unequip = function(self)
				self.Legend.Strength.Flat -= self.BuffAmount
			end,
		},
	},
	[9] = {
		Name = "Psychic Amplifier",
		Image = "rbxassetid://7096266994",
		Description = "A common Hestinian device that helps one concentrate. Not known to have lasting side effects, though it's worth noting that the most common affliction in Hestingrav is the headache. Increases Dominance.",
		UpgradeMaterials = {Worldstone = 0.01, Gemstones = 0.01},

		Args = {
			GetDescription = function(self)
				return string.format("%s\n\n+%d Dominance", self.Data.Description, self:GetBuffAmount())
			end,

			GetBuffAmount = function(self)
				return self:Lerp(5, 50, self.Upgrades / 10)
			end,

			Equip = function(self)
				self.BuffAmount = self:GetBuffAmount()

				self.Legend.Dominance.Flat += self.BuffAmount
			end,
			Unequip = function(self)
				self.Legend.Dominance.Flat -= self.BuffAmount
			end,
		},
	},
	[10] = {
		Name = "Embriguard Token",
		Image = "rbxassetid://7096266994",
		Description = "A magical talisman given to veterans of the Embriguard. Increases your attack speed while in Phalanx Stance.",
		
		Args = {
			WeaponSpearPhalanxStanceFactorBonus = 0.08,
		}
	}
}