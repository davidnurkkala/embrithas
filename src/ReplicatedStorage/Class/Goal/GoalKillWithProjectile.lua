local Super = require(script.Parent)
local Goal = Super:Extend()

Goal.Type = "KillWithProjectile"
Goal.CountCurrent = 0
Goal.CountMax = 1

function Goal:GetSaveData()
	return {
		Type = self.Type,
		CountCurrent = self.CountCurrent,
		CountMax = self.CountMax,
	}
end

function Goal:LoadData(data)
	self.CountCurrent = data.CountCurrent
	self.CountMax = data.CountMax
end

function Goal:ProcessGameplayEvent(event)
	if self:IsLobby() then return end
	
	if self:IsCompleted() then return end
	
	if event.Type ~= self.Type then return end
	
	self.CountCurrent += 1
end

function Goal:IsCompleted()
	return self.CountCurrent >= self.CountMax
end

return Goal