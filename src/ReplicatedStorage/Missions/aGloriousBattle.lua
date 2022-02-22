return {
	Name = "A Glorious Battle",
	Description = "Avenge a fallen League of Valor comrade.",
	Level = 45,
	PartySize = 6,
	
	MissionType = "Story Mission",
	MissionGroup = "OneOffs",
	
	Requirements = {
		{Type = "Alignment", Faction = "League", Amount = 15},
	},
	
	MapPosition = Vector3.new(-30.2501259, 5.19336414, -134.064087),
	
	Rewards = {
		{Type = "Ability", Id = 13, Chance = 1},
		{Type = "Material", Id = 8, Chance = 1, Amount = 2},
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 8, Amount = 25},
	},
	
	Enemies = {
		["Skeleton"] = 1,
	},
	
	Floors = {
		[1] = {
			Name = "Decrepit Mine",
			Type = "Basic",
			Args = {
				TileSetName = "Mineshaft",
				GridMap = {
					">---<",
				},
				StartRoomGridPosition = Vector2.new(1, 1),
			},
			
			Encounters = {
				{Type = "Mob", Enemy = "Skeleton", Count = 30, GridPosition = Vector2.new(3, 1)},
				{Type = "Multi", GridPosition = Vector2.new(5, 1), Encounters = {
					{Type = "Elite", Enemy = "Osseous Aberration"},
					{Type = "Elite", Enemy = "Osseous Aberration"},
				}}
			},
			
			Events = {
				OnStarted = {
					OnStarted = {
						Dialogue = {
							Name = "Jeonsa",
							Image = "rbxassetid://5617856098",
							Text = "Slayer, we recently lost a good friend clearing out this pocket of undead. Avenge them!",
						}
					}
				},
				OnFinished = {
					Dialogue = {
						Name = "Jeonsa",
						Image = "rbxassetid://5617856098",
						Text = "Outstanding work, slayer. Nayhen will rest easy knowing the job's been done. Let's head home and raise a cup in his honor and yours!",
					},
					Pause = 5,
				}
			},
		},
	}
}