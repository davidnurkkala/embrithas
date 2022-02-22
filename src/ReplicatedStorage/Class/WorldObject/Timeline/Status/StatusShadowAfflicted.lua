local Super = require(script.Parent)
local Status = Super:Extend()

Status.Type = "ShadowAfflicted"

Status.Category = "Bad"
Status.ImagePlaceholder = "SHDW"
				
function Status:OnStarted()
	local a = Instance.new("Attachment")
	a.Name = "ShadowAfflictedEmitterAttachment"
	
	local e = self.Storage.Models.ShadowAfflictedEmitter:Clone()
	e.Parent = a
	
	a.Parent = self.Character.Root
	
	self.EmitterAttachment = a
	self.Emitter = e
end

function Status:OnEnded()
	self.Emitter.Enabled = false
	game:GetService("Debris"):AddItem(self.EmitterAttachment, self.Emitter.Lifetime.Max)
end

return Status