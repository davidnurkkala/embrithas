local Super = require(script.Parent)
local LogService = Super:Extend()

local Players = game:GetService("Players")

function LogService:OnCreated()
	self:Reset()
end

function LogService:Reset()
	self.Log = {}
	self.DeathCountByPlayer = {}
end

function LogService:AddEvent(event)
	event.Time = tick()
	table.insert(self.Log, event)
	
	if event.Type == "legendDied" then
		local player = event.Legend.Player
		if player then
			self.DeathCountByPlayer[player] = (self.DeathCountByPlayer[player] or 0) + 1
		end
	end
end

function LogService:GetReviewData()
	local reviewData = {
		IconsByName = {},
		StatsByCategory = {},
	}
	local stats = reviewData.StatsByCategory
	
	local categories = {
		"Damage Dealt",
		"Damage Taken",
		"Deaths",
		"Monsters Slain",
		"Corruption Cleansed",
		"Healing Done",
		"Healing Received",
	}
	
	for _, category in pairs(categories) do
		stats[category] = {}
	end
	
	local players = Players:GetPlayers()
	for _, player in pairs(players) do
		local success, image = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size60x60)
		end)
		reviewData.IconsByName[player.Name] = success and image or ""
		
		for _, category in pairs(categories) do
			stats[category][player.Name] = 0
		end
	end
	
	for _, event in pairs(self.Log) do
		if event.Type == "damageDealt" then
			if event.Source:IsClass("Legend") and event.Target:IsClass("Enemy") then
				local cat = stats["Damage Dealt"]
				local name = event.Source.Player.Name
				cat[name] = (cat[name] or 0) + event.Amount
				
			elseif event.Source:IsClass("Enemy") and event.Target:IsClass("Legend") then
				local cat = stats["Damage Taken"]
				local name = event.Target.Player.Name
				cat[name] = (cat[name] or 0) + event.Amount
			end
			
		elseif event.Type == "healed" then
			if event.Source:IsClass("Legend") then
				local cat = stats["Healing Done"]
				local name = event.Source.Player.Name
				cat[name] = (cat[name] or 0) + event.Amount
			end
			
			if event.Target:IsClass("Legend") then
				local cat = stats["Healing Received"]
				local name = event.Target.Player.Name
				cat[name] = (cat[name] or 0) + event.Amount
			end
			
		elseif event.Type == "pointsAcquired" then
			local cat = stats["Corruption Cleansed"]
			local name = event.Player.Name
			cat[name] = (cat[name] or 0) + event.Amount
			
		elseif event.Type == "legendDied" and event.Legend.Player.Parent then
			local cat = stats["Deaths"]
			local name = event.Legend.Player.Name
			cat[name] = (cat[name] or 0) + 1
		
		elseif event.Type == "enemyDied" and event.Killer:IsClass("Legend") and event.Killer.Player.Parent then
			local cat = stats["Monsters Slain"]
			local name = event.Killer.Player.Name
			cat[name] = (cat[name] or 0) + 1
		end
	end
	
	return reviewData
end

local Singleton = LogService:Create()
return Singleton