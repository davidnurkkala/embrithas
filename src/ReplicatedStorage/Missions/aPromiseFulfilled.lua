return {
	Name = "A Promise Fulfilled",
	Description = "Delve into the glacier and help Vladiv fulfill his promise. [This mission is optional.]",
	Level = 63,
	PartySize = 6,
	
	MissionType = "Story Mission",
	MissionGroup = "Undead",
	
	Requirements = {
		{Type = "Mission", Id = "aPromiseMade"},
	},
	
	MapPosition = Vector3.new(-38.9217148, 5.19336414, -145.419373),
	
	Rewards = {
		{Type = "Weapon", Id = 45, Chance = 1/3},
		{Type = "Ability", Id = 22, Chance = 1/6},
		{Type = "Material", Id = 8, Chance = 1, Amount = 2},
		{Type = "Material", Id = 4, Chance = 1, Amount = 3},
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 8, Amount = 10},
		{Type = "Material", Id = 4, Amount = 10},
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
			Name = "Glacier Interior",
			Type = "Granular",
			Args = {
				Theme = "Glacier",
				ChunkMap = {
					"V--<",
					">-<^",
					"^-^<",
				},
				StartRoomChunkPosition = Vector2.new(4, 2),
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Vladiv \"Ironsides\" Kyrsek",
						Image = "rbxassetid://5617839594",
						Text = "It's cold, here. Fitting. Slayers, we descend.",
					}
				}
			},
		},
		[2] = {
			Name = "Frozen Sanctum",
			Type = "Custom",
			Args = {DungeonId = "lostChampionBossDungeon"},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Vladiv \"Ironsides\" Kyrsek",
						Image = "rbxassetid://5617839594",
						Text = "Within this tomb, my old friend Yurov should rest peacefully. Instead, his body roams restlessly. Return him to his sleep, slayers. I promised.",
					}
				}
			},
		}
	}
}