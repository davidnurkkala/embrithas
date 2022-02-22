local Super = require(script.Parent)
local Goal = Super:Extend()

function Goal:CreateFromData(data)
	local object = self:Create()
	object:LoadData(data)
	return object
end

function Goal:IsLobby()
	return self:GetService("GameService").IsLobby
end

function Goal:GetSaveData(data)
	error("Base Goal GetSaveData called.")
end

function Goal:LoadData(data)
	error("Base Goal LoadData called.")
end

function Goal:ProcessGameplayEvent(event)
	error("Base Goal ProcessGameplayEvent called.")
end

function Goal:IsCompleted()
	error("Base Goal IsCompleted called.")
end

return Goal