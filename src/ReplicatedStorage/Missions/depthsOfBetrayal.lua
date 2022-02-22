return {
	Name = "Depths of Betrayal",
	Description = "Alliance scouts have finally found a way into the sealed orc compound in Kakasta. It's time to delve in and investigate.",
	Level = 42,
	PartySize = 6,
	
	MissionType = "Story Mission",
	MissionGroup = "Orc",
	
	Requirements = {
		{Type = "Mission", Id = "growingSuspicion"},
	},
	
	MapPosition = Vector3.new(-35.091835, 5.19336414, -139.079865),
	
	Rewards = {
		{Type = "Ability", Id = 9, Chance = 1/5},
		{Type = "Material", Id = 1, Chance = 1, Amount = 3},
		{Type = "Material", Id = 6, Chance = 1, Amount = 2},
		{Type = "Material", Id = 8, Chance = 1, Amount = 1},
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 12, Amount = 25},
	},
	
	Enemies = {
		["Orc Miner"] = 8,
		["Orc Sapper"] = 8,
		["Orc Archer"] = 8,
		["Orc Bulwark"] = 8,
		["Orc"] = 8,
		["Orc Brute"] = 10,
		["Orc Berserker"] = 10,
		["Orc Shaman"] = 4,
		["Orc Lieutenant"] = 2,
	},
	
	Floors = {
		[1] = {
			Name = "Secret Tunnels",
			Type = "Granular",
			Args = {
				Theme = "Cave",
				ChunkMap = {
					">V  ",
					" ^< ",
					"  ^<",
				},
				StartRoomChunkPosition = Vector2.new(1, 1),
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "We've finally found a way to get deeper into this strange compound. Follow these tunnels, slayers. Find that way in.",
					}
				}
			},
		},
		[2] = {
			Name = "Facility Secret Entrance",
			Type = "Granular",
			Args = {
				Theme = "Lab",
				ChunkMap = {
					"   V",
					">--|",
					"   ^",
				},
				StartRoomChunkPosition = Vector2.new(1, 2),
			},
			
			FloorItemSets = {
				Bombs = {
					TrapBomb = {5, 10},
				}
			},
			FloorItemSetWeights = {
				None = 1,
				Bombs = 1,
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "???",
						Image = "rbxassetid://5617843718",
						Text = "Slayers... you'll never understand. Even if you destroy this place, my mission will go on. You cannot stop me.",
					}
				}
			},
		},
		[3] = {
			Name = "Facility Depths",
			Type = "Granular",
			Args = {SizeInChunks = Vector2.new(1, 2), Theme = "Lab"},
			
			FloorItemSets = {
				Bombs = {
					TrapBomb = {5, 10},
				}
			},
			FloorItemSetWeights = {
				None = 1,
				Bombs = 1,
			},
			
			Encounters = {
				{Type = "Multi", Encounters = {
					{Type = "Elite", Enemy = "Orc Lieutenant"},
					{Type = "Mob", Enemy = "Orc Shaman", Count = 6},
				}}
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "Who was that? That didn't sound like an orc... whoever or whatever it was is gone now. Cleanse this place and let's regroup.",
					}
				}
			},
		}
	}
}