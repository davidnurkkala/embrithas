return {
	Name = "A Fire Below",
	Description = "An experienced veteran slayer has gone missing in the caves beneath Rookie's Grave. Find out what happened to her.",
	Level = 60,
	PartySize = 6,
	
	MissionType = "Story Mission",
	MissionGroup = "CorruptedElemental",
	
	Requirements = {
		{Type = "Mission", Id = "rookiesGrave"},
	},
	
	MapPosition = Vector3.new(-32.928524, 5.19336414, -143.517456),
	
	Rewards = {
		{Type = "Weapon", Id = 1, Chance = 1/50},
		{Type = "Material", Id = 1, Chance = 1, Amount = 3},
		{Type = "Ability", Id = 4, Chance = 1/6},
		{Type = "Alignment", Faction = "League", Amount = 1, Reason = "you've started the search for a missing League slayer."},
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 8, Amount = 5},
	},
	
	Enemies = {
		["Orc"] = 10,
		["Orc Bulwark"] = 6,
		["Orc Archer"] = 6, 
		["Orc Brute"] = 3,
		["Orc Berserker"] = 3,
		["Orc Lieutenant"] = 1,
	},
	
	Floors = {
		[1] = {
			Name = "Crumbling Fort",
			Type = "Basic",
			Args = {
				TileSetName = "Castle",
				GridMap = {
					"##",
					"##",
				},
				StartRoomGridPosition = Vector2.new(1, 1),
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Jeonsa",
						Image = "rbxassetid://5617856098",
						Text = "Slayers, one of my best went missing down here. She wouldn't have died to the orcs we keep here. Something's going on. Find out what. Good luck!",
					}
				}
			},
		},
		[2] = {
			Name = "Dark Cavern",
			Type = "Granular",
			Args = {SizeInChunks = Vector2.new(2, 2), Theme = "Cave"},
		},
		[3] = {
			Name = "Deep Cavern",
			Type = "Granular",
			Args = {
				Theme = "Cave",
				ChunkMap = {
					">--V",
					"   ^",
				},
				StartRoomChunkPosition = Vector2.new(1, 1),
			},
			
			Enemies = {
				["Fiery Corruption"] = 1,
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Jeonsa",
						Image = "rbxassetid://5617856098",
						Text = "It's getting too hot. We're going to need to prepare better if we want to descend further. Finish exploring this level, then head back to the surface. We're not done here yet.",
					}
				}
			},
		},
	}
}