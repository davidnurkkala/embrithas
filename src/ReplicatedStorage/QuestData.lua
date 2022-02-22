local quests = {
	introQuest1 = {
		Name = "Not My Grave",
		Goals = {
			{Type = "StartMission", MissionId = "rookiesGrave"},
			{Type = "CompleteMission", MissionId = "rookiesGrave"},
		},
		Rewards = {
			{Type = "Gold", Amount = 2500},
			{Type = "Quest", QuestId = "introQuest2"}
		}
	},
	
	introQuest2 = {
		Name = "Orc Problems",
		Goals = {
			{Type = "StartMission", MissionId = "towerAtKastakar"},
			{Type = "CompleteMission", MissionId = "towerAtKastakar"},
		},
		Rewards = {
			{Type = "Item", Category = "Materials", Data = {Id = 1, Amount = 10}},
			{Type = "Item", Category = "Materials", Data = {Id = 6, Amount = 10}},
			{Type = "Quest", QuestId = "introQuest3"},
		}
	},
	
	introQuest3 = {
		Name = "A Bone to Pick",
		Goals = {
			{Type = "StartMission", MissionId = "aGraveIssue"},
			{Type = "CompleteMission", MissionId = "aGraveIssue"},
		},
		Rewards = {
			{Type = "Item", Category = "Materials", Data = {Id = 2, Amount = 10}},
			{Type = "Quest", QuestId = "introQuest4"},
		},
	},
	
	introQuest4 = {
		Name = "Into the Dark Forest",
		Goals = {
			{Type = "StartMission", MissionId = "hauntedForest"},
			{Type = "CompleteMission", MissionId = "hauntedForest"},
		},
		Rewards = {
			{Type = "Item", Category = "Materials", Data = {Id = 6, Amount = 10}},
			{Type = "Gold", Amount = 5000},
			{Type = "Quest", QuestId = "introQuest5"},
		},
	},
	
	introQuest5 = {
		Name = "Orcs Underfoot",
		Goals = {
			{Type = "StartMission", MissionId = "tunnelingThreat"},
			{Type = "CompleteMission", MissionId = "tunnelingThreat"},
		},
		Rewards = {
			{Type = "Item", Category = "Materials", Data = {Id = 8, Amount = 5}},
			{Type = "Quest", QuestId = "introQuest6"},
		},
	},
	
	introQuest6 = {
		Name = "I've Got the Magic",
		Goals = {
			{Type = "StartMission", MissionId = "lessonsInTheArcaneI"},
			{Type = "CompleteMission", MissionId = "lessonsInTheArcaneI"},
		},
		Rewards = {
			{Type = "Item", Category = "Materials", Data = {Id = 10, Amount = 25}},
			{Type = "Quest", QuestId = "introQuest7"},
		},
	},
	
	introQuest7 = {
		Name = "Get Me a Gun",
		Goals = {
			{Type = "StartMission", MissionId = "suddenIncursion"},
			{Type = "CompleteMission", MissionId = "suddenIncursion"},
		},
		Rewards = {
			{Type = "Item", Category = "Materials", Data = {Id = 2, Amount = 10}},
			{Type = "Quest", QuestId = "introQuest8"},
		},
	},
	
	introQuest8 = {
		Name = "He's Just Big-boned",
		Goals = {
			{Type = "StartMission", MissionId = "brokenBones"},
			{Type = "CompleteMission", MissionId = "brokenBones"},
		},
		Rewards = {
			{Type = "Item", Category = "Materials", Data = {Id = 6, Amount = 25}},
			{Type = "Gold", Amount = 5000},
			{Type = "Quest", QuestId = "introQuest9"},
		},
	},
	
	introQuest9 = {
		Name = "How Low Can You Go?",
		Goals = {
			{Type = "StartMission", MissionId = "lorithasExpedition"},
		},
		Rewards = {
			{Type = "Gold", Amount = 1000},
		},
	},
	
	rangerQuest1 = {
		Name = "Ranger Basics",
		Goals = {
			{Type = "KillWithProjectile", CountMax = 100},
		},
		Rewards = {
			{Type = "Item", Category = "Abilities", Data = {Id = 17}},
			{Type = "Quest", QuestId = "rangerQuest2"},
		},
	},
	
	rangerQuest2 = {
		Name = "Bouncing Around",
		Goals = {
			{Type = "KillWithProjectile", CountMax = 25},
			{Type = "KillWithAbility", Id = 17, CountMax = 50},
		},
		Rewards = {
			{Type = "Item", Category = "Abilities", Data = {Id = 18}},
			{Type = "Quest", QuestId = "rangerQuest3"},
		},
	},
	
	rangerQuest3 = {
		Name = "Maximize Surface Area",
		Goals = {
			{Type = "KillWithProjectile", CountMax = 25},
			{Type = "KillWithAbility", Id = 17, CountMax = 25},
			{Type = "KillWithAbility", Id = 18, CountMax = 50},
		},
		Rewards = {
			{Type = "Item", Category = "Abilities", Data = {Id = 16}},
			{Type = "Quest", QuestId = "rangerQuest4"},
		},
	},
	
	rangerQuest4 = {
		Name = "Make It Rain",
		Goals = {
			{Type = "KillWithProjectile", CountMax = 25},
			{Type = "KillWithAbility", Id = 17, CountMax = 25},
			{Type = "KillWithAbility", Id = 18, CountMax = 25},
			{Type = "KillWithAbility", Id = 16, CountMax = 50},
		},
		Rewards = {
			{Type = "Item", Category = "Abilities", Data = {Id = 19}},
			{Type = "Quest", QuestId = "rangerQuest5"},
		},
	},
	
	rangerQuest5 = {
		Name = "This Is My Boomstick",
		Goals = {
			{Type = "KillWithProjectile", CountMax = 25},
			{Type = "KillWithAbility", Id = 17, CountMax = 25},
			{Type = "KillWithAbility", Id = 18, CountMax = 25},
			{Type = "KillWithAbility", Id = 16, CountMax = 25},
			{Type = "KillWithAbility", Id = 19, CountMax = 50},
		},
		Rewards = {
			{Type = "Item", Category = "Abilities", Data = {Id = 20}},
		},
	}
}

for id, quest in pairs(quests) do
	quest.Id = id
end

return quests