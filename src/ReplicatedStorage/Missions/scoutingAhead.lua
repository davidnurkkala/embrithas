return {
	Name = "Scouting Ahead",
	Description = "Much to the displeasure of local tribal leaders, the Kakastan city council has finally allowed slayers into Kakastan territory to search for orcs.",
	Level = 28,
	PartySize = 6,
	
	MissionType = "Story Mission",
	MissionGroup = "Orc",
	
	Requirements = {
		{Type = "Mission", Id = "suddenIncursion"},
	},
	
	MapPosition = Vector3.new(-34.5203476, 5.19336414, -138.549194),
	
	Rewards = {
		{Type = "Weapon", Id = 24, Chance = 1/2},
		{Type = "Material", Id = 6, Chance = 1, Amount = 2},
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 6, Amount = 5},
	},
	
	Enemies = {
		["Orc Miner"] = 3,
		["Orc Sapper"] = 1,
		["Orc Archer"] = 1,
		["Orc Bulwark"] = 2,
		["Orc"] = 3,
		["Orc Brute"] = 1,
		["Orc Shaman"] = 1,
	},
	
	Floors = {
		[1] = {
			Name = "Nest Perimeter",
			Type = "Granular",
			Args = {
				Theme = "Forest",
				ChunkMap = {
					">-V",
					"  |",
					">-^",
				},
				StartRoomChunkPosition = Vector2.new(1, 3),
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "There are orcs everywhere! Why haven't the Kakastans contacted us before? Get to work, Slayers!",
					}
				}
			},
		},
		[2] = {
			Name = "Orc Nest",
			Type = "Basic",
			Args = {
				TileSetName = "Mineshaft",
				GridMap = {
					">-V",
					" V<",
					" ^ ",
				},
				StartRoomGridPosition = Vector2.new(1, 1),
			},
			
			Encounters = {
				{Type = "Multi", GridPosition = Vector2.new(2, 3), Encounters = {
					{Type = "Elite", Enemy = "Orc Bulwark"},
					{Type = "Elite", Enemy = "Orc Miner"},
					{Type = "Elite", Enemy = "Orc Archer"},
				}}
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "Clear out this nest and report back. Our scouts are reporting no devastation in the surrounding area... something is going on.",
					}
				}
			},
		},
	}
}