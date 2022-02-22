local Super = require(script.Parent)
local Trap = Super:Extend()

function Trap:OnCreated()
	self.Active = true
	
	self.Model:SetPrimaryPartCFrame(self.StartCFrame)
	self.Model.Parent = self.StartParent
	
	local function onTouched(...) self:OnTouched(...) end
	self:SafeTouched(self.Model.PrimaryPart, onTouched)
end

function Trap:OnTriggered(legend)
	
end

function Trap:OnTouched(part)
	local legend = self:GetClass("Legend").GetLegendFromPart(part)
	if legend then
		self:OnTriggered(legend)
	end
end

return Trap