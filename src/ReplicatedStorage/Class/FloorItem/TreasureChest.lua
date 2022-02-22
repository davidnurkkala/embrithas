local Super = require(script.Parent)
local TreasureChest = Super:Extend()

local Configuration = require(Super.Storage.Configuration)
local TweenService = game:GetService("TweenService")

TreasureChest.MaterialNames = {
	Iron = 20,
	Iskith = 20,
	Coal = 10,
	Gold = 10,
	Gemstones = 4,
	Worldstone = 4,
}

function TreasureChest:OnCreated()
	self.Active = true
	
	self.Model = self.Storage.Models.Chest:Clone()
	self.Model:SetPrimaryPartCFrame(self.StartCFrame)
	self.Model.Parent = self.StartParent
	
	local function onTouched(...) self:OnTouched(...) end
	self:SafeTouched(self.Model.Base, onTouched)
end

function TreasureChest:OnTouched(part)
	if not self.Active then return end
	
	local legend = self:GetClass"Legend".GetLegendFromPart(part)
	if not legend then return end
	
	local run = self:GetRun()
	local level = run.Dungeon.Level
	
	self.Active = false
	
	local track = self.Model.AnimationController:LoadAnimation(self.Storage.Animations.ChestOpen) 
	track:Play()
	
	track:GetMarkerReachedSignal("Sound"):Wait()
	
	self.Model.Base.Open:Play()
	
	track:GetMarkerReachedSignal("Open"):Wait()
	
	self.Model.Glow.Emitter:Emit(32)
	
	local players = game:GetService("Players"):GetPlayers()
	local inventoryService = self:GetService("InventoryService")
	
	local maxRolls = math.max(1, math.floor(self.Room.Dungeon.Level / Configuration.ChestMaxRollsPerLevel))
	local difficulty = run:GetDifficultyData()
	if difficulty.LootChance then
		maxRolls = math.ceil(maxRolls * difficulty.LootChance)
	end
	local rolls = math.random(1, maxRolls)
	
	for _, player in pairs(players) do
		local amountById = {}
		
		for _ = 1, rolls do
			local name = self:GetWeightedResult(self.MaterialNames)
			local data = self:GetService("MaterialService"):GetMaterialDataByInternalName(name)
			amountById[data.Id] = (amountById[data.Id] or 0) + 1
		end
		
		for id, amount in pairs(amountById) do
			inventoryService:PromptAddItem(player, "Materials", {Id = id, Amount = amount})
		end
	end
	
	wait(1)
	
	self.Model.Glow:Destroy()
	
	local duration = 5
	self:GetService("EffectsService"):RequestEffectAll("FadeModel", {
		Model = self.Model,
		Duration = duration
	})
	game:GetService("Debris"):AddItem(self.Model, duration)
end

return TreasureChest