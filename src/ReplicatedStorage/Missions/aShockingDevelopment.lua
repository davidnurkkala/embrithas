return {
	Name = "A Shocking Development",
	Description = "Help Elle investigate rumors of corrupted elemental sightings at Thundertop Iron Mine.",
	Level = 90,
	PartySize = 6,
	
	MissionType = "Story Mission",
	MissionGroup = "CorruptedElemental",
	
	Requirements = {
		{Type = "Mission", Id = "aChillingDiscovery"},
	},
	
	MapPosition = Vector3.new(-37.3595772, 5.19336414, -136.673462),
	
	Rewards = {
		{Type = "Material", Id = 1, Chance = 1, Amount = 5},
		{Type = "Ability", Id = 7, Chance = 1/12},
		{Type = "Alignment", Faction = "League", Amount = -2, Reason = "they believe the Alliance shouldn't be involved with the affairs between Kakasta and the Jolian Empire."},
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 1, Amount = 25},
	},
	
	RequiredExpansion = 1,
	
	Floors = {
		[1] = {
			Name = "Thundertop Approach",
			Type = "Granular",
			Args = {
				Theme = "Mountain",
				ChunkMap = {
					" --V",
					">| |",
					"   ^",
				},
				StartRoomChunkPosition = Vector2.new(1, 2),
			},
			
			Modifiers = {
				"Thunderstorm",
			},
			
			Enemies = {
				["Stone Corruption"] = 1,
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Elle",
						Image = "rbxassetid://5700209073",
						Text = "Some of my countrymen have been talking about some new elementals in this area. Let's investigate.",
					},
				},
				OnFinished = {
					Dialogue = {
						Name = "Elle",
						Image = "rbxassetid://5700209073",
						Text = "Well, that's a bit disappointing. Nothing but old fashioned Stone Corruptions. Maybe we'll spot them further up!",
					},
					Pause = 5,
				}
			},
		},
		[2] = {
			Name = "Bolt-break Pass",
			Type = "Granular",
			Args = {
				Theme = "Mountain",
				ChunkMap = {
					">--<",
				},
				StartRoomChunkPosition = Vector2.new(4, 1),
			},
			
			Modifiers = {
				"Thunderstorm",
			},
			
			Enemies = {
				["Corrupted Lightning"] = 1,
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Elle",
						Image = "rbxassetid://5700209073",
						Text = "Anyone else feeling their hairs stand up on end, or is that just me?",
					},
				},
				OnFinished = {
					Dialogue = {
						Name = "Elle",
						Image = "rbxassetid://5700209073",
						Text = "Wow, these new elementals are fast! Good thing they aren't faster than good ol' Jolian bullets, though! Ha ha ha!",
					},
					Pause = 5,
				},
			},
		},
		[3] = {
			Name = "Abandoned Mine",
			Type = "Basic",
			Args = {
				TileSetName = "Mineshaft",
				GridMap = {
					"V  ",
					"|  ",
					">-<",
					"  ^",
				},
				StartRoomGridPosition = Vector2.new(1, 1),
			},
			
			Enemies = {
				["Corrupted Lightning"] = 2,
				["Stone Corruption"] = 1,
			},
			
			Encounters = {
				{Type = "Elite", Enemy = "Corrupted Lightning", LevelDelta = 50, GridPosition = Vector2.new(3, 4)},
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Elle",
						Image = "rbxassetid://5700209073",
						Text = "Readings indicate the epicenter of the elemental corruption's inside this mine. Huh, you'd think it'd want to be out with the rest of the lightning, wouldn't you?",
					},
				},
				OnFinished = {
					Dialogue = {
						Name = "Elle",
						Image = "rbxassetid://5700209073",
						Text = "Good work, slayers. Now the miners up here only have to deal with the regular lightning, again! Let's head home.",
					},
					Pause = 5,
				},
			},
		},
	}
}