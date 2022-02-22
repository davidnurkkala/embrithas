local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local Super = require(script.Parent)
local Node = Super:Extend()

local InteractableService = Super:GetClass("InteractableService")
local EffectsService = Super:GetClass("EffectsService")

function Node:OnCreated()
	if self.Room == self.Room.Dungeon.StartRoom then
		self.Model:Destroy()
		return
	end
	
	self.WarningCooldowns = {}
	self.Busy = false
	
	self.Model.PrimaryPart = self.Model.__Root
	
	self.InteractableId = InteractableService:CreateInteractable{
		Model = self.Model,
		Radius = 12,
		Callback = function(player)
			self:OnActivated(player)
		end,
	}
end

function Node:OnActivated(player)
	if self.Busy then return end
	
	local legend = self:GetClass("Legend").GetLegendFromPlayer(player)
	if not legend then return end
	
	local pickaxeEquipped = legend.Weapon.Data.Id == 69
	
	if pickaxeEquipped then
		if legend.WeaponsSheathed then
			if self.WarningCooldowns[player] then return end
			self.WarningCooldowns[player] = true
			delay(3, function() self.WarningCooldowns[player] = nil end)
			
			EffectsService:RequestEffect(player, "TextFeedback", {
				TextArgs = {
					Text = "You must unsheath your pickaxe to mine.",
				}
			})
			
			return
		end
	else
		if not legend.WeaponsSheathed then
			if self.WarningCooldowns[player] then return end
			self.WarningCooldowns[player] = true
			delay(3, function() self.WarningCooldowns[player] = nil end)
			
			EffectsService:RequestEffect(player, "TextFeedback", {
				TextArgs = {
					Text = "You must sheath your weapons to mine.",
				}
			})
			
			return
		end
	end
	
	self.Busy = true
	
	local pickaxe
	if not pickaxeEquipped then
		pickaxe = self.Storage.Models.Pickaxe:Clone()
		pickaxe.Weld.Part1 = pickaxe
		pickaxe.Weld.Part0 = legend.Model.RightHand
		pickaxe.Parent = legend.Model
	end
	
	local duration = 3.6
	local root = self.Model.PrimaryPart
	
	self:FireRemote("FacePartCalled", player, root, duration)
	legend:AnimationPlay("MiningLoop")
	
	local success = legend:Channel(duration, "Mining", "Sensitive")
	
	self:FireRemote("FacePartCalled", player)
	legend:AnimationStop("MiningLoop")
	
	if not pickaxeEquipped then
		Debris:AddItem(pickaxe, 0.5)
	end
	
	if success then
		if math.random(1, 2048) == 1 then
			self:GetService("InventoryService"):AddItem(player, "Weapons", {Id = 69})
		end
		
		self:AwardDrops(pickaxeEquipped)
		self:Disappear()
	else
		self.Busy = false
	end
end

function Node:AwardDrops(pickaxeEquipped)
	local materials = require(self.Storage.ItemData).Materials
	local id
	
	for _, materialData in pairs(materials) do
		if materialData.InternalName == self.Resource then
			id = materialData.Id
			break
		end
	end
	
	if not id then return end
	
	local count = math.max(1, math.floor(self.Room.Dungeon.Level * self.ResourcePerLevel))
	if pickaxeEquipped then
		count = math.floor(count * 1.5)
	end
	count = math.random(1, count)
	
	local inventoryService = self:GetService("InventoryService")
	for _, player in pairs(Players:GetPlayers()) do
		inventoryService:AddItem(player, "Materials", {Id = id, Amount = count})
	end
end

function Node:Disappear()
	local sound = self.Storage.Sounds.RockImpact1:Clone()
	sound.Parent = self.Model.PrimaryPart
	sound:Play()
	
	InteractableService:DestroyInteractable(self.InteractableId)

	EffectsService:RequestEffectAll("FadeModel", {
		Model = self.Model,
		Duration = 1,
	})
	game:GetService("Debris"):AddItem(self.Model, 1)
end

return Node