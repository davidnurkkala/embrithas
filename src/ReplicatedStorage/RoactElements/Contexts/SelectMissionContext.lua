--[[
	Roact context for selecting a mission.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)
local SelectMissionContext = Roact.createContext("SelectMission")

function SelectMissionContext:Get(component)
	return component:__getContext(self.key).value
end

return SelectMissionContext
