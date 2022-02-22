return {
	Name = "Lessons in the Arcane I",
	Description = "Learn the ways of magic at the Academy of the City of Peace.",
	Level = 15,
	PartySize = 6,
	
	MissionType = "Story Mission",
	MissionGroup = "LessonsInTheArcane",
	
	Requirements = {},
	
	MapPosition = Vector3.new(-33.7862015, 5.19336414, -145.2034),
	
	Rewards = {
		{Type = "Ability", Id = 11, Chance = 1},
		{Type = "Material", Id = 10, Chance = 1, Amount = 1},
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 10, Amount = 10},
	},
	
	Enemies = {
		["Animated Construct"] = 1,
	},
	
	Floors = {
		[1] = {
			Name = "Academy of the City of Peace Training Course",
			Type = "Basic",
			Args = {
				TileSetName = "Castle",
				GridMap = {
					"  V  ",
					">-#-<",
					" >^< ",
				},
				StartRoomGridPosition = Vector2.new(3, 1),
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Adrasta van Linorei",
						Image = "rbxassetid://5617855826",
						Text = "Welcome to the Academy, slayer. Defeat these constructs to earn your right to wield the magic of the college!",
					}
				},
				OnFinished = {
					Dialogue = {
						Name = "Adrasta van Linorei",
						Image = "rbxassetid://5617855826",
						Text = "Well, done, slayer. I can see you are a capable student.",
					},
					Pause = 5,
				}
			},
		},
	}
}