local Super = require(script.Parent)
local PlayerGuideClient = Super:Extend()

PlayerGuideClient.ExpectingUpgrade = false

function PlayerGuideClient:OnCreated()
	self.Player = game:GetService("Players").LocalPlayer
	
	self.Gui = self.Player:WaitForChild("PlayerGui"):WaitForChild("Gui"):WaitForChild("PlayerGuideFrame")
	self.Gui:WaitForChild("ContentText")
	self.Gui:WaitForChild("ActionButton")
	self.Gui:WaitForChild("CloseButton")
	
	self:ConnectRemote("InventoryUpdated", self.OnInventoryUpdated, false)
	
	self.Gui.CloseButton.Activated:Connect(function()
		self.Gui.Visible = false
	end)
	
	self.Gui.ActionButton.Activated:Connect(function()
		if self.Action then
			self.Action()
		end
	end)
	
	--self:TryRecommendMission()
	
	local optionsClient = self:GetClass"OptionsClient"
	local options = optionsClient.Options or optionsClient.Updated:Wait()
	self.Gui.Visible = false--not options.DisablePlayerGuide
end

function PlayerGuideClient:OnInventoryUpdated()
	if self.ExpectingUpgrade then
		self:TryRecommendMission()
	end
end

function PlayerGuideClient:HasCompletedMission(missionId)
	local missionLog = self:GetService("LobbyClient").PlayerData.MissionLog
	for _, entry in pairs(missionLog) do
		if entry.MissionId == missionId then
			if entry.VictoryCount and entry.VictoryCount > 0 then
				return true
			end
		end
	end
	return false
end

function PlayerGuideClient:TryRecommendMission()
	local missionInfos = self.Storage.Remotes.GetMissionInfos:InvokeServer()
	
	local expeditions = {"lorithasExpedition", "intoTheGreatGlacier", "loggingExpedition", "thundertopIronMine", "volcanicBlastFurnace"}
	local count = 0
	local completedCount = 0
	
	local missionModule
	for _, info in pairs(missionInfos) do
		local id = info.Module.Name
		local isExpedition = (table.find(expeditions, id) ~= nil)
		local mission = require(info.Module)
		local isPaid = (mission.RequiredExpansion ~= nil)
		if (not isExpedition) and (not isPaid) then
			count += 1
			if self:HasCompletedMission(id) then
				completedCount += 1
				
			elseif #info.UnmetRequirements == 0 then
				missionModule = info.Module
				break
			end
		end
	end
	
	-- player has completed all available missions
	if count == completedCount then
		self.Gui.Visible = false
		return
	end
	
	if missionModule then
		self.ExpectingUpgrade = false
		
		self.Gui.Visible = true
		
		local mission = require(missionModule)
		self.Gui.ContentText.Text = string.format("You currently qualify for the mission \"%s,\" a mission you haven't completed yet. Click this button to find or start a party!", mission.Name)
		self.Gui.ActionButton.Text = "Play now!"
		self.Action = function()
			self.Gui.Visible = false
			self:FireRemote("PartyUpdated", "QuickPlayRequested", missionModule.Name)
		end
	else
		
	end
end

function PlayerGuideClient:CanUpgradeWeapon(slotData, inventory)
	local weaponService = self:GetService("WeaponService")
	local weaponData = weaponService:GetWeaponData(slotData)
	if not weaponData.UpgradeMaterials then return false end
	
	local upgradeData = weaponService:GetUpgradeData(slotData, inventory)
	for _, info in pairs(upgradeData) do
		if info.Held < info.Amount then
			return false
		end
	end
	return true
end

function PlayerGuideClient:TryRecommendUpgrade()
	self.ExpectingUpgrade = false
	
	local inventory = self:GetClass("InventoryClient").Inventory
	
	local bestSlotData, bestIndex
	local bestLevel = 0
	for index, slotData in pairs(inventory.Weapons) do
		if slotData.Level > bestLevel then
			bestSlotData = slotData
			bestIndex = index
			bestLevel = slotData.Level
		end
	end
	 
	if bestSlotData then
		local weaponData = self:GetService("WeaponService"):GetWeaponData(bestSlotData)
		
		if self:CanUpgradeWeapon(weaponData, inventory) then
			self.Gui.ContentText.Text = string.format("You require a higher-level weapon to unlock a new mission! You can currently upgrade your \"%s.\" Upgrading weapons is key to progressing in Heroes! 2.", weaponData.Name)
			self.Gui.ActionButton.Text = "Upgrade now!"
			self.Action = function()
				self.Gui.Visible = false
				self.ExpectingUpgrade = true
				
				local inventoryClient = self:GetClass("InventoryClient")
				inventoryClient:ToggleVisibility(true)
				inventoryClient:SelectContentByIndex(bestIndex)
			end
			
			return
		end
	end
	
	self:TryRecommendMaterialExpedition()
end

function PlayerGuideClient:TryRecommendMaterialExpedition()
	local expeditionId = "thundertopIronMine"
	local expedition = require(self.Storage:WaitForChild("Missions"):WaitForChild(expeditionId))
	
	local inventory = self:GetClass("InventoryClient").Inventory
	
	if inventory.Gold >= expedition.Cost.Gold then
		self.Gui.ContentText.Text = string.format("You need to upgrade your weapon to progress, but don't have materials. You can get lots of materials quickly on Material Expedition missions like \"%s.\" Material Expedition missions cost gold coins but drop lots of a specific material!", expedition.Name)
		self.Gui.ActionButton.Text = "Earn materials!"
		self.Action = function()
			self.Gui.Visible = false
			self:FireRemote("PartyUpdated", "QuickPlayRequested", expeditionId)
		end
	else
		self:TryRecommendLorithasExpedition()
	end
end

function PlayerGuideClient:TryRecommendLorithasExpedition()
	self.Gui.ContentText.Text = "You need to upgrade your weapon to progress, but you don't have materials and you don't have enough gold coins to go on any Material Expedition missions. The best way to earn gold coins is to go on a Lorithas Expedition!"
	self.Gui.ActionButton.Text = "Earn gold coins!"
	self.Action = function()
		self.Gui.Visible = false
		self:FireRemote("PartyUpdated", "QuickPlayRequested", "lorithasExpedition")
	end
end

local Singleton = PlayerGuideClient:Create()
return Singleton