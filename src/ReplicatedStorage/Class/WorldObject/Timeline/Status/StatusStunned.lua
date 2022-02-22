local Super = require(script.Parent)
local Status = Super:Extend()

Status.Type = "Stunned"

Status.Category = "Bad"
Status.ImagePlaceholder = "STUN"

function Status:OnStarted()
	if self.Character:IsA(self:GetClass("Enemy")) then
		self.Character:CancelTelegraphs()
	end
end

return Status