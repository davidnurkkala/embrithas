return {
	Name = "Homefront Defense",
	Description = "An especially large wave of Shadows is assaulting Fort Ryonos, and they have called for reinforcements.",
	Level = 20,
	PartySize = 6,
	
	MissionType = "Story Mission",
	MissionGroup = "Shadow",
	
	MapPosition = Vector3.new(-32.0474548, 5.19336414, -143.755371),
	
	Rewards = {
		{Type = "Weapon", Id = 23, Chance = 1/4},
		{Type = "Material", Id = 6, Chance = 1/2, Amount = 3},
		{Type = "Material", Id = 2, Chance = 1/2, Amount = 3},
		{Type = "Trinket", Id = 9, Chance = 1/10},
		{Type = "Alignment", Faction = "Order", Amount = 1, Reason = "you don't give up a single inch of sacred Embrithas."},
		{Type = "Alignment", Faction = "College", Amount = 1, Reason = "any conflict with the mysterious Shadows and their immunity to corruption is valuable information."},
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 10, Amount = 5},
	},
	
	Enemies = {
		["Armored Shadow"] = 1,
		["Shadow Assassin"] = 1,
		["Mystic Shadow"] = 1,
	},
	
	Floors = {
		[1] = {
			Name = "Overrun Tower",
			Type = "Basic",
			Args = {
				TileSetName = "Castle",
				GridMap = {
					">-V",
					"V |",
					">-<",
				},
				StartRoomGridPosition = Vector2.new(1, 2),
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Vladiv \"Ironsides\" Kyrsek",
						Image = "rbxassetid://5617839594",
						Text = "Welcome to Fort Ryonos, slayers! You're just in time to claim some glory for yourselves. Get moving!",
					}
				}
			},
		},
		[2] = {
			Name = "Old Quarry",
			Type = "Basic",
			Args = {
				TileSetName = "Mineshaft",
				GridMap = {
					"V ",
					"|<",
					"^ ",
				},
				StartRoomGridPosition = Vector2.new(2, 2),
			},
		},
		[3] = {
			Name = "Forward Fortification",
			Type = "Basic",
			Args = {
				TileSetName = "Castle",
				GridMap = {
					"V V",
					"#-#",
					"^ ^",
				},
				StartRoomGridPosition = Vector2.new(3, 3),
			},
			
			Encounters = {
				{Type = "Multi", GridPosition = Vector2.new(2, 2), Encounters = {
					{Type = "Elite", Enemy = "Armored Shadow"},
					{Type = "Elite", Enemy = "Armored Shadow"},
					{Type = "Elite", Enemy = "Shadow Assassin"},
					{Type = "Mob", Count = 8, Enemy = "Mystic Shadow", LevelDelta = -10},
				}}
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Vladiv \"Ironsides\" Kyrsek",
						Image = "rbxassetid://5617839594",
						Text = "I'm in your debt, slayers. Clear this fort, and you're done. Next time we're both at base, I'll treat you at the tavern, ha ha!",
					}
				}
			},
		}
	}
}