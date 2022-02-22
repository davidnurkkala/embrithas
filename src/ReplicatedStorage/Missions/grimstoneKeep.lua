return {
	Name = "Grimstone Keep",
	Description = "Delve into the twisting corridors of Grimstone Keep, Lorithas' ancient prison.",
	Level = 45,
	PartySize = 6,
	
	MissionType = "Story Mission",
	MissionGroup = "OneOffs",
	
	MapPosition = Vector3.new(-30.9104805, 5.19336414, -142.473083),
	
	Rewards = {
		{Type = "Weapon", Id = 55, Chance = 1/6},
		{Type = "Weapon", Id = 56, Chance = 1/6},
		{Type = "Weapon", Id = 53, Chance = 1/6},
		{Type = "Weapon", Id = 54, Chance = 1/6},
		{Type = "Ability", Id = 23, Chance = 1/6},
		{Type = "Material", Id = 8, Chance = 1, Amount = 2},
	},
	
	Enemies = {
		["Chained One"] = 6,
		["Imprisoned One"] = 2,
		["Terrorknight"] = 4,
		["Terrorknight Jailor"] = 4,
		["Terrorknight Summoner"] = 4,
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 8, Amount = 15},
	},
	
	Floors = {
		[1] = {
			Name = "Aboard the Komodo",
			Type = "Custom",
			Args = {DungeonId = "lorithasPrisonBoat"},

			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Cap'n Kerris, Esq.",
						Image = "rbxassetid://5825863256",
						Text = "We're approaching Grimstone Keep now. Brace yourselves... any ship that passes too close'll get boarded by the ancient guards and their lackeys.",
					}
				},
				OnFinished = {
					Dialogue = {
						Name = "Cap'n Kerris, Esq.",
						Image = "rbxassetid://5825863256",
						Text = "All right, landlubbers. We made it through. Get ready to assault the fort proper. I'll await you on the beachhead.",
					},
					Pause = 5,
				}
			},
		},
		[2] = {
			Name = "Swampy Shoreline",
			Type = "Granular",
			Args = {
				Theme = "Swamp",
				ChunkMap = {
					">--V",
					"   |",
					"   ^",
				},
				StartRoomChunkPosition = Vector2.new(4, 3), 
			},

			Modifiers = {
				"Thunderstorm",
			},

			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Adrasta van Linorei",
						Image = "rbxassetid://5617855826",
						Text = "I've had fairer voyages, slayers, but at least we have arrived. Let's find a way up to the fort, shall we?",
					}
				}
			},
		},
		[3] = {
			Name = "Cliff Face",
			Type = "Granular",
			Args = {
				Theme = "Mountain",
				ChunkMap = {
					">-<",
				},
				StartRoomChunkPosition = Vector2.new(3, 1),
			},

			Encounters = {
				{Type = "Multi", ChunkPosition = Vector2.new(1, 1), Encounters = {
					{Type = "Elite", Enemy = "Terrorknight Jailor"},
					{Type = "EnemySet", Set = {
						"Terrorknight", 4,
						"Chained One", 6,
					}}
				}}
			},

			Modifiers = {
				"Thunderstorm",
			},

			Events = {
				OnFinished = {
					Dialogue = {
						Name = "Adrasta van Linorei",
						Image = "rbxassetid://5617855826",
						Text = "I see this prison's reputation is well earned... what a battle it was just to reach it. Now we can delve within and unlock its secrets!",
					},
					Pause = 5,
				}
			},
		},
		[4] = {
			Name = "Echoing Halls",
			Type = "Basic",
			Args = {
				TileSetName = "Castle",
				GridMap = {
					">-V",
					">V<",
					" >^",
				},
				StartRoomGridPosition = Vector2.new(1, 2), 
			},
			
			Encounters = {
				{Type = "Elite", Enemy = "Terrorknight Summoner", GridPosition = Vector2.new(2, 2)},
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Adrasta van Linorei",
						Image = "rbxassetid://5617855826",
						Text = "This place is... frightening. Do you hear...? No, surely it is my imagination.",
					}
				}
			},
		},
		[5] = {
			Name = "Deepest Cell",
			Type = "Custom",
			Args = {DungeonId = "cageBossDungeon"},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Adrasta van Linorei",
						Image = "rbxassetid://5617855826",
						Text = "It's said the warden of this place used terrifying magic to punish prisoners... what could be left of his awful machinations?",
					}
				},
				OnFinished = {
					Dialogue = {
						Name = "Adrasta van Linorei",
						Image = "rbxassetid://5617855826",
						Text = "It seems that the destruction of this device has deactivated the Terrorknights. Well done, slayers! We will begin excavations immediately...",
					},
					Pause = 5,
				}
			},
		},
	}
}