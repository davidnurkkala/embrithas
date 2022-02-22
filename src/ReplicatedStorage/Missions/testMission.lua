local override-- = script.Parent.aShockingDevelopment
if override then
	local id = override.Name
	override = require(override)
	override.MissionId = id
	override.Difficulty = "Rookie"
	return override
end

local bossFight = {
	Name = "BOSS FIGHT",
	Type = "Custom",
	Args = {DungeonId = "corruptedCrater1"},
	Modifiers = {"Thunderstorm"},
}

local customFloor = {
	Name = "BOSS FIGHT",
	Type = "Custom",
	Args = {DungeonId = "bless"},
}

local normalFloor = {
	Name = "TEST DUNGEON",
	Type = "Granular2",
	Args = {
		RoomCount = 10,
		Theme = "Castle",
	},
}

local tutorial = {
	Name = "TUT",
	Type = "Tutorial",
}

local beegFloor = {
	Name = "BEEG DUNGEON",
	Type = "Granular",
	Args = {SizeInChunks = Vector2.new(3, 3), Theme = "Glacier"},
}

local basicFloor = {
	Name = "Dungeon",
	Type = "Basic",
	Args = {
		TileSetName = "Mineshaft",
		Size = Vector2.new(12, 12)
	},
}

local basicFloor2 = {
	Name = "Dungeon",
	Type = "Basic",
	Args = {
		TileSetName = "Mineshaft",
		GridMap = {
			">--<",
			"|   ",
			">--<",
			"|   ",
			"^   ",
		},
		StartRoomGridPosition = Vector2.new(1, 1),
	},
}

local encountersFloor = {
	Name = "ENCOUNTERS?",
	Type = "Basic",
	Args = {Size = Vector2.new(2, 2)},
	
	Encounters = {
		{Type = "Elite", Enemy = "Skeleton Warrior", LevelDelta = 10},
		{Type = "Mob", Enemy = "Orc Sapper", Count = 16, LevelDelta = -4},
		{Type = "Multi", Encounters = {
			{Type = "Elite", Enemy = "Orc Bulwark", LevelDelta = 10},
			{Type = "Mob", Enemy = "Orc Archer", Count = 8, LevelDelta = -10},
		}}
	}
}

local smallFloor = {
	Name = "YEET",
	Type = "Granular",
	Args = {SizeInChunks = Vector2.new(1, 2), Theme = "Test"},
}

local debugFloor = {
	Name = "Sheltered Clearing",
	Type = "Granular",
	Args = {SizeInChunks = Vector2.new(3, 2), Theme = "Forest"},
}

local lobby = {
	Name = "Slayer Headquarters",
	Type = "Lobby",
	Args = {}
}

return {
	MaxPlayerLevel = 75,
	Hidden = true,
	
	Name = "Test Mission",
	Description = "You shouldn't be able to see this.",
	Level = 100,
	PartySize = 6,
	
	StartingLifeCount = 3,
	
	MapPosition = Vector3.new(69, 9001, 420),
	
	MissionId = "testMission",
	
	Enemies = {
		["Orc"] = 1,
	},
	
	--FloorItemSets = {
	--	Gas = {
	--		TrapGas = {1, 8},
	--	}
	--},
	--FloorItemSetWeights = {
	--	Gas = 1,
	--},
	
	Floors = {
		[1] = lobby,
	},
	
	Rewards = {
		{Type = "Material", Id = 10, Amount = 69, Chance = 1/4},
		{Type = "Trinket", Id = 1, Chance = 1}
	},
}