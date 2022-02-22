return {
	Name = "Guard at the Gate",
	Description = "Begin your grueling journey into the heart of the Corrupted Crater with the ultimate goal of ensuring that the Selfish One is dead. To proceed, you must defeat the Shadow of Fiara, who was once Lorithas' High King's bodyguard. [This mission is brutally difficult and can only be undertaken alone. Be warned.]",
	Level = 100,
	PartySize = 1,
	
	MissionType = "Solo Challenge",
	MissionGroup = "CorruptedCrater",
	
	Requirements = {
		{Type = "Mission", Id = "rookiesGrave"},
	},
	
	MapPosition = Vector3.new(-31.585, 5.218, -141.688),
	
	Rewards = {
		{Type = "Weapon", Id = 68, Chance = 1},
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 8, Amount = 500},
		{Type = "Material", Id = 10, Amount = 500},
	},
	
	Enemies = {},
	
	Floors = {
		[1] = {
			Name = "Platform at the Crater's Edge",
			Type = "Custom",
			Args = {DungeonId = "corruptedCrater1"},
			Modifiers = {"Thunderstorm"},
		},
	}
}