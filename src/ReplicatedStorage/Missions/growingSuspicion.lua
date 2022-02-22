return {
	Name = "Growing Suspicion",
	Description = "Despite the indignant locals' harassment, scouts have discovered a suspicious compound infested with orcs.",
	Level = 42,
	PartySize = 6,
	
	MissionType = "Story Mission",
	MissionGroup = "Orc",
	
	Requirements = {
		{Type = "Mission", Id = "scoutingAhead"},
	},
	
	MapPosition = Vector3.new(-35.091835, 5.19336414, -139.079865),
	
	Rewards = {
		{Type = "Weapon", Id = 25, Chance = 1/3},
		{Type = "Material", Id = 8, Chance = 1/2},
		{Type = "Material", Id = 10, Chance = 1/2},
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 8, Amount = 3},
		{Type = "Material", Id = 1, Amount = 3},
		{Type = "Material", Id = 6, Amount = 3},
	},
	
	Enemies = {
		["Orc Miner"] = 3,
		["Orc Sapper"] = 1,
		["Orc Archer"] = 1,
		["Orc Bulwark"] = 2,
		["Orc"] = 3,
		["Orc Shaman"] = 2,
	},
	
	Floors = {
		[1] = {
			Name = "Compound Outskirts",
			Type = "Granular",
			Args = {
				Theme = "Forest",
				ChunkMap = {
					" V  ",
					">-V ",
					"  ^<",
				},
				StartRoomChunkPosition = Vector2.new(4, 3),
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "Our scouts reported a strangely unransacked compound in this area. Let's clear the area and follow up.",
					}
				}
			},
		},
		[2] = {
			Name = "Natural Tunnels",
			Type = "Granular",
			Args = {SizeInChunks = Vector2.new(4,1), Theme = "Cave", StartRoomChunkPosition = Vector2.new(1, 1)},
		},
		[3] = {
			Name = "Facility Entrance",
			Type = "Granular",
			Args = {
				Theme = "Lab",
				ChunkMap = {
					"  V ",
					">--<",
				},
				StartRoomChunkPosition = Vector2.new(3, 1),
			},
			
			Encounters = {
				{Type = "Multi", ChunkPosition = Vector2.new(1, 2), Encounters = {
					{Type = "Elite", Enemy = "Orc Bulwark"},
					{Type = "Elite", Enemy = "Orc Bulwark"},
					{Type = "Elite", Enemy = "Orc Bulwark"},
					{Type = "Mob", Enemy = "Orc Shaman", Count = 6},
				}}
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "What is this place? Orcs aren't smart enough to make this... establish a foothold and report back. We need a plan before delving deeper.",
					}
				}
			},
		}
	}
}