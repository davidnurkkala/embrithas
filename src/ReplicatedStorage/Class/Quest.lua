local Super = require(script.Parent)
local Quest = Super:Extend()

function Quest:CreateFromData(data)
	local object = self:Create()
	object:LoadData(data)
	return object
end

function Quest:OnCreated()
	self.Goals = {}
end

function Quest:ProcessGameplayEvent(event)
	for _, goal in ipairs(self.Goals) do
		goal:ProcessGameplayEvent(event)
	end
end

function Quest:IsCompleted()
	for _, goal in ipairs(self.Goals) do
		if not goal:IsCompleted() then
			return false
		end
	end
	return true
end

function Quest:GetSaveData()
	local data = {
		Name = self.Name,
		Goals = {},
		Rewards = self.Rewards,
	}
	
	for _, goal in ipairs(self.Goals) do
		table.insert(data.Goals, goal:GetSaveData())
	end
	
	return data
end

function Quest:LoadData(data)
	self.Name = data.Name
	self.Rewards = data.Rewards
	
	self.Goals = {}
	for _, goalData in ipairs(data.Goals) do
		local className = "Goal"..goalData.Type
		table.insert(self.Goals, self:GetClass(className):CreateFromData(goalData))
	end
end

return Quest