return {
	Name = "Chill of Death",
	Description = "The Evrig have reported undead rising in their glacial home.",
	Level = 31,
	PartySize = 6,
	
	MissionType = "Story Mission",
	MissionGroup = "Undead",
	
	Requirements = {
		{Type = "Mission", Id = "brokenBones"},
	},
	
	MapPosition = Vector3.new(-37.5370789, 5.19336414, -145.887924),
	
	Rewards = {
		{Type = "Weapon", Id = 31, Chance = 1/4},
		{Type = "Material", Id = 4, Chance = 1/4},
		{Type = "Material", Id = 6, Chance = 1, Amount = 2},
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 4, Amount = 5},
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
			Name = "Frozen Waste",
			Type = "Granular",
			Args = {
				Theme = "Snow",
				ChunkMap = {
					">---V",
					"    ^",
				},
				StartRoomChunkPosition = Vector2.new(1, 1),
			},
			
			Encounters = {
				{Type = "Elite", Enemy = "Ghost", ChunkPosition = Vector2.new(2, 1)},
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "Brr... t-try not to f-freeze out here, s-slayers. Hunt down the undead and show them no mercy!",
					}
				}
			},
		},
		[2] = {
			Name = "Chilled Cavern",
			Type = "Granular",
			Args = {
				Theme = "Cave",
				ChunkMap = {
					">V",
					" |",
					">^",
				},
				StartRoomChunkPosition = Vector2.new(1, 3),
			},
		},
		[3] = {
			Name = "Glacial Graveyard",
			Type = "Granular",
			Args = {
				Theme = "Snow",
				ChunkMap = {
					" V ",
					">^<",
				},
				StartRoomChunkPosition = Vector2.new(2, 1),
			},
			
			Encounters = {
				{Type = "Multi", ChunkPosition = Vector2.new(2, 2), Encounters = {
					{Type = "Elite", Enemy = "Skeleton Warrior"},
					{Type = "Elite", Enemy = "Skeleton Warrior"},
					{Type = "Elite", Enemy = "Skeleton Warrior"},
					{Type = "Mob", Enemy = "Bone Archer", Count = 6},
				}}
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "C-clear out this glacier and let's r-regroup at base to c-consider our next options.",
					}
				}
			},
		}
	}
}