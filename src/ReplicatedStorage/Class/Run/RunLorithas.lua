local Super = require(script.Parent)
local RunLorithas = Super:Extend()

RunLorithas.InfiniteData = {
	Dungeons = {
		{Type = "Basic", TileSetName = "Castle"},
		{Type = "Basic", TileSetName = "Sewer"},
		{Type = "Basic", TileSetName = "Mineshaft"},
		{Type = "Granular", Theme = "Lab"},
		{Type = "Granular", Theme = "FrozenCastle"},
		{Type = "Granular", Theme = "MagmaCave"},
		{Type = "Granular", Theme = "Crypt"},
		{Type = "Granular", Theme = "Swamp"},
	},
	MinSize = Vector2.new(1, 2),
	MaxSize = Vector2.new(2, 4),
	Enemies = {
		{"Orc", 1},
		{"Skeleton", 1},
		{"Orc Archer", 1},
		{"Bone Archer", 1},
		{"Mystic Shadow", 1},
		{"Orc Bulwark", 1},
		{"Orc Miner", 30},
		{"Orc Sapper", 30},
		{"Orc Shaman", 40},
		{"Skeleton Warrior", 40},
		{"Shadow Assassin", 40},
		{"Armored Shadow", 50},
		{"Raging Shadow", 50},
		{"Shadow Warrior", 50},
		{"Orc Brute", 50},
		{"Orc Berserker", 50},
		{"Zombie", 50},
		{"Ghost", 50},
		{"Skeleton Berserker", 60},
		{"Orc Lieutenant", 70},
		{"Zombie Defender", 100},
		{"Null", 100},
		{"Immortal Shadow", 100},
		{"Orc Aegis", 100},
		{"Orc Pistoleer", 100},
		{"Orc Grenadier", 100},
	},

	BossFights = {
		{"Orc", 1},
		{"Golem", 25},
		{"Skeleton", 50},
		{"ForgottenShadows", 75},
		{"ForsakenShadows", 75},
		{"LostChampion", 100},
	},
}

RunLorithas.BossFightFrequency = 5

function RunLorithas:OnCreated()
	self.Floor = self.RunData.MaxPlayerLevel or 1
	self.FloorsCleared = 0

	Super.OnCreated(self)
end

function RunLorithas:NewRegularDungeon()
	math.randomseed(tick())
	
	local dungeons = self.InfiniteData.Dungeons
	local dungeon = dungeons[math.random(1, #dungeons)]
	local sizeX = math.random(self.InfiniteData.MinSize.X, self.InfiniteData.MaxSize.X)
	local sizeY = math.random(self.InfiniteData.MinSize.Y, self.InfiniteData.MaxSize.Y)
	local size = Vector2.new(sizeX, sizeY)
	
	local args = {
		Run = self,
		Level = self.Floor,
		SizeInChunks = size,
		GoldEnabled = (self.FloorsCleared > 1),
		ChestChance = 1 / 16,
	}
	
	if dungeon.Type == "Granular" then
		args.Theme = dungeon.Theme
		self.Dungeon = self:CreateNew"DungeonGranular"(args)
		
	elseif dungeon.Type == "Basic" then
		args.TileSetName = dungeon.TileSetName
		self.Dungeon = self:CreateNew"DungeonBasic"(args)
	end

	self:StartDungeon()
end

function RunLorithas:OnDungeonCompleted()
	if self.State ~= "Running" then return end

	if self:IsBossFloor() then
		local players = game:GetService("Players"):GetPlayers()
		for _, player in pairs(players) do
			local amount = self.Floor * 25

			local difficulty = self.Run:GetDifficultyData()
			if difficulty.LootChance then
				amount = math.ceil(amount * difficulty.LootChance)
			end

			self:GetService("InventoryService"):AddGold(player, amount)
			self:FireRemote("NotificationRequested", player, {
				Title = "Gold acquired!",
				Content = amount,
				Image = "rbxassetid://5272914329",
			})
		end
	end

	Super.OnDungeonCompleted(self)
end

function RunLorithas:NewBossDungeon()
	math.randomseed(tick())

	local bossFights = {}
	for _, bossFight in pairs(self.InfiniteData.BossFights) do
		if bossFight[2] <= self.Floor then
			table.insert(bossFights, bossFight[1])
		end
	end
	local bossFight = bossFights[math.random(1, #bossFights)]

	self.Dungeon = self:CreateNew"DungeonCustom"{
		DungeonId = "lorithas"..bossFight.."BossDungeon",
		Level = self.Floor,
	}

	self:StartDungeon()
end

function RunLorithas:IsBossFloor()
	return self.FloorsCleared % 5 == 0
end

function RunLorithas:NewDungeon()
	self.FloorsCleared = self.FloorsCleared + 1

	if self:IsBossFloor() then
		self:NewBossDungeon()
	else
		self:NewRegularDungeon()
	end
end

function RunLorithas:RequestEnemy()
	local enemies = self.InfiniteData.Enemies
	local enemy
	repeat
		enemy = enemies[math.random(1, #enemies)]
	until enemy[2] <= self.Floor
	return enemy[1]
end

function RunLorithas:CheckForVictory()
	return false
end

return RunLorithas