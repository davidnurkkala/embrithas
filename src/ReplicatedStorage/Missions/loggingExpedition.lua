return {
	Type = "RunLoggingExpedition",
	
	Name = "Logging Expedition",
	Description = "The Iskith are more than happy to sell lumber rights, but we'll have to clear out the undead first so our lumberjacks can work safely.",
	Level = 30,
	PartySize = 6,
	
	MissionType = "Expedition",
	MissionGroup = "MaterialExpeditions",
	
	Requirements = {
		{Type = "Mission", Id = "hauntedForest"},
	},
	
	MapPosition = Vector3.new(-31.0637436, 5.19336414, -134.146561),
	
	Rewards = {},
	
	Cost = {
		Gold = 2500,
	},
	
	Floors = {
		[1] = {
			Name = "Uncharted Forest",
			Type = "Granular",
			Args = {SizeInChunks = Vector2.new(2, 2), Theme = "Forest"},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Slayer Alliance Woodcutter",
						Image = "rbxassetid://5651417472",
						Text = "Slayers, we're here for smaller, younger trees. If you find one, touch it to mark it and I'll come chop it down. Watch out for the undead!",
					}
				}
			}
		},
	}
}