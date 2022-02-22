local Players = game:GetService("Players")

local Super = require(script.Parent)
local PlayerListService = Super:Extend()

local ItemData = require(Super.Storage.ItemData)

function PlayerListService:OnCreated()
	self.Legend = self:GetClass("Legend")
	self.InventoryService = self:GetService("InventoryService")
	self.LogService = self:GetService("LogService")
	
	spawn(function()
		while true do
			self:OnUpdated(wait(0.2))
		end
	end)
end

function PlayerListService:GetLegendWeaponIcon(legend)
	local inventory = self.InventoryService:GetInventory(legend.Player)
	if not inventory then return "" end
	
	local slotData = inventory.Weapons[inventory.EquippedWeaponIndex]
	if not slotData then return "" end
	
	local itemData = ItemData.Weapons[slotData.Id]
	if not itemData then return "" end
	
	return itemData.Image or ""
end

function PlayerListService:GetPlayerDeaths(player)
	return self.LogService.DeathCountByPlayer[player] or 0
end

function PlayerListService:OnUpdated(dt)
	local infoById = {}
	
	for _, player in pairs(Players:GetPlayers()) do
		local legend = self.Legend.GetLegendFromPlayer(player)
		if legend then
			infoById[player.UserId] = {
				Name = player.Name,
				Level = legend.Level or 0,
				Deaths = self:GetPlayerDeaths(player),
				Icon = self:GetLegendWeaponIcon(legend),
				HealthRatio = math.clamp(legend.Health / legend.MaxHealth:Get(), 0, 1)
			}
		else
			infoById[player.UserId] = {
				Name = player.Name,
				Level = "DEAD",
				Deaths = self:GetPlayerDeaths(player),
				Icon = "",
				HealthRatio = 0,
			}
		end
	end
	
	self:FireRemoteAll("PlayerListUpdated", infoById)
end

local Singleton = PlayerListService:Create()
return Singleton