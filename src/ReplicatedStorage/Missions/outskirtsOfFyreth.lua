return {
	Name = "Outskirts of Fyreth",
	Description = "Vladiv wants to begin a bold campaign to capture the ruins of Fyreth, once a major Lorithasi port city. Help him claim a staging area for the siege.",
	Level = 35,
	PartySize = 6,
	
	MissionType = "Story Mission",
	MissionGroup = "Shadow",
	
	MapPosition = Vector3.new(-33.0482559, 5.19336414, -142.316483),
	
	Requirements = {
		{Type = "Mission", Id = "pushingForward"},
	},
	
	Rewards = {
		{Type = "Weapon", Id = 26, Chance = 1/5},
		{Type = "Material", Id = 2, Chance = 1, Amount = 2},
		{Type = "Material", Id = 10, Chance = 1, Amount = 2},
		{Type = "Alignment", Faction = "League", Amount = 1, Reason = "it will be glorious to take the fight to the enemy for a change!"},
		{Type = "Alignment", Faction = "College", Amount = 1, Reason = "Fyreth could hold many secrets."},
		{Type = "Alignment", Faction = "Order", Amount = 1, Reason = "every inch of Lorithas that falls to the Alliance is a victory for the Distant Goddess!"},
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 2, Amount = 10},
		{Type = "Material", Id = 10, Amount = 5},
	},
	
	Enemies = {
		["Armored Shadow"] = 2,
		["Shadow Assassin"] = 2,
		["Mystic Shadow"] = 2,
		["Raging Shadow"] = 1,
		["Shadow Warrior"] = 1,
	},
	
	Floors = {
		[1] = {
			Name = "Outskirts Approach",
			Type = "Granular",
			Args = {
				Theme = "Forest",
				ChunkMap = {
					"V  ",
					"|><",
					">^ ",
				},
				StartRoomChunkPosition = Vector2.new(1, 1),
			},
			
			Encounters = {
				{Type = "Lore", LoreId = "aTheoryOnShadows", ChunkPosition = Vector2.new(2, 2)},
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Vladiv \"Ironsides\" Kyrsek",
						Image = "rbxassetid://5617839594",
						Text = "We're deep in enemy territory, slayers. Time to claim a staging area so we can begin the siege. Onward to glory!",
					}
				}
			},
		},
		[2] = {
			Name = "Southeastern Watchtower F1",
			Type = "Basic",
			Args = {
				TileSetName = "Castle",
				GridMap = {
					"VV",
					"><",
				},
				StartRoomGridPosition = Vector2.new(1, 1),
			},
		},
		[3] = {
			Name = "Southeastern Watchtower F2",
			Type = "Basic",
			Args = {
				TileSetName = "Castle",
				GridMap = {
					"VV",
					"><",
				},
				StartRoomGridPosition = Vector2.new(2, 1),
			},
			
			Encounters = {
				{Type = "Elite", GridPosition = Vector2.new(1, 1), Enemy = "Raging Shadow", LevelDelta = 10},
			},
		},
		[4] = {
			Name = "Southeastern Watchtower B1",
			Type = "Basic",
			Args = {
				TileSetName = "Mineshaft",
				GridMap = {
					">-<",
					"  ^",
				},
				StartRoomGridPosition = Vector2.new(3, 2),
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Vladiv \"Ironsides\" Kyrsek",
						Image = "rbxassetid://5617839594",
						Text = "We've got sappers ready to fill in the tunnels around here. Pave the way for them and we've claimed our base camp! Huzzah!",
					}
				}
			},
		}
	}
}