return {
	Type = "RunBlastFurnace",
	
	Name = "Volcanic Blast Furnace",
	Description = "Make use of the College's experimental blast furnace to transform iron into steel. [You must bring iron into this mission.] [This mission is not possible to undertake alone.]",
	Level = 45,
	PartySize = 6,
	
	MissionType = "Expedition",
	MissionGroup = "MaterialExpeditions",
	
	Requirements = {
		{Type = "Alignment", Faction = "College", Amount = 25},
		{Type = "Mission", Id = "aFireBelow"},
	},
	
	MapPosition = Vector3.new(-29.3565254, 5.19336414, -134.994064),
	
	Rewards = {},
	
	Cost = {
		Gold = 6000,
	},

	FloorItemSets = {
		LavaCores = {
			LavaCore = {1, 1},
		}
	},
	FloorItemSetWeights = {
		LavaCores = 1,
	},
	
	Floors = {
		[1] = {
			Name = "Volcanic Cave",
			Type = "Granular",
			Args = {SizeInChunks = Vector2.new(5, 5), Theme = "MagmaCave"},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Faris",
						Image = "rbxassetid://5706733990",
						Text = "Welcome, slayers. To power the blast furnace, you must retrieve lava cores. They will burn you without my heat shield spell, which I can only hold on one person at a time. Whoever wants it, step up to me.",
					}
				}
			}
		},
	}
}