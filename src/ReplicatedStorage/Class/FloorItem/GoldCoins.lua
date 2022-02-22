local Super = require(script.Parent)
local GoldCoins = Super:Extend()

local TweenService = game:GetService("TweenService")

function GoldCoins:OnCreated()
	self.Active = true
	
	local models = self.Storage.Models.Gold:GetChildren()
	self.Model = models[math.random(1, #models)]:Clone()
	self.Model:SetPrimaryPartCFrame(self.StartCFrame)
	
	local sphere = self:CreateHitSphere(3)
	sphere.CFrame = self.StartCFrame
	sphere.Parent = self.Model
	
	self.Model.Parent = self.StartParent
	
	local function onTouched(...) self:OnTouched(...) end
	self:SafeTouched(sphere, onTouched)
end

function GoldCoins:OnTouched(part)
	if not self.Active then return end
	
	local legend = self:GetClass"Legend".GetLegendFromPart(part)
	if not legend then return end
	
	-- give money
	local players = game:GetService("Players"):GetPlayers()
	for _, player in pairs(players) do
		self:GetService("InventoryService"):AddGold(player, self.Amount)
	end
	
	self.Active = false
	self:Disappear()
end

function GoldCoins:Disappear()
	self.Model.PrimaryPart.Pickup:Play()
	
	local emitter = self.Model.PrimaryPart.Emitter
	local duration = emitter.Lifetime.Max
	
	emitter.Enabled = true
	delay(0.5, function()
		emitter.Enabled = false
	end)
	
	self:GetService("EffectsService"):RequestEffectAll("FadeModel", {
		Model = self.Model,
		Duration = duration,
	})
	game:GetService("Debris"):AddItem(self.Model, duration + 0.5)
end

return GoldCoins