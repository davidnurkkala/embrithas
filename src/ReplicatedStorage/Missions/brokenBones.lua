return {
	Name = "Broken Bones",
	Description = "A Slayer scout has reported a never-before-seen Undead with her dying breath.",
	Level = 21,
	PartySize = 6,
	
	MissionType = "Story Mission",
	MissionGroup = "Undead",
	
	Requirements = {
		{Type = "Mission", Id = "hauntedForest"},
	},
	
	MapPosition = Vector3.new(-30.2501259, 5.19336414, -134.064087),
	
	Rewards = {
		{Type = "Weapon", Id = 19, Chance = 1/3},
		{Type = "Trinket", Id = 6, Chance = 1/4},
		{Type = "Material", Id = 2, Chance = 1},
		{Type = "Material", Id = 10, Chance = 1/2},
		{Type = "Alignment", Faction = "League", Amount = 1, Reason = "you slay a terrifying foe!"},
		{Type = "Alignment", Faction = "Order", Amount = 1, Reason = "you cleanse the world of a vile undead aberration."},
	},
	
	FirstTimeRewards = {
		{Type = "Material", Id = 2, Amount = 10},
	},
	
	Enemies = {
		["Skeleton"] = 7,
		["Skeleton Warrior"] = 4,
		["Bone Archer"] = 4,
		["Zombie"] = 1,
		["Skeleton Berserker"] = 1,
	},
	
	Floors = {
		[1] = {
			Name = "Morbid Dell",
			Type = "Granular",
			Args = {
				Theme = "Forest",
				ChunkMap = {
					">-V",
					">V|",
					" ><",
				},
				StartRoomChunkPosition = Vector2.new(1, 1),
			},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "One of our scouts just died reporting what she lost her team to. A giant undead creature. It's time for vengeance, slayers!",
					}
				}
			},
		},
		[2] = {
			Name = "Putrid Tunnels",
			Type = "Basic",
			Args = {
				TileSetName = "Mineshaft",
				GridMap = {
					">-V  ",
					"  ^-<",
				},
				StartRoomGridPosition = Vector2.new(1, 1),
			},
			
			Encounters = {
				{Type = "Multi", Encounters = {
					{Type = "Elite", Enemy = "Skeleton"},
					{Type = "Elite", Enemy = "Skeleton"},
					{Type = "Elite", Enemy = "Skeleton"},
				}}
			}
		},
		[3] = {
			Name = "Acrid Chamber",
			Type = "Custom",
			Args = {DungeonId = "skeletonBossDungeon"},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Drillmaster Leon",
						Image = "rbxassetid://5617833593",
						Text = "Steel yourselves, slayers! Show no mercy. Everything through that door has seen death once, and will see it again!",
					}
				}
			},
		}
	}
}