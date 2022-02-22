local Super = require(script.Parent)
local BluesteelOre = Super:Extend()

function BluesteelOre:OnCreated()
	self.Active = true
			
	self.Model = self.Storage.Models.BluesteelOre:Clone()
	self.Model:SetPrimaryPartCFrame(self.StartCFrame * CFrame.Angles(0, math.pi * 2 * math.random(), 0))
	
	local sphere = self:CreateHitSphere(5)
	sphere.CFrame = self.StartCFrame
	sphere.Parent = self.Model
	
	self.Model.Parent = self.StartParent
	
	local function onTouched(...) self:OnTouched(...) end
	self:SafeTouched(sphere, onTouched)
end

function BluesteelOre:OnTouched(part)
	if not self.Active then return end
	
	local legend = self:GetClass"Legend".GetLegendFromPart(part)
	if not legend then return end
	
	local min = 1
	local max = 3
	max = math.max(1, math.floor(max * self:GetRun():GetDifficultyData().LootChance or 1))
	min = math.floor(max / 2)
	local amount = math.random(min, max)
	
	for _, player in pairs(game:GetService("Players"):GetPlayers()) do
		self:GetService("InventoryService"):AddItem(player, "Materials", {Id = 4, Amount = amount})
	end
	
	self.Active = false
	self:Disappear()
end

function BluesteelOre:Disappear()
	self.Model.Bluesteel:Destroy()
	
	delay(1, function()
		self:GetService("EffectsService"):RequestEffectAll("FadeModel", {
			Model = self.Model,
			Duration = 1,
		})
		game:GetService("Debris"):AddItem(self.Model, 1)
	end)
end

return BluesteelOre