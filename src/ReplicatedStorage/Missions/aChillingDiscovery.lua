return {
	Name = "A Chilling Discovery",
	Description = "Elle has located a strange area of corruption in the Arinthari mountains.",
	Level = 78,
	PartySize = 6,
	
	MissionType = "Story Mission",
	MissionGroup = "CorruptedElemental",
	
	Requirements = {
		{Type = "Mission", Id = "conflagration"},
	},
	
	MapPosition = Vector3.new(-36.5860214, 5.19336414, -141.187561),
	
	Rewards = {
		{Type = "Material", Id = 12, Chance = 1, Amount = 3},
		{Type = "Ability", Id = 6, Chance = 1/12},
		{Type = "Alignment", Faction = "League", Amount = -2, Reason = "getting that close to the Kakastan border is asking for political trouble."},
		{Type = "Alignment", Faction = "College", Amount = 2, Reason = "they find this new monster intriguing."}
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 4, Amount = 5},
		{Type = "Material", Id = 12, Amount = 5},
	},
	
	Enemies = {
		["Stone Corruption"] = 1,
	},
	
	RequiredExpansion = 1,
	
	Floors = {
		[1] = {
			Name = "Rock-strewn Mountainside",
			Type = "Granular",
			Args = {
				Theme = "Mountain",
				ChunkMap = {
					">--V",
					"^  |",
					"   ^",
				},
				StartRoomChunkPosition = Vector2.new(1, 2),
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Elle",
						Image = "rbxassetid://5700209073",
						Text = "Thanks for tagging along, slayers. This is definitely the place -- crawling with stone corruptions. But according to my readings, the source should be further up the slope. Let's get to climbing!",
					},
				}
			},
		},
		[2] = {
			Name = "Lower Snowcap",
			Type = "Granular",
			Args = {
				Theme = "Snow",
				ChunkMap = {
					">--V",
					"   ^",
				},
				StartRoomChunkPosition = Vector2.new(4, 2),
			},
			
			Enemies = {
				["Frozen Corruption"] = 1,
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Elle",
						Image = "rbxassetid://5700209073",
						Text = "Ah, what's this? A new type of corrupted elemental! Let's \"investigate\" them -- first experiment: how do they handle blunt force trauma? C'mon, slayers!",
					},
				}
			},
		},
		[3] = {
			Name = "Upper Snowcap",
			Type = "Granular",
			Args = {SizeInChunks = Vector2.new(1, 3), Theme = "Snow"},
			
			Enemies = {
				["Frozen Corruption"] = 2,
				["Stone Corruption"] = 1,
			},
			
			Encounters = {
				{Type = "Multi", Encounters = {
					{Type = "Mob", Enemy = "Frozen Corruption", Count = 6, LevelDelta = -5},
					{Type = "Elite", Enemy = "Stone Corruption", LevelDelta = 10},
				}},
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Elle",
						Image = "rbxassetid://5700209073",
						Text = "Phew, air's getting a bit thin up here, huh? Well, we're almost there.",
					},
				},
				
				OnFinished = {
					Dialogue = {
						Name = "Elle",
						Image = "rbxassetid://5700209073",
						Text = "Well hey, what's this? An old Arinthari fort, perhaps? Old abandoned places like these often get corrupted. Let's investigate.",
					},
					Pause = 5,
				},
			},
		},
		[4] = {
			Name = "Frigid Fortress",
			Type = "Granular",
			Args = {SizeInChunks = Vector2.new(2, 2), Theme = "FrozenCastle"},
			
			Enemies = {
				["Frozen Corruption"] = 2,
				["Stone Corruption"] = 1,
			},
			
			Encounters = {
				{Type = "Multi", Encounters = {
					{Type = "Elite", Enemy = "Frozen Corruption", LevelDelta = 5},
					{Type = "Elite", Enemy = "Frozen Corruption", LevelDelta = 5},
					{Type = "Elite", Enemy = "Frozen Corruption", LevelDelta = 5},
				}}
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Elle",
						Image = "rbxassetid://5700209073",
						Text = "Not much warmer in here. Well, slayers, it'd be irresponsible to leave these monsters unchecked. Let's get to work!",
					},
				},
				
				OnFinished = {
					Dialogue = {
						Name = "Elle",
						Image = "rbxassetid://5700209073",
						Text = "Hm, this fort is bigger than I thought. Let's report back to headquarters and see if we can't get some reinforcements.",
					},
					Pause = 5,
				},
			},
		}
	}
}