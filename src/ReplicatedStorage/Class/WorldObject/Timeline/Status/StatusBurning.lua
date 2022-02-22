local Super = require(script.Parent)
local Status = Super:Extend()

Status.Type = "Burning"
Status.Interval = 0.5

Status.Category = "Bad"
Status.ImagePlaceholder = "BRN"
				
function Status:OnStarted()
	local a = Instance.new("Attachment")
	a.Name = "BurningEmitterAttachment"
	
	local e = self.Storage.Models.BurningEmitter:Clone()
	e.Parent = a
	
	a.Parent = self.Character.Root
	
	self.EmitterAttachment = a
	self.Emitter = e
	
	self.DamagePerSecond = self.Damage / self.MaxTime
end

function Status:UpdateDamage(damage)
	self.Damage = damage
	self.DamagePerSecond = self.Damage / self.MaxTime
end

function Status:OnTicked(dt)
	self:GetService("DamageService"):Damage({
		Source = self.Source,
		Target = self.Character,
		Amount = self.DamagePerSecond * dt,
		Weapon = self.Weapon,
		Type = "Heat",
		Tags = self.Tags,
	})
end

function Status:OnEnded()
	self.Emitter.Enabled = false
	game:GetService("Debris"):AddItem(self.EmitterAttachment, self.Emitter.Lifetime.Max)
end

return Status