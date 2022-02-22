local player = game.Players.Davidii
local level = 25
for _, id in pairs{13} do
	require(game.ReplicatedStorage.Class.WorldObject.Character.HumanoidCharacter.PlayerCharacter.Legend).GetLegendFromPlayer(player):PromptAddItem("Weapons", {Id = id, Level = level})
end

local legend = require(game.ReplicatedStorage.Class.WorldObject.Character.HumanoidCharacter.PlayerCharacter.Legend).GetLegendFromPlayer(game.Players.Davidii)
legend:AddItem("Weapons", {Id = 7, Level = 50})
legend:AddGold(69420)
legend:AddItem("Materials", {Id = 10, Amount = 500})
for _ = 1, 5 do
	legend:AddItem("Weapons", {Id = 13, Level = math.random(1, 50)})
end


local inventory = legend.Inventory
for _ = 1, 5 do
	table.remove(inventory.Weapons, #inventory.Weapons)
end