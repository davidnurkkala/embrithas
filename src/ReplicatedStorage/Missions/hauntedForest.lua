return {
	Name = "Haunted Forest",
	Description = "A stony glen in the forests of Iskis has been overrun by undead.",
	Level = 12,
	PartySize = 6,
	
	MissionType = "Story Mission",
	MissionGroup = "Undead",
	
	Requirements = {
		{Type = "Mission", Id = "aGraveIssue"},
	},
	
	MapPosition = Vector3.new(-30.6323528, 5.19336414, -133.620148),
	
	Rewards = {
		{Type = "Weapon", Id = 13, Chance = 1/2},
		{Type = "Trinket", Id = 4, Chance = 1/4},
		{Type = "Material", Id = 6, Chance = 1},
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 6, Amount = 10},
	},
	
	Enemies = {
		["Skeleton"] = 7,
		["Skeleton Warrior"] = 4,
		["Bone Archer"] = 4,
		["Zombie"] = 1,
		["Skeleton Berserker"] = 1,
	},
	
	Floors = {
		[1] = {
			Name = "Fetid Glen",
			Type = "Granular",
			Args = {
				Theme = "Forest",
				ChunkMap = {
					">V",
					">^",
					"^ ",
				},
				StartRoomChunkPosition = Vector2.new(1, 3),
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "All right, slayers. Our purpose here is twofold: clear out the undead, and see if we can find a connection between this outbreak and the last.",
					}
				}
			},
		},
		[2] = {
			Name = "Rotten Gully",
			Type = "Granular",
			Args = {SizeInChunks = Vector2.new(1, 5), Theme = "Forest", StartRoomChunkPosition = Vector2.new(1, 5)},
			
			Encounters = {
				{Type = "Lore", LoreId = "iskisASummary"},
			},
		},
		[3] = {
			Name = "Darkened Clearing",
			Type = "Granular",
			Args = {
				Theme = "Forest",
				ChunkMap = {
					" V ",
					"V< ",
					">-<",
				},
				StartRoomChunkPosition = Vector2.new(2, 1),
			},
			
			Encounters = {
				{Type = "Mob", Enemy = "Bone Archer", Count = 12, Level = 1, ChunkPosition = Vector2.new(2, 2)},
			},
			
			Events = {
				OnFinished = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "We've just received word about a much more dangerous undead in the area. Let's move out.",
					},
					Pause = 5,
				}
			},
		},
	}
}