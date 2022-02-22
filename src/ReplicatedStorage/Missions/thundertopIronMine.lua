return {
	Type = "RunThundertopIronMine",
	
	Name = "Thundertop Iron Mine",
	Description = "The Jolians, grateful to the Alliance for the help at New Grahst, have permitted the slayers to come to Thundertop Iron Mine to gather materials.",
	Level = 30,
	PartySize = 6,
	
	MissionType = "Expedition",
	MissionGroup = "MaterialExpeditions",
	
	Requirements = {
		{Type = "Mission", Id = "suddenIncursion"},
	},
	
	MapPosition = Vector3.new(-37.3595772, 5.19336414, -136.673462),
	
	Rewards = {},
	
	Cost = {
		Gold = 2000,
	},
	
	FloorItemSets = {
		Iron = {
			IronOreRock = {1, 4},
		}
	},
	FloorItemSetWeights = {
		Iron = 1,
	},
	
	Floors = {
		[1] = {
			Name = "Thundertop Iron Mine",
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Jolian Miner",
						Image = "rbxassetid://5625183248",
						Text = "Right, slayers. Y' here for iron, yeah? Find ore stones out in the pits and bring 'em back. Be careful, though. That much conductive stuff tends to attract the lightnin'.",
					}
				}
			}
		},
	}
}