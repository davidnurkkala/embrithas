return {
	Name = "Lessons in the Arcane III",
	Description = "Learn the ways of magic at the Academy of the City of Peace.",
	Level = 50,
	PartySize = 6,
	
	MissionType = "Story Mission",
	MissionGroup = "LessonsInTheArcane",
	
	Requirements = {
		{Type = "Alignment", Faction = "College", Amount = 20},
		{Type = "Mission", Id = "lessonsInTheArcaneII"},
	},
	
	MapPosition = Vector3.new(-33.7862015, 5.19336414, -145.2034),
	
	Rewards = {
		{Type = "Ability", Id = 14, Chance = 1},
		{Type = "Material", Id = 10, Chance = 1, Amount = 1},
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 10, Amount = 25},
	},
	
	Enemies = {
		["Animated Construct"] = 1,
		["Projected Construct"] = 1,
		["Blaster Construct"] = 1,
	},
	
	Floors = {
		[1] = {
			Name = "Academy of the City of Peace Training Course",
			Type = "Basic",
			Args = {
				TileSetName = "Castle",
				GridMap = {
					"   ><  ",
					"   |   ",
					">-----<",
					"   |   ",
					"   ><  ",
				},
				StartRoomGridPosition = Vector2.new(1, 3),
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Adrasta van Linorei",
						Image = "rbxassetid://5617855826",
						Text = "You are an able student. It's time for you to see a demonstration of a more powerful spell.",
					}
				},
				OnFinished = {
					Dialogue = {
						Name = "Adrasta van Linorei",
						Image = "rbxassetid://5617855826",
						Text = "Mastering such high-intensity mana expulsions is key to your progress. Keep up the good work, slayer.",
					},
					Pause = 5,
				}
			},
		},
	}
}