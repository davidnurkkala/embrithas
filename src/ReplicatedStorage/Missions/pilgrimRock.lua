return {
	Name = "Pilgrim Rock",
	Description = "Join Drillmaster Leon on an annual journey to a holy site for Order slayers.",
	Level = 60,
	PartySize = 6,
	
	MissionType = "Story Mission",
	MissionGroup = "OneOffs",
	
	Requirements = {
		{Type = "Alignment", Faction = "Order", Amount = 20},
	},
	
	MapPosition = Vector3.new(-32.2944717, 5.19336414, -143.38855),
	
	Rewards = {
		{Type = "Ability", Id = 10, Chance = 1/12},
		{Type = "Material", Id = 10, Chance = 1, Amount = 2},
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 10, Amount = 5},
	},
	
	Enemies = {
		["Armored Shadow"] = 3,
		["Shadow Assassin"] = 1,
		["Mystic Shadow"] = 1,
	},
	
	Floors = {
		[1] = {
			Name = "Lorithasi Foothills",
			Type = "Granular",
			Args = {
				Theme = "Forest",
				ChunkMap = {
					">--V",
					"  >^",
				},
				StartRoomChunkPosition = Vector2.new(1, 1),
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "Slayers, thank you for joining me. We're climbing to Pilgrim Rock, an ancient site where one of the first Purifier slayers won a great victory.",
					}
				}
			},
		},
		[2] = {
			Name = "Dreadful Passage",
			Type = "Granular",
			Args = {
				Theme = "Cave",
				ChunkMap = {
					"    V",
					">---^",
					" ^   ",
				},
				StartRoomChunkPosition = Vector2.new(1, 2),
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "This cave symbolizes the dread that all mortals felt when the Great Corruption happened. They, like us, feared what might become of the world the Goddess left in our care.",
					}
				}
			},
		},
		[3] = {
			Name = "Aspiring Climb",
			Type = "Granular",
			Args = {
				Theme = "Mountain",
				ChunkMap = {
					"V   ",
					">--V",
					"   |",
					"   |",
					"   ^",
				},
				StartRoomChunkPosition = Vector2.new(4, 5),
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "This stretch of mountain symbolizes the aspiration to return the world to its rightful state -- at peace, and without monsters. Like this climb, it will be a difficult task.",
					}
				}
			},
		},
		[4] = {
			Name = "Pilgrim Rock Shrine",
			Type = "Basic",
			Args = {
				TileSetName = "Castle",
				GridMap = {
					"><",
				},
				StartRoomGridPosition = Vector2.new(1, 1),
			},
			
			Encounters = {
				{Type = "Multi", Encounters = {
					{Type = "Elite", Enemy = "Raging Shadow"},
					{Type = "Elite", Enemy = "Armored Shadow"},
					{Type = "Elite", Enemy = "Shadow Warrior"},
					{Type = "Elite", Enemy = "Mystic Shadow"},
					{Type = "Elite", Enemy = "Shadow Assassin"},
				}}
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "This shrine was constructed upon the site of a great victory for the Order of Purifiers. It's not known why, but powerful shadows gather here. Prepare yourselves.",
					}
				},
				
				OnFinished = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "Well done and thank you, slayers. This place is very important to me, and to be able to pray to the Distant Goddess here refreshes my soul.",
					},
					Pause = 5,
				}
			},
		}
	}
}