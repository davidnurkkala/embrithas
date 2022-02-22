return {
	Name = "Sudden Incursion",
	Description = "With its forces securing the border with Kakasta, the Jolian Empire requests Slayer aid in dealing with a sudden orc incursion outside New Grahst.",
	Level = 24,
	PartySize = 6,
	
	MissionType = "Story Mission",
	MissionGroup = "Orc",
	
	Requirements = {
		{Type = "Mission", Id = "tunnelingThreat"},
	},
	
	MapPosition = Vector3.new(-35.7601013, 5.19336414, -136.209686),
	
	Rewards = {
		{Type = "Weapon", Id = 21, Chance = 1/4},
		{Type = "Material", Id = 2, Chance = 1},
		{Type = "Material", Id = 2, Chance = 1/2},
		{Type = "Trinket", Id = 8, Chance = 1/10},
		{Type = "Alignment", Faction = "League", Amount = -1, Reason = "the League would rather not involve itself in such a political defense."}
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 1, Amount = 5},
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
		["Orc Berserker"] = 1,
	},
	
	Floors = {
		[1] = {
			Name = "Killing Fields",
			Type = "Granular",
			Args = {
				Theme = "Forest",
				ChunkMap = {
					"###",
					"###",
				},
				StartRoomChunkPosition = Vector2.new(2, 1),
			},
			
			Encounters = {
				{Type = "Multi", Encounters = {
					{Type = "Elite", Enemy = "Orc Bulwark"},
					{Type = "Elite", Enemy = "Orc Archer"},
					{Type = "Elite", Enemy = "Orc"},
				}}
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "We have teams mopping up the orcs in the surrounding area. We've confirmed this is where they're surfacing -- find their tunnels and let's turn this fight around!",
					}
				}
			},
		},
		[2] = {
			Name = "Fresh-carved Tunnels",
			Type = "Basic",
			Args = {
				TileSetName = "Mineshaft",
				GridMap = {
					">V ",
					" | ",
					" ^<",
				},
				StartRoomGridPosition = Vector2.new(3, 3),
			},
		},
		[3] = {
			Name = "Orc Forward Command Base",
			Type = "Custom",
			Args = {DungeonId = "doubleOrcBossDungeon"},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "Whatever orc is in charge of this incursion is behind that door. End this, slayers!",
					}
				}
			},
		}
	}
}