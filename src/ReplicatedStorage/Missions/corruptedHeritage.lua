return {
	Name = "Corrupted Heritage",
	Description = "The incursion beneath Neiss has spread corruption to an important heritage site. [This mission is difficult and optional.]",
	Level = 35,
	PartySize = 6,
	
	MissionType = "Story Mission",
	MissionGroup = "Orc",
	
	Requirements = {
		{Type = "Mission", Id = "tunnelingThreat"},
	},
	
	MapPosition = Vector3.new(-37.5914192, 5.19336414, -142.948456),
	
	Rewards = {
		{Type = "Weapon", Id = 11, Chance = 1/2},
		{Type = "Ability", Id = 21, Chance = 1/6},
		{Type = "Material", Id = 8, Chance = 1/4},
		{Type = "Alignment", Faction = "College", Amount = -1, Reason = "the College is upset that such a powerful artifact is destroyed."},
		{Type = "Alignment", Faction = "Order", Amount = 1, Reason = "the Order is glad that such an imminent threat to Mortal life is removed."},
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 8, Amount = 15},
	},
	
	Enemies = {
		["Orc"] = 2,
		["Orc Bulwark"] = 1,
		["Orc Archer"] = 1,
		["Orc Brute"] = 1,
		["Orc Shaman"] = 1,
		["Orc Berserker"] = 1,
	},
	
	Floors = {
		[1] = {
			Name = "Neiss Sewers South",
			Type = "Basic",
			Args = {
				TileSetName = "Sewer",
				GridMap = {
					"V  ",
					"|  ",
					"|-<",
					"^  ",
				},
				StartRoomGridPosition = Vector2.new(3, 3),
			},
			
			Encounters = {
				{Type = "Lore", LoreId = "onGolems"}
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Geomancer Helia",
						Image = "rbxassetid://5617842027",
						Text = "Grave news, Slayers. The corruption spreading due to the orcs has infected one of our golems of old. If left unchecked, it could cause devasating earthquakes. We must reach it and pacify it!",
					}
				}
			},
		},
		[2] = {
			Name = "Orc Tunnel Network",
			Type = "Basic",
			Args = {
				TileSetName = "Mineshaft",
				GridMap = {
					">-V",
					" >^",
					">^ ",
				},
				StartRoomGridPosition = Vector2.new(1, 3),
			},
			
			Enemies = {
				["Orc"] = 4,
				["Orc Bulwark"] = 1,
				["Orc Archer"] = 2,
				["Orc Sapper"] = 2,
				["Orc Miner"] = 4,
			},
			
			Encounters = {
				{Type = "Elite", Enemy = "Orc Miner", LevelDelta = 10},
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Geomancer Helia",
						Image = "rbxassetid://5617842027",
						Text = "The orcs breached the ancient shrine through these tunnels. You can, too.",
					}
				}
			},
		},
		[3] = {
			Name = "Ancient Shrine",
			Type = "Custom",
			Args = {DungeonId = "golemBossDungeon"},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Geomancer Helia",
						Image = "rbxassetid://5617842027",
						Text = "The golem was once a precious artifact of my city. Now it is a tool for evil. While tragic, you mustn't hold back! Defeat it, Slayers! For Neiss!",
					}
				}
			},
		}
	}
}