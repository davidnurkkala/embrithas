--[[
	Handles rendering of the Mission Select screen.
]]

local main = game.ReplicatedStorage.RoactElements
local CreateRoactClass = require(main.CreateRoactClass)
local MissionSelectController = require(main.Components.MissionSelect.MissionSelectController)
local Super = require(script.Parent)

return CreateRoactClass(Super, MissionSelectController)
