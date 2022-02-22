local Super = require(script.Parent)
local Goal = Super:Extend()

Goal.Type = "KillWithAbility"
Goal.Id = 1
Goal.CountCurrent = 0
Goal.CountMax = 1

function Goal:GetSaveData()
	return {
		Type = self.Type,
		Id = self.Id,
		CountCurrent = self.CountCurrent,
		CountMax = self.CountMax,
	}
end

function Goal:LoadData(data)
	self.Id = data.Id
	self.CountCurrent = data.CountCurrent
	self.CountMax = data.CountMax
end

function Goal:ProcessGameplayEvent(event)
	if self:IsLobby() then return end
	
	if self:IsCompleted() then return end
	
	if event.Type ~= self.Type then return end
	
	if event.Id ~= self.Id then return end
	
	self.CountCurrent += 1
end

function Goal:IsCompleted()
	return self.CountCurrent >= self.CountMax
end

return Goal