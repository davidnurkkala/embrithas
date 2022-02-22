local Super = require(script.Parent)
local Status = Super:Extend()

Status.Type = "Frosty"
Status.SlowPerStack = 0.1

Status.Category = "Bad"
Status.ImagePlaceholder = "FRSTY"
				
function Status:OnStarted()
	local a = Instance.new("Attachment")
	a.Name = "FrostyEmitterAttachment"
	
	local e = self.Storage.Models.FrostyEmitter:Clone()
	e.Parent = a
	
	a.Parent = self.Character.Root
	
	self.EmitterAttachment = a
	self.Emitter = e
	
	self:AddStack()
end

function Status:AddStack()
	local stacks = self.Stacks or 0
	
	if stacks > 0 then
		if not self.Character.Resilient then
			self.Character.Speed.Percent = self.Character.Speed.Percent + self.SlowPerStack * stacks
		end
	end
	
	stacks = stacks + 1
	
	if not self.Character.Resilient then
		self.Character.Speed.Percent = self.Character.Speed.Percent - self.SlowPerStack * stacks
	end
	
	self.Stacks = stacks
	self:Restart()
end

function Status:OnEnded()
	if not self.Character.Resilient then
		self.Character.Speed.Percent = self.Character.Speed.Percent + self.SlowPerStack * (self.Stacks or 0)
	end
	
	self.Emitter.Enabled = false
	game:GetService("Debris"):AddItem(self.EmitterAttachment, self.Emitter.Lifetime.Max)
end

return Status