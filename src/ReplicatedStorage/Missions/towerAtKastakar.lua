return {
	Name = "Tower at Kastakar",
	Description = "An infestation of orcs has sprung up in the dungeons beneath the Tower at Kastakar.",
	Level = 5,
	PartySize = 6,
	
	MissionType = "Story Mission",
	MissionGroup = "Orc",
	
	Requirements = {
		{Type = "Mission", Id = "rookiesGrave"},
	},
	
	MapPosition = Vector3.new(-33.9152794, 5.19336414, -137.76265),
	
	Rewards = {
		{Type = "Weapon", Id = 7, Chance = 1/6},
		{Type = "Ability", Id = 2, Chance = 1/3},
		{Type = "Trinket", Id = 3, Chance = 1/4},
		{Type = "Material", Id = 6, Chance = 1},
		{Type = "Alignment", Faction = "League", Amount = 1, Reason = "you slay a mighty orc lieutenant!"},
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 1, Amount = 5},
		{Type = "Material", Id = 6, Amount = 5},
	},
	
	Enemies = {
		["Orc"] = 4,
		["Orc Bulwark"] = 2,
		["Orc Archer"] = 2,
		["Orc Brute"] = 1, 
		["Orc Shaman"] = 1,
	},
	
	Floors = {
		[1] = {
			Name = "Tower Entrance",
			Type = "Basic",
			Args = {
				TileSetName = "Castle",
				GridMap = {
					">-V",
					"V |",
					">-<",
				},
				StartRoomGridPosition = Vector2.new(1, 1),
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "All right, rookies. The Jolians reported an orc infestation and we're the exterminators. Go to work!",
					}
				}
			},
		},
		[2] = {
			Name = "Tower Basement",
			Type = "Basic",
			Args = {
				TileSetName = "Castle",
				GridMap = {
					"VV",
					">#",
				},
				StartRoomGridPosition = Vector2.new(2, 2),
			},
			Encounters = {
				{Type = "Lore", LoreId = "towerAtKastakarForemanReport"},
			}
		},
		[3] = {
			Name = "Orc Tunnel",
			Type = "Basic",
			Args = {Size = Vector2.new(1, 4), TileSetName = "Mineshaft", StartRoomGridPosition = Vector2.new(1, 4)},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "Well, this tunnel explains where the orcs have been coming from. Clear it out and let's purge this at the source.",
					}
				}
			},
		},
		[4] = {
			Name = "Orc Nest",
			Type = "Granular",
			Args = {SizeInChunks = Vector2.new(1, 2), Theme = "Cave"},
			
			Encounters = {
				{Type = "EnemySet", Set = {"Orc", 25, "Orc Archer", 5, "Orc Shaman"}, Level = 1},
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "By the Distant Goddess, there's an entire nest down here! You know what to do, rookies.",
					}
				}
			},
		},
		[5] = {
			Name = "Orc Stronghold",
			Type = "Custom",
			Args = {DungeonId = "orcBossDungeon"},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "I've got a bad feeling about this place. Be ready for a real fight.",
					}
				}
			},
		},
	}
}