local Super = require(script.Parent)
local Goal = Super:Extend()

Goal.Type = "CompleteMission"
Goal.Completed = false

function Goal:GetSaveData()
	return {
		Type = self.Type,
		MissionId = self.MissionId,
		Completed = self.Completed,
	}
end

function Goal:LoadData(data)
	self.MissionId = data.MissionId
	self.Completed = data.Completed
end

function Goal:ProcessGameplayEvent(event)
	if event.Type ~= self.Type then return end
	
	if event.MissionId == self.MissionId then
		self.Completed = true
	end
end

function Goal:IsCompleted()
	return self.Completed
end

return Goal