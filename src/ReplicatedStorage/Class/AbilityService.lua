local Super = require(script.Parent)
local AbilityService = Super:Extend()

AbilityService.AbilityData = require(Super.Storage.ItemData).Abilities

function AbilityService:GetAbilityData(id, level)
	local data = {
		Level = level,
	}
	
	for key, val in pairs(self.AbilityData[id]) do
		data[key] = val
	end
	
	return data
end

local Singleton = AbilityService:Create()
return Singleton