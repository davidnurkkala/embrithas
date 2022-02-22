return {
	Type = "RunGreatGlacier",
	
	Name = "Into The Great Glacier",
	Description = "Since you helped the Evrig with their undead infestation, a revered holy site of theirs -- the Great Glacier -- and its bounty of Bluesteel is yours.",
	Level = 45,
	PartySize = 6,
	
	MissionType = "Expedition",
	MissionGroup = "MaterialExpeditions",
	
	Requirements = {
		{Type = "Mission", Id = "chillOfDeath"},
	},
	
	MapPosition = Vector3.new(-38.1129379, 5.19336414, -147.126312),
	
	Rewards = {},
	
	Cost = {
		Gold = 4000,
	},
	
	Floors = {
		[1] = {
			Name = "Great Glacier Shores",
			
			Type = "Granular",
			Args = {SizeInChunks = Vector2.new(2, 3), Theme = "Snow"},
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Raid-captain Frostmeyer",
						Image = "rbxassetid://5666198915",
						Text = "So you've the guts to claim Bluesteel from the glacier? We'll see. Destroy any undead you find on your way to the ice caverns.",
					}
				}
			}
		},
		
		[2] = {
			FloorItemSets = {
				Bluesteel = {
					BluesteelOre = {1, 1},
				}
			},
			FloorItemSetWeights = {
				Bluesteel = 1,
			},
			
			Name = "Great Glacier Interior",
			
			Events = {
				OnStarted = {
					Dialogue = {
						Name = "Raid-captain Frostmeyer",
						Image = "rbxassetid://5666198915",
						Text = "The glacier has a great bounty of Bluesteel, but beware her bite. Remain within the warmth of this torch or die. One of you will have to carry it with you.",
					}
				}
			}
		},
	}
}