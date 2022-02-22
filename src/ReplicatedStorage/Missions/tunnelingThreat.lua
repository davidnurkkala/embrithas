return {
	Name = "Tunneling Threat",
	Description = "Geomancers in the city of Neiss have reported an insidious seismic disturbance.",
	Level = 15,
	PartySize = 6,
	
	MissionType = "Story Mission",
	MissionGroup = "Orc",
	
	Requirements = {
		{Type = "Mission", Id = "towerAtKastakar"},
	},
	
	MapPosition = Vector3.new(-37.5914192, 5.19336414, -142.948456),
	
	Rewards = {
		{Type = "Weapon", Id = 57, Chance = 1/3},
		{Type = "Ability", Id = 24, Chance = 1/100},
		{Type = "Trinket", Id = 2, Chance = 1/3},
		{Type = "Material", Id = 10, Chance = 1},
		{Type = "Alignment", Faction = "College", Amount = 1, Reason = "you uncover some useful information about orcs."}
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 1, Amount = 9},
		{Type = "Material", Id = 6, Amount = 9},
		{Type = "Alignment", Faction = "College", Amount = 4},
	},
	
	Enemies = {
		["Orc"] = 2,
		["Orc Bulwark"] = 1,
		["Orc Archer"] = 1,
		["Orc Brute"] = 1,
		["Orc Shaman"] = 1,
	},
	
	Floors = {
		[1] = {
			Name = "Neiss Sewers",
			Type = "Basic",
			Args = {
				TileSetName = "Sewer",
				GridMap = {
					"  V  ",
					">---<",
					" ^  ^",
				},
				StartRoomGridPosition = Vector2.new(1, 2),
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Geomancer Helia",
						Image = "rbxassetid://5617842027",
						Text = "Thank you for coming on such short notice, Slayers. You should be able to find the source of the seismic disturbances beneath this sewer.",
					}
				}
			},
		},
		[2] = {
			Name = "Sewer Depths",
			Type = "Basic",
			Args = {
				TileSetName = "Sewer",
				GridMap = {
					">V",
					" ^",
				},
				StartRoomGridPosition = Vector2.new(1, 1),
			},
			
			Enemies = {
				["Orc"] = 2,
				["Orc Bulwark"] = 1,
				["Orc Archer"] = 1,
				["Orc Sapper"] = 1,
				["Orc Brute"] = 1,
				["Orc Shaman"] = 1,
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Geomancer Helia",
						Image = "rbxassetid://5617842027",
						Text = "Some of the nearest seismic disturbances are coming from this area. What could it be?",
					}
				}
			},
		},
		[3] = {
			Name = "Tunnel Entrance",
			Type = "Basic",
			Args = {
				TileSetName = "Mineshaft",
				GridMap = {
					"  V ",
					">--<",
					" ^  ",
				},
				StartRoomGridPosition = Vector2.new(3, 1),
			},
			
			FloorItemSets = {
				Bombs = {
					TrapBomb = {1, 6},
				}
			},
			FloorItemSetWeights = {
				None = 2,
				Bombs = 1,
			},
			
			Enemies = {
				["Orc Bulwark"] = 1,
				["Orc Miner"] = 1,
				["Orc Sapper"] = 1,
				["Orc Brute"] = 1,
				["Orc Shaman"] = 1,
			},
			
			Encounters = {
				{Type = "Mob", Enemy = "Orc Sapper", Count = 20, Level = 1, GridPosition = Vector2.new(2, 3)},
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Geomancer Helia",
						Image = "rbxassetid://5617842027",
						Text = "Are these orcs using... explosives? This is dire news. Let's clean up here and return to the surface with this new information. We'll be back to finish this.",
					}
				}
			},
		},
	}
}