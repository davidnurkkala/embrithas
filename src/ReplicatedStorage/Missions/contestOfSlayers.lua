return {
	Type = "RunContest",
	
	Name = "Contest of Slayers",
	Description = "This description will not be shown.",
	Level = 100,
	PartySize = 8,
	
	StartingLifeCount = 10,
	
	MapPosition = Vector3.new(0, 0, 0),
	
	MissionId = "testMission",
	
	Enemies = {},
	Rewards = {},
	
	Floors = {
		[1] = {
			Name = "The Great Arch",
			Type = "Custom",
			Args = {DungeonId = "contestOfSlayers"},
		},
	},
}