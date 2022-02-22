return {
	Name = "A Promise Made",
	Description = "Vladiv has an old promise to keep, and he needs help keeping it. [This mission is optional.]",
	Level = 39,
	PartySize = 6,
	
	MissionType = "Story Mission",
	MissionGroup = "Undead",
	
	Requirements = {
		{Type = "Mission", Id = "chillOfDeath"},
	},
	
	MapPosition = Vector3.new(-38.9217148, 5.19336414, -145.419373),
	
	Rewards = {
		{Type = "Weapon", Id = 43, Chance = 1/3},
		{Type = "Material", Id = 8, Chance = 1, Amount = 2},
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 8, Amount = 10},
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
			Name = "Northward Path",
			Type = "Granular",
			Args = {
				Theme = "Snow",
				ChunkMap = {
					">V",
					"V<",
					"><",
				},
				StartRoomChunkPosition = Vector2.new(2, 3),
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Vladiv \"Ironsides\" Kyrsek",
						Image = "rbxassetid://5617839594",
						Text = "I wish we were returning to my homeland on a better errand, slayers, but... an old friend needs our help.",
					}
				}
			},
		},
		[2] = {
			Name = "Frosted Plateau",
			Type = "Granular",
			Args = {
				Theme = "Snow",
				ChunkMap = {
					">-<",
					"V-^",
					"^  ",
				},
				StartRoomChunkPosition = Vector2.new(1, 3),
			},
		},
		[3] = {
			Name = "Glacial Passage",
			Type = "Granular",
			Args = {
				Theme = "Glacier",
				ChunkMap = {
					"V--V",
					"^  ^",
				},
				StartRoomChunkPosition = Vector2.new(1, 2),
			},
			
			Events = {
				OnFinished = {
					Dialogue = {
						Name = "Vladiv \"Ironsides\" Kyrsek",
						Image = "rbxassetid://5617839594",
						Text = "Our mission lies within this glacier. Make camp. We'll finish this when we're ready.",
					},
					Pause = 5,
				}
			},
		},
	}
}