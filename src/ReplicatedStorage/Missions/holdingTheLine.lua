return {
	Name = "Holding the Line (Unfinished)",
	Description = "The shadows have come to reclaim what is theirs. They will never stop. How long can you hold?",
	Level = 100,
	PartySize = 10,
	
	MissionType = "Group Challenge",
	MissionGroup = "Shadow",
	
	MapPosition = Vector3.new(-33.211834, 5.19336414, -142.227554),
	
	Requirements = {
		{Type = "Mission", Id = "siegeOfFyreth"},
	},
	
	Enemies = {
		["Armored Shadow"] = 2,
		["Shadow Assassin"] = 2,
		["Mystic Shadow"] = 2,
		["Raging Shadow"] = 2,
		["Shadow Warrior"] = 2,
		["Immortal Shadow"] = 2,
		["Null"] = 2,
	},
	
	Floors = {
		[1] = {
			Name = "The Besieged Gate",
			Type = "HoldingTheLine",
			Args = {DungeonId = "shadowEndlessDefense"},

			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Vladiv \"Ironsides\" Kyrsek",
						Image = "rbxassetid://5617839594",
						Text = "They are beyond counting. They are without feeling. They are fierce. But we stand united! This patch of Lorithas is ours, Slayers! Glory awaits!",
					}
				},
			},
		},
	}
}