return {
	Name = "Clawing at the Walls",
	Description = "The Abbey of the Chasm is under attack, threatening the lives of a visiting political delegation.",
	Level = 56,
	PartySize = 6,
	
	MissionType = "Story Mission",
	MissionGroup = "Undead",
	
	Requirements = {
		{Type = "Mission", Id = "aMurkySituation"},
	},
	
	MapPosition = Vector3.new(-36.1956902, 5.19336414, -147.548615),
	
	Rewards = {
		{Type = "Weapon", Id = 38, Chance = 1/3},
		{Type = "Material", Id = 10, Chance = 1, Amount = 3},
		{Type = "Alignment", Faction = "Order", Amount = 2, Reason = "you came to the aid of one of their Great Abbeys."},
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 10, Amount = 10},
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
	
	Floors = {
		[1] = {
			Name = "Marshy Outskirts",
			Type = "Granular",
			Args = {
				Theme = "Swamp",
				ChunkMap = {
					">--V",
					"^  |",
					"   |",
					"  >^",
				},
				StartRoomChunkPosition = Vector2.new(1, 2),
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Deacon Avery",
						Image = "rbxassetid://5651066105",
						Text = "Slayers! The Abbey of the Chasm is an Order holy site! We must reach it as soon as possible and purge these disgusting creatures.",
					}
				}
			},
		},
		[2] = {
			Name = "Abbey Walls",
			Type = "Basic",
			Args = {
				TileSetName = "Castle",
				GridMap = {
					">---<",
				},
				StartRoomGridPosition = Vector2.new(1, 1),
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Deacon Avery",
						Image = "rbxassetid://5651066105",
						Text = "Hurry to the keep, slayers. A group of diplomats from the Kingdom of Sketh is in danger, and if they're harmed, we'll be held responsible.",
					}
				}
			},
		},
		[3] = {
			Name = "Abbey Keep",
			Type = "Basic",
			Args = {
				TileSetName = "Castle",
				GridMap = {
					"##",
					"##",
				},
				StartRoomGridPosition = Vector2.new(2, 2),
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Deacon Avery",
						Image = "rbxassetid://5651066105",
						Text = "Goddess curse these abominations! We're too late. The visiting Sketh delegation... these monsters will pay for their lives. Take vengeance, slayers!",
					}
				}
			},
		}
	}
}