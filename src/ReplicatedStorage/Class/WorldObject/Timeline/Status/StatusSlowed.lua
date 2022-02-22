local Super = require(script.Parent)
local Status = Super:Extend()

Status.Type = "Slowed"

Status.Category = "Bad"
Status.ImagePlaceholder = "SLOW"

Status.Percent = 0
Status.Flat = 0

function Status:OnStarted()
	self.Character.Speed.Percent -= self.Percent
	self.Character.Speed.Flat -= self.Flat
end

function Status:OnEnded()
	self.Character.Speed.Percent += self.Percent
	self.Character.Speed.Flat += self.Flat
end

return Status