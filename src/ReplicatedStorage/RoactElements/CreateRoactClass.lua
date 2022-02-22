--[[
	Creates a class that wraps a Roact tree.
	Takes a Super class to extend, as well as a Roact element Controller.
	The Controller element should take no props.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)
local RoactElements = game.ReplicatedStorage.RoactElements
local GuiObjectContext = require(RoactElements.Contexts.GuiObjectContext)

local function CreateRoactClass(Super, Controller)
	local Class = Super:Extend()

	function Class:OnCreated()
		self.handle = Roact.mount(Roact.createElement(GuiObjectContext.Provider, {
			value = self,
		}, {
			Controller = Roact.createElement(Controller),
		}))
	end

	function Class:Close()
		if self.handle then
			Roact.unmount(self.handle)
			self.handle = nil
		end
	end

	return Class
end

return CreateRoactClass
