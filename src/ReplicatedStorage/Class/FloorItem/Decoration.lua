local Super = require(script.Parent)
local Decoration = Super:Extend()

function Decoration:OnCreated()
	self.Model:SetPrimaryPartCFrame(self.StartCFrame * (self.Offset or CFrame.new()))
	self.Model.Parent = self.StartParent
end

return Decoration