return {
	Name = "Rookie's Grave",
	Description = "The Slayers permit monsters to live here so that when a culling becomes necessary the rookies have something to test their mettle on.",
	Level = 1,
	PartySize = 6,
	
	MissionType = "Tutorial",
	MissionGroup = "Tutorial",
	
	Requirements = {
		{Type = "Mission", Id = "recruitTraining"},
	},
	
	MapPosition = Vector3.new(-32.928524, 5.19336414, -143.517456),
	
	Rewards = {
		{Type = "Weapon", Id = 8, Chance = 1/4},
		{Type = "Trinket", Id = 1, Chance = 1/4},
		{Type = "Material", Id = 1, Chance = 1},
		{Type = "Alignment", Faction = "League", Amount = 1, Reason = "this is the beginning of your mighty story!"},
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 1, Amount = 3},
		{Type = "Material", Id = 6, Amount = 3},
		{Type = "Alignment", Faction = "League", Amount = 4},
	},
	
	Enemies = {
		["Orc"] = 2,
		["Orc Bulwark"] = 1,
		["Orc Archer"] = 1, 
	},
	
	Floors = {
		[1] = {
			Name = "Crumbling Fort",
			Type = "Basic",
			Args = {
				TileSetName = "Castle",
				GridMap = {
					"V-V",
					"|>^",
					"^  ",
				},
				StartRoomGridPosition = Vector2.new(2, 2),
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "Today's the last day any Slayer calls you a recruit, rookies! Prove yourselves and clear out this dungeon.",
					},
					
					Custom = function(run)
						wait(10)
						run:FireRemoteAll("TutorialUpdated", "rookiesGraveShowMap")
					end,
				}
			},
		},
		[2] = {
			Name = "Crumbling Fort Depths",
			Type = "Basic",
			Args = {
				TileSetName = "Mineshaft",
				GridMap = {
					"><",
					" |",
					"><",
				},
				StartRoomGridPosition = Vector2.new(1, 1),
			},
			
			Encounters = {
				{Type = "EnemySet", GridPosition = Vector2.new(2, 2), Set = {
					"Orc Shaman",
					"Orc Bulwark", 2,
				}},
				{Type = "Multi", GridPosition = Vector2.new(1, 3), Encounters = {
					{Type = "Elite", Enemy = "Orc Bulwark"},
					{Type = "Mob", Enemy = "Orc Shaman", Count = 2},
				}},
				{Type = "Lore", LoreId = "rookiesGraveJournal"},
			},
			
			Events = {
				OnFinished = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "Well done, rookies. Now for your final challenge. A powerful orc lurks in the cave below. I know you can defeat him!",
					},
					Pause = 5,
				}
			}
		},
		[3] = {
			Name = "Dark Cavern",
			Type = "Granular",
			Args = {SizeInChunks = Vector2.new(1, 2), Theme = "Cave"},
			
			Encounters = {
				{Type = "Elite", Enemy = "Orc Berserker", LevelDelta = 10},
			},
			
			Events = {
				OnFinished = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "Outstanding work, rookies. You're all sure to make great slayers someday. Let's head back and celebrate!",
					},
					Pause = 5,
				}
			},
		},
	}
}