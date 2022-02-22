return {
	Name = "Raid: Worst Case Scenario",
	Description = "The Alliance has confirmed that a mortal is supplying the orcs with weapons and technology. Defeat and apprehend this individual at all costs. [This mission is a raid and is recommended for a party of 20.]",
	LockedDescription = "Put an end to the Orc incursion... Complete this mission's requirements to reveal more details.",
	Level = 90,
	PartySize = 20,
	
	MissionType = "Raid",
	MissionGroup = "Orc",
	
	StartingLifeCount = 10,
	LifeType = "Raid",
	
	MapPosition = Vector3.new(-37.2144547, 5.19336414, -138.141876),
	
	Requirements = {
		{Type = "Mission", Id = "depthsOfBetrayal"},
	},
	
	RewardsRolledSeperately = true,
	Rewards = {
		{Type = "Weapon", Id = 58, Chance = 1/3},
		{Type = "Weapon", Id = 46, Chance = 1/3},
		{Type = "Weapon", Id = 59, Chance = 1/3},
		
		{Type = "Material", Id = 2, Amount = 15, Chance = 1},
		{Type = "Material", Id = 10, Amount = 10, Chance = 1},
		{Type = "Material", Id = 8, Amount = 10, Chance = 1},
		{Type = "Material", Id = 1, Amount = 30, Chance = 1},
		
		{Type = "Alignment", Faction = "League", Amount = -9},
		{Type = "Alignment", Faction = "College", Amount = 9},
		{Type = "Alignment", Faction = "Order", Amount = 9},
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 2, Amount = 50},
		{Type = "Material", Id = 10, Amount = 50},
	},
	
	Enemies = {
		["Orc"] = 6,
		["Orc Miner"] = 2,
		["Orc Sapper"] = 2,
		["Orc Archer"] = 2,
		["Orc Bulwark"] = 6,
		["Orc Shaman"] = 6,
		["Orc Aegis"] = 4,
		["Orc Grenadier"] = 4,
		["Orc Pistoleer"] = 4,
		["Orc Lieutenant"] = 2,
	},
	
	Floors = {
		[1] = {
			Name = "Siege",
			Type = "Custom",
			Args = {DungeonId = "worstCaseSiege"},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "Slayers, you know why we're here. Within this fortress is a mortal who has betrayed all of his kind. Protect the cannons while we pound through the walls. We're finishing this today.",
					}
				},
				OnFinished = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "Well done. They've given up the countersiege and are returning to the fortress. We've punched through. Prepare to rush the palisade -- initial reports indicate a powerful orc mage is waiting for us.",
					},
					Pause = 5,
				}
			},
		},
		[2] = {
			Name = "Palisade Rush",
			Type = "Custom",
			Args = {DungeonId = "worstCaseShamanBoss"},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "Hold nothing back, slayers. These monsters don't know mercy.",
					}
				},
				OnFinished = {
					Dialogue = {
						Name = "???",
						Image = "rbxassetid://5617843718",
						Text = "Your senseless murder of these creatures' religious leader shows you as what you are, slayers. Lackeys of that godless empire in the west. Proceed if you must, but know the Goddess will surely side with me in the end.",
					},
					Pause = 10,
				}
			}
		},
		[3] = {
			Name = "Fortress Entrance Tunnels",
			Type = "Basic",
			Args = {
				TileSetName = "Mineshaft",
				GridMap = {
					"   V  ",
					" >-|< ",
					"   |  ",
					" V>|-<",
					" ^-^-<",
				},
				StartRoomGridPosition = Vector2.new(4, 1),
			},
			
			FloorItemSets = {
				Bombs = {
					TrapBomb = {6, 12},
				}
			},
			FloorItemSetWeights = {
				Bombs = 1,
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "???",
						Image = "rbxassetid://5617843718",
						Text = "You must be familiar with weapons of those godless Jolians, yes? Being their minions? Well, I've left many of them for you to find. Be sure to examine them closely...",
					}
				},
				OnFinished = {
					Dialogue = {
						Name = "???",
						Image = "rbxassetid://5617843718",
						Text = "You survived? I should have known that the forces of evil would be tenacious. Very well, then. I will close the way to you.",
					},
					Pause = 5,
				}
			}
		},
		[4] = {
			Name = "Unstable Tunnel",
			Type = "Basic",
			Args = {
				TileSetName = "Mineshaft",
				Size = Vector2.new(10, 1),
				StartRoomGridPosition = Vector2.new(1, 1),
			},
			
			FloorItemSets = {
				FallingRocks = {
					TrapFallingRocks = {5, 10},
				},
			},
			FloorItemSetWeights = {
				FallingRocks = 1,
			},
			
			Modifiers = {
				{Class = "Timed", Args = {Time = 60 * 3}},
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "They're caving in this tunnel on us! Hurry through before we're buried alive!",
					}
				},
				OnFinished = {
					Dialogue = {
						Name = "???",
						Image = "rbxassetid://5617843718",
						Text = "May the Goddess curse you. How can you fight for them, who stole everything from us? Very well... I will unleash my magnum opus: a warrior born of they who so desecrated our lands.",
					},
					Pause = 10,
				},
			}
		},
		[5] = {
			Name = "Pit of Industry",
			Type = "Custom",
			Args = {DungeonId = "worstCaseJuggernautBoss"},
			
			Events = {
				OnFinished = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "By the Distant Goddess... that was rough. We can't let orcs like that escape this fortress. Slayers! Charge ahead!",
					}
				},
				Pause = 5,
			},
		},
		[6] = {
			Name = "Experimental Lab",
			Type = "Granular",
			Args = {
				Theme = "Lab",
				ChunkMap = {
					"V---V",
					"|V^>|",
					"^---^",
					"  ^  ",
				},
				StartRoomChunkPosition = Vector2.new(3, 4),
			},
			
			FloorItemSets = {
				Gas = {
					TrapGas = {5, 10},
				},
			},
			FloorItemSetWeights = {
				Gas = 1,
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "Who knows what kind of vile experiments took place, here. Ransack it, slayers. Nothing should remain of this forbidden knowledge.",
					}
				},
				OnFinished = {
					Dialogue = {
						Name = "Erisai, Tribal Kakastan",
						Image = "rbxassetid://5925226345",
						Text = "You have ruined everything. There will be no justice in this. Only senseless slaughter. The Jolians could have borne the massacre of these creatures, but you chose to spare them. Why? Kakasta shouldn't have to suffer!",
					},
					Pause = 10,
				}
			}
		},
		[7] = {
			Name = "Traitor's Throne",
			Type = "Custom",
			Args = {DungeonId = "worstCaseChieftanBoss"},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Erisai, Tribal Kakastan",
						Image = "rbxassetid://5925226345",
						Text = "You have ensured the death of my people's way of life. Take pride in this, slayers. You've killed more than these monsters ever could.",
					},
				},
				OnFinished = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "Apprehend that Kakastan, slayers. We'll turn him over to his rulers and let them serve their own justice for this terrible thing he has done.",
					},
					Pause = 10,
				}
			}
		}
	}
}