local MOVEMENT_RADIUS_SQ = 2 ^ 2

local Super = require(script.Parent)
local Status = Super:Extend()

Status.Type = "Channeling"
Status.ChannelType = "Normal"

Status.ReplicationDisabled = true

Status.FailureTypesByChannelType = {
	Sheathing = {"Stun", "Attack", "Ability", "Damage"},
	Normal = {"Stun", "Attack", "Ability"},
	Sensitive = {"Stun", "Attack", "Ability", "Movement", "Damage"},
}

function Status:OnStarted()
	if not self.Event then
		error("Channel must be passed an event to fire its success to.")
	end
	
	self.StartPosition = self.Character:GetPosition()
	self.DidSucceed = true
	
	self.Connections = {}
	
	if self:DoesFailOn("Attack") then
		table.insert(self.Connections, self.Character.WeaponUsed:Connect(function()
			self:Fail()
		end))
	end
	
	if self:DoesFailOn("Ability") then
		table.insert(self.Connections, self.Character.AbilityActivated:Connect(function()
			self:Fail()
		end))
	end
end

function Status:Fail()
	self.DidSucceed = false
	self:Stop()
end

function Status:DoesFailOn(failureType)
	return table.find(self.FailureTypesByChannelType[self.ChannelType], failureType) ~= nil
end

function Status:OnDamaged(damage)
	if damage.Amount <= 0 then return end
	
	if self:DoesFailOn("Damage") then
		self:Fail()
		return
	end
end

function Status:HasMoved()
	local delta = self.Character:GetPosition() - self.StartPosition
	local distanceSq = delta.X ^ 2 + delta.Z ^ 2
	return distanceSq >= MOVEMENT_RADIUS_SQ
end

function Status:OnTicked(dt)
	if self:DoesFailOn("Stun") and self.Character:IsStunned() then
		self:Fail()
		return
	end
	
	if self:DoesFailOn("Movement") and self:HasMoved() then
		self:Fail()
		return
	end
	
	if self.CustomOnTicked then
		self:CustomOnTicked(dt)
	end
end

function Status:OnEnded()
	for _, connection in pairs(self.Connections) do
		connection:Disconnect()
	end
	
	self.Event:Fire(self.DidSucceed)
end

return Status