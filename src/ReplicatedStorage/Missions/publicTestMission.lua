return {
	Hidden = true,
	
	Name = "Public Test Mission",
	Description = "[This is open for a limited time so you can help the developer test the game.]",
	Level = 5,
	PartySize = 20,
	StartingLifeCount = 50,
	
	MapPosition = Vector3.new(0, 0, 0),
	
	Rewards = {
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
			Name = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
			Type = "Custom",
			Args = {DungeonId = "orcShamanBossDungeon"},
		},
	}
}