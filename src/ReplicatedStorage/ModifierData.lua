local modifierData = {
	Sharp = {
		Name = "Sharp",
		Description = "Slightly increases damage.",
		Rarity = 8,
		
		TypeExclusions = {
			"Maul",
			"Staff",
		},
	},
	
	Heavy = {
		Name = "Heavy",
		Description = "Slightly increases damage.",
		Rarity = 8,
		
		TypeInclusions = {
			"Maul",
			"Staff",
		}
	},
	
	Sturdy = {
		Name = "Sturdy",
		Description = "Increases shield block or adds an additional parry.",
		Rarity = 16,
		
		TypeInclusions = {
			"SwordAndShield",
			"AxeAndBuckler",
		}
	},
	
	Loaded = {
		Name = "Loaded",
		Description = "Increases ranged attack speed or decreases reload time.",
		Rarity = 16,
		
		TypeInclusions = {
			"CrossbowAndShortsword",
			"BowAndDagger",
			"Musket",
		}
	},
	
	Mystic = {
		Name = "Mystic",
		Description = "Restores mana with each attack.",
		Rarity = 32,
		
		IdExclusions = {
			52, -- Mana Bow
		},
		TypeExclusions = {
			"Staff",
		}
	},
	
	Agile = {
		Name = "Agile",
		Description = "Increases Agility.",
		Rarity = 64,
	},
	
	Fierce = {
		Name = "Fierce",
		Description = "Increases Strength.",
		Rarity = 64,
	},
	
	Willful = {
		Name = "Willful",
		Description = "Increases Dominance.",
		Rarity = 64,
	},
	
	Empathetic = {
		Name = "Empathetic",
		Description = "Increases Compassion.",
		Rarity = 64,
	},
	
	Vital = {
		Name = "Vital",
		Description = "Increases Constitution.",
		Rarity = 64,
	},
	
	Spiritual = {
		Name = "Spiritual",
		Description = "Increases Perseverance.",
		Rarity = 64,
	},
	
	Enraging = {
		Name = "Enraging",
		Description = "Increases rage or adrenaline gain.",
		Rarity = 64,
		
		TypeInclusions = {
			"Greatsword",
			"Claws",
		}
	},
	
	Efficient = {
		Name = "Efficient",
		Description = "Reduces the resource cost of a weapon, typically mana.",
		Rarity = 64,
		
		IdInclusions = {
			52, -- Mana Bow
		},
		TypeInclusions = {
			"StaffLightning",
		}
	},
	
	Magnum = {
		Name = "Magnum",
		Description = "Increases gun damage dramatically.",
		Rarity = 96,
		
		TypeInclusions = {
			"Musket",
			"SaberAndPistol",
		}
	},
	
	Ethereal = {
		Name = "Ethereal",
		Description = "Pass through enemies as if you were a ghost.",
		Rarity = 96,
	},
	
	-- lmaginationBurst was here
	Vampiric = {
		Name = "Vampiric",
		Description = "Heals you for a portion of damage dealt.",
		Rarity = 128,
	},
	
	Perfected = {
		Name = "Perfected",
		Description = "Attacks grant increasing damage as long as you don't get hit.",
		Rarity = 128,
	},
}

return modifierData