return {
	Name = "Conflagration",
	Description = "Descend into the burning caverns below Rookie's Grave and find out what happened to the slayer who went missing.",
	Level = 69,
	PartySize = 6,
	
	MissionType = "Story Mission",
	MissionGroup = "CorruptedElemental",
	
	Requirements = {
		{Type = "Mission", Id = "aFireBelow"},
	},
	
	MapPosition = Vector3.new(-32.928524, 5.19336414, -143.517456),
	
	Rewards = {
		{Type = "Material", Id = 10, Chance = 1, Amount = 3},
		{Type = "Ability", Id = 5, Chance = 1/12},
		{Type = "Alignment", Faction = "League", Amount = 1, Reason = "you continued the search for a missing League slayer."},
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 10, Amount = 5},
	},
	
	Enemies = {
		["Fiery Corruption"] = 4,
		["Stone Corruption"] = 1,
	},
	
	RequiredExpansion = 1,
	
	Floors = {
		[1] = {
			Name = "Deep Cavern",
			Type = "Granular",
			Args = {
				Theme = "Cave",
				ChunkMap = {
					">--V",
					"   ^",
				},
				StartRoomChunkPosition = Vector2.new(1, 1),
			},
			
			Enemies = {
				["Fiery Corruption"] = 1,
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Jeonsa",
						Image = "rbxassetid://5617856098",
						Text = "Goddess above, it's scorching down here. Get ready to descend, slayers. We're not leaving without finding out what happened to my comrade.",
					}
				}
			},
		},
		[2] = {
			Name = "Blazing Cavern",
			Type = "Granular",
			Args = {
				Theme = "MagmaCave",
				ChunkMap = {
					" ><",
					">V|",
					" ><",
				},
				StartRoomChunkPosition = Vector2.new(1, 2),
			},
			
			Encounters = {
				{Type = "Mob", Enemy = "Fiery Corruption", Count = 20, LevelDelta = -10},
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Jeonsa",
						Image = "rbxassetid://5617856098",
						Text = "These monsters... I've never seen anything like them. What's going on, here?",
					}
				}
			},
		},
		[3] = {
			Name = "Scorched Chamber",
			Type = "Granular",
			Args = {SizeInChunks = Vector2.new(1, 2), Theme = "MagmaCave"},
			
			Encounters = {
				{Type = "Multi", Encounters = {
					{Type = "Mob", Enemy = "Fiery Corruption", Count = 6, LevelDelta = -5},
					{Type = "Elite", Enemy = "Stone Corruption", LevelDelta = 10},
				}},
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Jeonsa",
						Image = "rbxassetid://5617856098",
						Text = "This is the lowest point of the cave system... surely she's here. Find out, Slayers.",
					}
				},
				
				OnFinished = {
					Dialogue = {
						Name = "Elle",
						Image = "rbxassetid://5700209073",
						Text = "Thanks for the assist, slayers. I'd've been toast without you. Catch you back at headquarters.",
					},
					Pause = 5,
				},
			},
		}
	}
}