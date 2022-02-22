return {
	Name = "Recruit Training",
	Description = "Every great Slayer -- even the legendary Heroes -- started right here. You will, too.",
	Level = 0,
	PartySize = 1,
	
	MissionType = "Tutorial",
	MissionGroup = "Tutorial",
	
	StartingLifeCount = 99,
	
	MapPosition = Vector3.new(-33.6617775, 5.19336414, -144.795425),
	
	FirstTimeRewards = {
		{Type = "Material", Id = 1, Amount = 12},
		{Type = "Material", Id = 6, Amount = 12},
	},
	
	Floors = {
		[1] = {
			Name = "The Course",
			Type = "Tutorial",
			Args = {},
		},
	},
}