local Super = require(script.Parent)
local Status = Super:Extend()

Status.Type = "ManaBurning"
Status.Interval = 0.1

Status.Category = "Bad"
Status.ImagePlaceholder = "MANA\nBRN"
				
function Status:OnStarted()
	local a = Instance.new("Attachment")
	a.Name = "BurningEmitterAttachment"
	
	local e = self.Storage.Models.ManaBurningEmitter:Clone()
	e.Parent = a
	
	a.Parent = self.Character.Root
	
	self.EmitterAttachment = a
	self.Emitter = e
	
	self.DrainPerSecond = self.Drain / self.MaxTime
end

function Status:OnTicked(dt)
	self.Character.Mana = math.max(0, self.Character.Mana - self.DrainPerSecond * dt)
end

function Status:OnEnded()
	self.Emitter.Enabled = false
	game:GetService("Debris"):AddItem(self.EmitterAttachment, self.Emitter.Lifetime.Max)
end

return Status