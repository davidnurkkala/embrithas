return {
	Name = "A Grave Issue",
	Description = "A decrepit cemetary outside the City of Peace is being haunted by undead.",
	Level = 5,
	PartySize = 6,
	
	MissionType = "Story Mission",
	MissionGroup = "Undead",
	
	Requirements = {
		{Type = "Mission", Id = "rookiesGrave"},
	},
	
	MapPosition = Vector3.new(-33.5582275, 5.19336414, -145.358017),
	
	Rewards = {
		{Type = "Weapon", Id = 14, Chance = 1/3},
		{Type = "Trinket", Id = 5, Chance = 1/4},
		{Type = "Material", Id = 2, Chance = 1},
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 2, Amount = 5},
	},
	
	Enemies = {
		["Skeleton"] = 7,
		["Skeleton Warrior"] = 4,
		["Bone Archer"] = 4,
		["Zombie"] = 1,
		["Skeleton Berserker"] = 1,
	},
	
	Floors = {
		[1] = {
			Name = "Shallow Grave",
			Type = "Granular2",
			Args = {RoomCount = 6, Theme = "Cave"},
			
			Encounters = {
				{Type = "Mob", Enemy = "Skeleton", Count = 12, Level = 1},
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "Gravetenders reported undead sightings here. Doubtless the foul Jukumai necromancers are involved. Time to put these bodies back where they belong!",
					}
				}
			},
		},
		[2] = {
			Name = "Damp Crypt",
			Type = "Basic",
			Args = {
				TileSetName = "Castle",
				GridMap = {
					" V ",
					">-<",
					"  ^",
				},
				StartRoomGridPosition = Vector2.new(2, 1),
			},
		},
		[3] = {
			Name = "Desecrated Burial",
			Type = "Basic",
			Args = {
				TileSetName = "Mineshaft",
				GridMap = {
					">V ",
					">-<",
				},
				StartRoomGridPosition = Vector2.new(1, 1),
			},
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "There's no end to these abominations. Surely we're nearing the number of this horde. Fight on, Slayers!",
					}
				}
			},
		},
		[4] = {
			Name = "Forlorn Memorial",
			Type = "Basic",
			Args = {
				TileSetName = "Castle",
				GridMap = {
					"><",
				},
				StartRoomGridPosition = Vector2.new(1, 1),
			},
			
			Encounters = {
				{Type = "EnemySet", Set = {"Skeleton Berserker"}}
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "Scouts are reporting this is the last affected area. No sign of Jukumai... was this just a distraction?",
					}
				}
			},
		},
	}
}