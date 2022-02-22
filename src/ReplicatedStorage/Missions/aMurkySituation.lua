return {
	Name = "A Murky Situation",
	Description = "We've received an uncharacteristic call for help from the Jolians in an unexpected place -- Elt. What are they doing there?",
	Level = 48,
	PartySize = 6,
	
	MissionType = "Story Mission",
	MissionGroup = "Undead",
	
	Requirements = {
		{Type = "Mission", Id = "chillOfDeath"},
	},
	
	MapPosition = Vector3.new(-36.6659737, 5.19336414, -148.331284),
	
	Rewards = {
		{Type = "Weapon", Id = 37, Chance = 1/4},
		{Type = "Trinket", Id = 10, Chance = 1/10},
		{Type = "Material", Id = 2, Chance = 1, Amount = 4},
		{Type = "Alignment", Faction = "College", Amount = 1, Reason = "discovering new undead locations is important in divining the pattern of their appearances."},
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 1, Amount = 10},
		{Type = "Material", Id = 12, Amount = 10},
	},
	
	Enemies = {
		["Skeleton"] = 7,
		["Skeleton Warrior"] = 4,
		["Bone Archer"] = 4,
		["Zombie"] = 1,
		["Skeleton Berserker"] = 1,
		["Ghost"] = 1,
	},
	
	Floors = {
		[1] = {
			Name = "Fetid Marsh",
			Type = "Granular",
			Args = {
				Theme = "Swamp",
				ChunkMap = {
					"V< ",
					"|^ ",
					">-<",
				},
				StartRoomChunkPosition = Vector2.new(2, 2),
			},
			
			Encounters = {
				{Type = "Lore", LoreId = "onElt"},
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Colonel Achre",
						Image = "rbxassetid://5625183248",
						Text = "Slayers, thank the Goddess you're here. We came to this swamp to -- well, nevermind. The undead emerged from the muck and are everywhere. Help us!",
					}
				}
			},
		},
		[2] = {
			Name = "Secluded Island",
			Type = "Granular",
			Args = {SizeInChunks = Vector2.new(2, 1), Theme = "Swamp"},
			
			Encounters = {
				{Type = "Multi", Encounters = {
					{Type = "Elite", Enemy = "Zombie Defender"},
					{Type = "Mob", Enemy = "Zombie", Count = 12, LevelDelta = -10}
				}}
			}
		},
		[3] = {
			Name = "Gaseous Swamps",
			Type = "Granular",
			Args = {
				Theme = "Swamp",
				ChunkMap = {
					"V< ",
					"|#<",
					"^< ",
				},
				StartRoomChunkPosition = Vector2.new(3, 2),
			},
			
			Enemies = {
				["Skeleton"] = 7,
				["Skeleton Warrior"] = 4,
				["Bone Archer"] = 4,
				["Zombie"] = 1,
				["Zombie Defender"] = 1,
				["Skeleton Berserker"] = 1,
				["Ghost"] = 1,
			},
			
			FloorItemSets = {
				Gas = {
					TrapGas = {8, 12},
				}
			},
			FloorItemSetWeights = {
				None = 1,
				Gas = 1,
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Colonel Achre",
						Image = "rbxassetid://5625183248",
						Text = "Er, sorry about the gas vents. That's our fault. Why? Uh... That's not important. Regardless, you've dealt with this outbreak very efficiently! Makes me wonder why we're under orders not to ask for your help.",
					}
				}
			},
		}
	}
}