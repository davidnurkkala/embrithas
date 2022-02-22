return {
	Name = "Raid: Siege of Fyreth",
	Description = "With the staging area ready, Vladiv plans to conquer and occupy Fyreth for the Slayer Alliance. [This mission is a raid and is recommended for a party of 20.]",
	LockedDescription = "Gather a party and conquer an entire city... Complete this mission's requirements to reveal more details.",
	Level = 50,
	PartySize = 20,
	
	MissionType = "Story Mission",
	MissionGroup = "Shadow",
	
	StartingLifeCount = 10,
	LifeType = "Raid",
	
	MapPosition = Vector3.new(-33.211834, 5.19336414, -142.227554),
	
	Requirements = {
		{Type = "Mission", Id = "outskirtsOfFyreth"},
	},
	
	RewardsRolledSeperately = true,
	Rewards = {
		{Type = "Weapon", Id = 27, Chance = 1/3},
		{Type = "Weapon", Id = 30, Chance = 1/3},
		{Type = "Material", Id = 1, Chance = 1, Amount = 30},
		{Type = "Material", Id = 6, Chance = 1, Amount = 25},
		{Type = "Material", Id = 2, Chance = 1, Amount = 15},
		{Type = "Material", Id = 10, Chance = 1, Amount = 10},
		{Type = "Material", Id = 11, Chance = 1/4, Amount = 1},
		
		{Type = "Alignment", Faction = "League", Amount = 5, Reason = "you conquered an entire city! Amazing!"},
		{Type = "Alignment", Faction = "College", Amount = -5, Reason = "Fyreth could have held many secrets, but this assault is reckless and destructive."},
		{Type = "Alignment", Faction = "Order", Amount = 5, Reason = "you have expunged an entire corrupted city from the world!"},
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 10, Amount = 10},
		{Type = "Material", Id = 1, Amount = 25},
		{Type = "Material", Id = 6, Amount = 25},
		{Type = "Material", Id = 2, Amount = 15},
	},
	
	Enemies = {
		["Armored Shadow"] = 2,
		["Shadow Assassin"] = 2,
		["Mystic Shadow"] = 2,
		["Raging Shadow"] = 1,
		["Shadow Warrior"] = 1,
	},
	
	Floors = {
		[1] = {
			Name = "Gate Approach",
			Type = "Granular",
			Args = {
				Theme = "Forest",
				ChunkMap = {
					"V    ",
					"|  V<",
					">V | ",
					" | | ",
					" >-< ",
				},
				StartRoomChunkPosition = Vector2.new(1, 1),
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
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Vladiv \"Ironsides\" Kyrsek",
						Image = "rbxassetid://5617839594",
						Text = "Slayers! This is the hour of glory and conquest! Today we wipe a corrupted city from the map! Today we take Fyreth for the Alliance! Chaaarge!",
					}
				}
			},
		},
		[2] = {
			Name = "Outer Fortifications",
			Type = "Basic",
			Args = {
				TileSetName = "Castle",
				GridMap = {
					"V-V",
					"| |",
					"^-^",
					" | ",
					"V-V",
					"| |",
					"^-^",
				},
				StartRoomGridPosition = Vector2.new(2, 4),
			},
			
			FloorItemSets = {
				Gas = {
					TrapGas = {4, 6},
				}
			},
			FloorItemSetWeights = {
				None = 2,
				Gas = 1,
			},
		},
		[3] = {
			Name = "Great Eastern Gate of Fyreth",
			Type = "Custom",
			Args = {DungeonId = "shadowBossDungeon1"},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Vladiv \"Ironsides\" Kyrsek",
						Image = "rbxassetid://5617839594",
						Text = "Our mages are detecting a huge presence within this gate. Probably a good fight ahead!",
					}
				}
			},
		},
		[4] = {
			Name = "Eastern Walls",
			Type = "Basic",
			Args = {
				TileSetName = "Castle",
				GridMap = {
					">V  ",
					" |< ",
					" |  ",
					" >-<",
					" |  ",
					" |< ",
					">^  ",
				},
				StartRoomGridPosition = Vector2.new(4, 4),
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
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Vladiv \"Ironsides\" Kyrsek",
						Image = "rbxassetid://5617839594",
						Text = "Once we've occupied this wall, we'll head through the sewers to avoid exposure and head to the docks.",
					}
				}
			},
		},
		[5] = {
			Name = "Fyreth Sewers East",
			Type = "Basic",
			Args = {
				TileSetName = "Sewer",
				GridMap = {
					"   V   ",
					">-----V",
					"    ^ |",
					"      |",
					"     ><",
				},
				StartRoomGridPosition = Vector2.new(1, 2),
			},
			
			FloorItemSets = {
				Gas = {
					TrapGas = {4, 6},
				}
			},
			FloorItemSetWeights = {
				Gas = 1,
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Vladiv \"Ironsides\" Kyrsek",
						Image = "rbxassetid://5617839594",
						Text = "This place is putrid, but it sure beats getting pelted with countless shadow bolts. Find an exit leading to the wharf, on the double!",
					}
				}
			},
		},
		[6] = {
			Name = "Fyreth Docks",
			Type = "Custom",
			Args = {DungeonId = "shadowBossDungeon2"},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Vladiv \"Ironsides\" Kyrsek",
						Image = "rbxassetid://5617839594",
						Text = "There's another powerful entity guarding the docks. Claim your glory, slayers!",
					}
				}
			},
		},
		[7] = {
			Name = "Fyreth Sewers North",
			Type = "Basic",
			Args = {
				TileSetName = "Sewer",
				GridMap = {
					"  V ",
					">-| ",
					"  | ",
					"  | ",
					" >|<",
					">-^ ",
				},
				StartRoomGridPosition = Vector2.new(3, 1),
			},
			
			FloorItemSets = {
				Gas = {
					TrapGas = {4, 6},
				}
			},
			FloorItemSetWeights = {
				Gas = 1,
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Vladiv \"Ironsides\" Kyrsek",
						Image = "rbxassetid://5617839594",
						Text = "One more trek through the sewers, slayers! Next stop: the castle in the center of this city! You know what the say, cut off the head of the snake and the body dies.",
					}
				}
			},
		},
		[8] = {
			Name = "Fyreth Keep B1",
			Type = "Basic",
			Args = {
				TileSetName = "Castle",
				GridMap = {
					">---< ",
					"| ^ | ",
					"|  >|<",
					"|   | ",
					">---< ",
					"   ^  ",
				},
				StartRoomGridPosition = Vector2.new(6, 3),
			},
			
			FloorItemSets = {
				Bombs = {
					TrapBomb = {1, 10},
				}
			},
			FloorItemSetWeights = {
				Bombs = 1,
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Vladiv \"Ironsides\" Kyrsek",
						Image = "rbxassetid://5617839594",
						Text = "All right, these tunnels are just beneath the keep. Find a way up!",
					}
				}
			},
		},
		[9] = {
			Name = "Fyreth Keep F1",
			Type = "Basic",
			Args = {
				TileSetName = "Castle",
				GridMap = {
					">--<",
					"|^ |",
					"|  |",
					">--<",
				},
				StartRoomGridPosition = Vector2.new(2, 2),
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Vladiv \"Ironsides\" Kyrsek",
						Image = "rbxassetid://5617839594",
						Text = "We're in the keep proper. Clear it out and keep climbing!",
					}
				}
			},
		},
		[10] = {
			Name = "Fyreth Keep F2",
			Type = "Basic",
			Args = {
				TileSetName = "Castle",
				GridMap = {
					">-<",
					"|^|",
					">-<",
				},
				StartRoomGridPosition = Vector2.new(2, 2),
			},
		},
		[11] = {
			Name = "Fyreth Keep Throne Room",
			Type = "Custom",
			Args = {DungeonId = "shadowBossDungeon3"},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Vladiv \"Ironsides\" Kyrsek",
						Image = "rbxassetid://5617839594",
						Text = "This is it, slayers! The final fight! Get ready for your finest battle yet! Charge!",
					}
				}
			},
		},
	}
}