return {
	Name = "Raid: The Yawning Abyss",
	Description = "The Alliance has found the Jukumai necromancer in a forgotten fortress in the depths of the great chasm. [This mission is a raid and is recommended for a party of 20.] [Warning: this mission includes mechanics that are nearly impossible without multiple party members. Do not attempt to complete it alone!]",
	LockedDescription = "Discover what lies in the deep... Complete this mission's requirements to reveal more details.",
	Level = 70,
	PartySize = 20,
	
	MissionType = "Raid",
	MissionGroup = "Undead",
	
	StartingLifeCount = 10,
	LifeType = "Raid",
	
	MapPosition = Vector3.new(-36.3766632, 5.19336414, -146.966965),
	
	Requirements = {
		{Type = "Mission", Id = "clawingAtTheWalls"},
	},
	
	RewardsRolledSeperately = true,
	Rewards = {
		{Type = "Weapon", Id = 47, Chance = 1/3},
		{Type = "Weapon", Id = 48, Chance = 1/3},
		{Type = "Weapon", Id = 49, Chance = 1/3},
		
		{Type = "Material", Id = 1, Chance = 1, Amount = 30},
		{Type = "Material", Id = 6, Chance = 1, Amount = 30},
		{Type = "Material", Id = 2, Chance = 1, Amount = 15},
		{Type = "Material", Id = 10, Chance = 1, Amount = 10},
		
		{Type = "Alignment", Faction = "League", Amount = 7},
		{Type = "Alignment", Faction = "College", Amount = 7},
		{Type = "Alignment", Faction = "Order", Amount = -7},
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 2, Amount = 50},
		{Type = "Material", Id = 10, Amount = 50},
	},
	
	Enemies = {
		["Skeleton"] = 8,
		["Bone Archer"] = 8,
		["Skeleton Warrior"] = 8,
		["Ghost"] = 6,
		["Zombie"] = 6,
		["Zombie Defender"] = 4,
		["Skeleton Berserker"] = 4,
	},
	
	Floors = {
		[1] = {
			Name = "Swamp Approach",
			Type = "Granular",
			Args = {
				Theme = "Swamp",
				ChunkMap = {
					">---V",
					"V---^",
					"^---<",
				},
				StartRoomChunkPosition = Vector2.new(5, 3), 
			},
			
			Encounters = {
				{Type = "Elite", Enemy = "Osseous Aberration", ChunkPosition = Vector2.new(1, 1)},
			},
			
			FloorItemSets = {
				Gas = {
					TrapGas = {1, 6},
				}
			},
			FloorItemSetWeights = {
				Gas = 1,
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Adrasta van Linorei",
						Image = "rbxassetid://5617855826",
						Text = "Welcome to the operation, slayers. Deacon Avery was supposed to lead this assault, but unfortunately the situation with the Sketh demands quite a lot of attention. Let's push to the chasm's edge, slayers!",
					}
				}
			},
		},
		[2] = {
			Name = "Cliff's Edge",
			Type = "Granular",
			Args = {
				Theme = "Mountain",
				ChunkMap = {
					"V   ",
					"|  V",
					"|  |",
					">--<",
					"|V  ",
					"|V  ",
					"^<  ",
				},
				StartRoomChunkPosition = Vector2.new(4, 2),
			},
			
			Encounters = {
				{Type = "Multi", ChunkPosition = Vector2.new(2, 5), Encounters = {
					{Type = "Mob", Enemy = "Ghost", Count = 20},
					{Type = "Elite", Enemy = "Zombie Defender"},
				}}
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Adrasta van Linorei",
						Image = "rbxassetid://5617855826",
						Text = "Slayers, we have a team ready to deploy a device that will lower us into the chasm. First we have to clear the cliff's edge so we can set it up.",
					}
				}
			},
		},
		[3] = {
			Name = "The Descent",
			Type = "Custom",
			Args = {DungeonId = "yawningAbyssLift"},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Adrasta van Linorei",
						Image = "rbxassetid://5617855826",
						Text = "Impressive device, no? College ingenuity inspired by Jolian designs. It can -- wait, Slayers! Look above you!",
					}
				},
				
				OnFinished = {
					Dialogue = {
						Name = "Adrasta van Linorei",
						Image = "rbxassetid://5617855826",
						Text = "All right, slayers. We're about to reach the bottom. Initial surveys suggest an ancient fortress lies down there. What secrets it may hold will have to wait. Ready yourselves!",
					},
					Pause = 7,
				},
			},
		},
		[4] = {
			Name = "Ancient Fortress Entrance",
			Type = "Basic",
			Args = {
				TileSetName = "Castle",
				GridMap = {
					"V<",
					"^|",
					" |",
					"V|",
					"^<",
				},
				StartRoomGridPosition = Vector2.new(2, 3),
			},
			
			Modifiers = {
				"UndeadDeathMiasma",
			},
			
			Encounters = {
				{Type = "Mob", Enemy = "Osseous Aberration", GridPosition = Vector2.new(1, 2), Count = 1},
				{Type = "Mob", Enemy = "Osseous Aberration", GridPosition = Vector2.new(1, 4), Count = 1},
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Adrasta van Linorei",
						Image = "rbxassetid://5617855826",
						Text = "Slayers, the enemy has deployed some sort of misasma which is sapping away at our life forces and preventing any type of healing. We'll have to push forward as quickly as possible and destroy its source.",
					}
				}
			},
		},
		[5] = {
			Name = "Ancient Fortress Keep",
			Type = "Basic",
			Args = {
				TileSetName = "Castle",
				GridMap = {
					"><  ",
					"|^< ",
					"^--V",
					"V--^",
					"|V< ",
					"><  ",
				},
				StartRoomGridPosition = Vector2.new(4, 3),
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Adrasta van Linorei",
						Image = "rbxassetid://5617855826",
						Text = "Those aberrations were the source, evidently. Let's push forward, slayers. We're detecting the Jukumai necromancer even further down... unfathomable.",
					}
				}
			},
		},
		[6] = {
			Name = "Crypt Descent",
			Type = "Granular",
			Args = {
				Theme = "Crypt",
				ChunkMap = {
					"V--<",
					"|><|",
					">-^|",
					">--^",
				},
				StartRoomChunkPosition = Vector2.new(1, 4),
			},
			
			Encounters = {
				{Type = "Multi", ChunkPosition = Vector2.new(2, 2), Encounters = {
					{Type = "Elite", Enemy = "Skeleton Berserker"},
					{Type = "Elite", Enemy = "Skeleton Berserker"},
					{Type = "Elite", Enemy = "Skeleton Berserker"},
					{Type = "Elite", Enemy = "Zombie Defender"},
				}}
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Adrasta van Linorei",
						Image = "rbxassetid://5617855826",
						Text = "Goddess above, these crypts must be ancient. Try not to damage them too much as we continue down further, slayers.",
					}
				}
			},
		},
		[7] = {
			Name = "The Grand Mausoleum",
			Type = "Custom",
			Args = {DungeonId = "cryptkeeperBossDungeon"},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Adrasta van Linorei",
						Image = "rbxassetid://5617855826",
						Text = "We just detected a surge of Jukumai necromantic magic on the other side of that door. Whatever's beyond it is sure to put up a fight. Prepare accordingly!",
					}
				}
			},
		},
		[8] = {
			Name = "Deep Crypt",
			Type = "Granular",
			Args = {
				Theme = "Crypt",
				ChunkMap = {
					"  V<  ",
					" >|<-V",
					">-#--<",
					" >|<-^",
					"  ^<  ",
				},
				StartRoomChunkPosition = Vector2.new(6, 3),
				CustomGenerateRooms = function(self)
					local chunkPosition = self.StartRoomChunkPosition
					
					self:ResetChunk(chunkPosition)
					
					local chunkSize = self.ChunkSize - self.ChunkPadding
					local roomSize = self:MapVector2(chunkSize / 2, math.floor)
					local roomPosition = self:MapVector2(chunkSize / 2 - roomSize / 2, math.floor)
					
					local pattern, size, position = self.ThemeMachine:CreateCircularRoom(roomSize.X, chunkPosition * self.ChunkSize + roomPosition)
					
					-- mining camp in the center
					local left = self:MapVector2(roomSize * Vector2.new(0.5, 0.66), math.floor)
					pattern[left.X][left.Y].FloorItems = {
						"ResurrectionPreventer",
					}
					local right = self:MapVector2(roomSize * Vector2.new(0.5, 0.33), math.floor)
					pattern[right.X][right.Y].FloorItems = {
						"ResurrectionPreventer",
					}
					local center = self:MapVector2(roomSize * Vector2.new(0.33, 0.5), math.floor)
					pattern[center.X][center.Y].FloorItems = {
						"ResurrectionPreventer",
					}
					
					-- no other features in this room
					for x, row in pairs(pattern) do
						for y, cell in pairs(row) do
							cell.NoFeatures = true
						end
					end
					
					self:ApplyPattern(pattern, size, position)
				end
			},
			Modifiers = {
				"UndeadResurrection",
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Adrasta van Linorei",
						Image = "rbxassetid://5617855826",
						Text = "The Jukumai necromancer is projecting an overwhelming amount of energy into this area. Enemies killed will resurrect unless they're within the fields emitted by these worldstone devices. They'll only work while carried, so you'll have to work together.",
					}
				}
			},
		},
		[9] = {
			Name = "Exhumed Mass Grave",
			Type = "Custom",
			Args = {DungeonId = "boneSpiderBossDungeon"},
		},
		[10] = {
			Name = "Immemorial Grave",
			Type = "Granular",
			Args = {
				Theme = "Crypt",
				ChunkMap = {
					">V  ",
					">^ V",
					"|<--",
					">V ^",
					">^  ",
				},
				StartRoomChunkPosition = Vector2.new(4, 3),
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Adrasta van Linorei",
						Image = "rbxassetid://5617855826",
						Text = "We're drawing ever closer. Our detection artifices almost can't handle the amount of energy that the necromancer is emitting... was it a mistake to come here? No, we must do this! Onward, slayers!",
					}
				},
				
				OnFinished = {
					Dialogue = {
						Name = "Jukumai Necromancer",
						Image = "rbxassetid://5726449422",
						Text = "So, you've finally come? My brothers and sisters warned me that I was causing too much trouble. But I cannot stop, now. The secrets are so very close. Interrupt me at your own peril. You've been warned.",
					},
					Pause = 10,
				}
			},
		},
		[11] = {
			Name = "The First Burial",
			Type = "Custom",
			Args = {DungeonId = "jukumaiBossDungeon"},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Jukumai Necromancer",
						Image = "rbxassetid://5726449422",
						Text = "You have tried my patience for the last time, \"slayers.\" You will not stop me. You will not prevent me from saving everyone!",
					},
				},
				
				OnFinished = {
					Dialogue = {
						Name = "Adrasta van Linorei",
						Image = "rbxassetid://5617855826",
						Text = "He's defeated! Well done, slayers! As for killing him... well, not a slayer alive knows how to do that. We'll make sure he's secured back at headquarters. Excellent work, slayers! We've done a great deed today.",
					},
					Pause = 10,
				}
			}
		}
	}
}