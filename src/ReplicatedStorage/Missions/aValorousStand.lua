return {
	Name = "A Valorous Stand",
	Description = "Partake in a typical League of Valor hazing ritual.",
	Level = 18,
	PartySize = 6,
	
	MissionType = "Story Mission",
	MissionGroup = "OneOffs",
	
	Requirements = {
		{Type = "Alignment", Faction = "League", Amount = 5},
	},
	
	MapPosition = Vector3.new(-32.928524, 5.19336414, -143.517456),
	
	Rewards = {
		{Type = "Ability", Id = 12, Chance = 1},
		{Type = "Material", Id = 2, Chance = 1, Amount = 2},
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 1, Amount = 25},
	},
	
	Enemies = {
		["Orc"] = 1,
		["Orc Bulwark"] = 1,
		["Orc Archer"] = 1,
		["Orc Brute"] = 1,
		["Orc Berserker"] = 1,
	},
	
	Floors = {
		[1] = {
			Name = "Crumbling Fort Abandoned Wing",
			Type = "Basic",
			Args = {
				TileSetName = "Castle",
				GridMap = {
					">-V",
					"V-^",
					">-<",
				},
				StartRoomGridPosition = Vector2.new(1, 1),
			},
			
			Encounters = {
				{Type = "Elite", Enemy = "Orc Lieutenant", GridPosition = Vector2.new(3, 1)},
				{Type = "Multi", GridPosition = Vector2.new(1, 2), Encounters = {
					{Type = "Elite", Enemy = "Orc Lieutenant"},
					{Type = "Elite", Enemy = "Orc Lieutenant"},
				}},
				{Type = "Multi", GridPosition = Vector2.new(3, 3), Encounters = {
					{Type = "Elite", Enemy = "Orc Lieutenant"},
					{Type = "Elite", Enemy = "Orc Lieutenant"},
					{Type = "Elite", Enemy = "Orc Lieutenant"},
				}}
			},
			
			Events = {
				OnStarted = {
					OnStarted = {
						Dialogue = {
							Name = "Jeonsa",
							Image = "rbxassetid://5617856098",
							Text = "All right, slayer. We've got the Valorous Stand all set up. Good luck!",
						}
					}
				},
				OnFinished = {
					Dialogue = {
						Name = "Jeonsa",
						Image = "rbxassetid://5617856098",
						Text = "That was glorious, slayer! Well done.",
					},
					Pause = 5,
				}
			},
		},
	}
}