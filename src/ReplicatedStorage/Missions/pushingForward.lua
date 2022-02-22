return {
	Name = "Pushing Forward",
	Description = "The assault by the shadows forced the abandonment of a forward position at Fort Ryonos. The slayers want to take it back.",
	Level = 25,
	PartySize = 6,
	
	MissionType = "Story Mission",
	MissionGroup = "Shadow",
	
	MapPosition = Vector3.new(-32.0692062, 5.19336414, -143.537445),
	
	Requirements = {
		{Type = "Mission", Id = "homefrontDefense"},
	},
	
	Rewards = {
		{Type = "Ability", Id = 3, Chance = 1/4},
		{Type = "Material", Id = 10, Chance = 1/2, Amount = 3},
		{Type = "Alignment", Faction = "League", Amount = 1, Reason = "little is more gallant than charging headlong into enemy territory!"},
		{Type = "Alignment", Faction = "College", Amount = -1, Reason = "they believe that the shadows could have been captured in this fortification and studied."},
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 10, Amount = 5},
	},
	
	Enemies = {
		["Armored Shadow"] = 1,
		["Shadow Assassin"] = 1,
		["Mystic Shadow"] = 1,
	},
	
	Floors = {
		[1] = {
			Name = "Trench Run",
			Type = "Granular",
			Args = {
				Theme = "Forest",
				ChunkMap = {
					"V<V< ",
					"^^<^<",
				},
				StartRoomChunkPosition = Vector2.new(5, 2),
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Vladiv \"Ironsides\" Kyrsek",
						Image = "rbxassetid://5617839594",
						Text = "All right slayers, this is our best approach to the position. We won't get pelted with ranged attacks from here. Chaaarge!",
					}
				}
			},
		},
		[2] = {
			Name = "Fort Periphery",
			Type = "Basic",
			Args = {
				TileSetName = "Castle",
				GridMap = {
					">< ",
					"^^<",
				},
				StartRoomGridPosition = Vector2.new(3, 2),
			},
		},
		[3] = {
			Name = "Fort Keep",
			Type = "Basic",
			Args = {
				TileSetName = "Castle",
				GridMap = {
					"><",
				},
				StartRoomGridPosition = Vector2.new(2, 1),
			},
			
			Encounters = {
				{Type = "Elite", Enemy = "Armored Shadow", LevelDelta = 10},
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Vladiv \"Ironsides\" Kyrsek",
						Image = "rbxassetid://5617839594",
						Text = "This is it -- the keep. Our mages are detecting a somewhat powerful presence inside. Be ready for anything, slayers.",
					}
				}
			},
		}
	}
}