_G.AddItem = function(category, data)
	require(game.ReplicatedStorage.Class.InventoryService):AddItem(game.Players:GetPlayers()[1], category, data)
end
_G.Next = function()
	require(game.ReplicatedStorage.Class.GameService).CurrentRun.Dungeon.Completed:Fire()
end
_G.RemovePurchase = function(productId)
	local p = require(game.ReplicatedStorage.Class.DataService):GetPlayerPurchases(game.Players:GetPlayers()[1]).Products
	table.remove(p, table.find(p, productId))
end
_G.IWon = function(missionId)
	require(game.ReplicatedStorage.Class.DataService):UpdatePlayerMissionLog(game.Players:GetPlayers()[1], {Type = "Victory", Difficulty = "Rookie", MissionId = missionId, Time = 69420})
end
_G.Exp = function(exp)
	require(game.ReplicatedStorage.Class.LevelService):AddExperience(game.Players:GetPlayers()[1], exp)
end
_G.TestLevelUp = function()
	local legend = require(game.ReplicatedStorage.Class):GetClass("Legend").GetLegendFromPlayer(game.Players:GetPlayers()[1])
	legend:GetService("EffectsService"):RequestEffectAll("LevelUp", {Root = legend.Root})
end
_G.Gold = function(amount)
	require(game.ReplicatedStorage.Class.InventoryService):AddGold(game.Players:GetPlayers()[1], amount)
end
_G.AddQuest = function(questData)
	local questService = require(game.ReplicatedStorage.Class.QuestService)
	local quest = require(game.ReplicatedStorage.Class.Quest)
	
	questService:AddQuestToPlayer(game.Players:GetPlayers()[1], quest:CreateFromData(questData))
end
_G.ClearQuests = function()
	local questService = require(game.ReplicatedStorage.Class.QuestService)
	questService:ClearPlayerQuests(game.Players:GetPlayers()[1])
end