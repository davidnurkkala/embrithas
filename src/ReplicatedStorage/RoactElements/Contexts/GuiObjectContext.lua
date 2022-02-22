--[[
	Roact context for accessing the GuiObject class
	associated with the current Roact tree.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)
local GuiObjectContext = Roact.createContext("GuiObject")

function GuiObjectContext:Get(component)
	return component:__getContext(self.key).value
end

function GuiObjectContext:GetLobbyClient(component)
	local GuiObject = self:Get(component)
	return GuiObject:GetService("LobbyClient")
end

return GuiObjectContext
