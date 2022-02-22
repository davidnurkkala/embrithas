return {
	Name = "Lessons in the Arcane II",
	Description = "Learn the ways of magic at the Academy of the City of Peace.",
	Level = 36,
	PartySize = 6,
	
	MissionType = "Story Mission",
	MissionGroup = "LessonsInTheArcane",
	
	Requirements = {
		{Type = "Alignment", Faction = "College", Amount = 10},
		{Type = "Mission", Id = "lessonsInTheArcaneI"},
	},
	
	MapPosition = Vector3.new(-33.7862015, 5.19336414, -145.2034),
	
	Rewards = {
		{Type = "Weapon", Id = 52, Chance = 1},
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 10, Amount = 10},
	},
	
	Enemies = {
		["Animated Construct"] = 1,
		["Projected Construct"] = 1,
	},
	
	Floors = {
		[1] = {
			Name = "Academy of the City of Peace Training Course",
			Type = "Basic",
			Args = {
				TileSetName = "Castle",
				GridMap = {
					"V V V",
					">-#-<",
					" >^<V",
					"  ^-<",
				},
				StartRoomGridPosition = Vector2.new(3, 1),
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Adrasta van Linorei",
						Image = "rbxassetid://5617855826",
						Text = "Back to learn more, slayer? Very well, let's break out some more difficult constructs to fight.",
					}
				},
				OnFinished = {
					Dialogue = {
						Name = "Adrasta van Linorei",
						Image = "rbxassetid://5617855826",
						Text = "Capable as always, slayer. At this rate you'll be a true master of magic in no time!",
					},
					Pause = 5,
				}
			},
		},
	}
}