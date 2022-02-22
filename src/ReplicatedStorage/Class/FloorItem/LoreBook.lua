local Super = require(script.Parent)
local LoreBook = Super:Extend()

LoreBook.LoreId = "worldHistoryAbridged"

function LoreBook:OnCreated()
	self.Active = true
	
	self.Model = self.Storage.Models.LoreBook:Clone()
	self.Model:SetPrimaryPartCFrame(self.StartCFrame)
	self.Model.Parent = self.StartParent
	
	local function onTouched(...) self:OnTouched(...) end
	self:SafeTouched(self.Model.PrimaryPart, onTouched)
end

function LoreBook:OnTouched(part)
	if not self.Active then return end
	
	local legend = self:GetClass"Legend".GetLegendFromPart(part)
	if not legend then return end
	
	local dataService = self:GetService("DataService")
	
	for _, player in pairs(game:GetService("Players"):GetPlayers()) do
		local result = dataService:UnlockLore(player, self.LoreId)
		
		if (player == legend.Player) and (result == false) then
			self:FireRemote("NotificationRequested", player, {
				Title = "Lore Known",
				Content = "You've found this lore before",
			})
		end
	end
	
	self.Active = false
	self:Disappear()
end

function LoreBook:Disappear()
	local duration = 1
	
	self:GetService("EffectsService"):RequestEffectAll("FadeModel", {
		Model = self.Model,
		Duration = duration,
	})
	game:GetService("Debris"):AddItem(self.Model, duration + 0.5)
end

return LoreBook