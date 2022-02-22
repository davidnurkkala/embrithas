return {
	Name = "Blessed Spring",
	Description = "Go with Drillmaster Leon to his homeland of Yakund and help with the production of Blessed Water.",
	Level = 80,
	PartySize = 6,
	
	MissionType = "Story Mission",
	MissionGroup = "OneOffs",
	
	Requirements = {
		{Type = "Alignment", Faction = "Order", Amount = 35},
	},
	
	MapPosition = Vector3.new(-36.613, 5.218, -145.49),
	
	Rewards = {
		{Type = "Ability", Id = 15, Chance = 1/6},
		{Type = "Material", Id = 10, Chance = 1, Amount = 4},
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 10, Amount = 10},
	},
	
	Enemies = {
		["Stone Corruption"] = 1,
		["Zombie"] = 8,
		["Bone Archer"] = 4,
	},
	
	Floors = {
		[1] = {
			Name = "Blessed Spring",
			Type = "Custom",
			Args = {
				DungeonId = "blessedWaterDungeon",
				FloorScript = script.blessedSpringFloor1,
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "Slayers, welcome to my homeland. Well, a remote part of it, at least. Here the light from the Distant Goddess shines down and allows us to create Blessed Water. Let's get to work! Fill a flask at the spring and bring it to the shrine.",
					}
				}
			},
		}
	}
}