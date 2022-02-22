local Super = require(script.Parent)
local MiningCamp = Super:Extend()

local TweenService = game:GetService("TweenService")

function MiningCamp:OnCreated()
	self.Model = self.Storage.Models.MiningCamp:Clone()
	self.Model:SetPrimaryPartCFrame(self.StartCFrame)
	
	local sphere = self:CreateHitSphere(16)
	sphere.CFrame = self.StartCFrame
	sphere.Parent = self.Model
	
	self.Model.Parent = self.StartParent
	
	self.Model.Miner.AnimationController:LoadAnimation(self.Storage.Animations.JolianMinerIdle):Play()
	
	local function onTouched(...) self:OnTouched(...) end
	self:SafeTouched(sphere, onTouched)
end

function MiningCamp:OnTouched(part)
	local legend = self:GetClass"Legend".GetLegendFromPart(part)
	if not legend then return end
	if not legend.IronOreRockCarrying then return end
	
	legend.IronOreRockCarrying = false
	legend.Model.Sack:Destroy()
	
	local min = 1
	local max = 2
	max = math.ceil(max * self:GetRun():GetDifficultyData().LootChance or 1)
	local amount = math.random(min, max)
	for _, player in pairs(game:GetService("Players"):GetPlayers()) do
		self:GetService("InventoryService"):AddItem(player, "Materials", {Id = 1, Amount = amount})
	end
end

return MiningCamp