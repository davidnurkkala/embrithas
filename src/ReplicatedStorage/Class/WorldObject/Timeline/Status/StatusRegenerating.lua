local Super = require(script.Parent)
local Status = Super:Extend()

Status.Type = "Regenerating"

Status.Category = "Good"
Status.ImagePlaceholder = "RGN"

function Status:OnTicked(dt)
	self:GetService("DamageService"):Heal{
		Source = self.Source,
		Target = self.Character,
		Amount = self.HealingPerSecond * dt,
		Weapon = self,
	}
end

function Status:OnStarted()
	local attachment = Instance.new("Attachment")
	attachment.Name = "RegeneratingEmitterAttachment"
	
	local emitter = self.Storage.Emitters.RegeneratingEmitter:Clone()
	emitter.Parent = attachment
	
	attachment.Parent = self.Character.Root
	
	self.EmitterAttachment = attachment
	self.Emitter = emitter
end

function Status:OnEnded()
	self.Emitter.Enabled = false
	game:GetService("Debris"):AddItem(self.EmitterAttachment, self.Emitter.Lifetime.Max)
end

return Status