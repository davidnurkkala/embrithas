--[[
	Calls the Update function every render step.
	Uses a Lua signal to prevent lag that occurs from C++/Lua Boundary.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)
local RenderSteppedSignal = require(game.ReplicatedStorage.Packages.RenderSteppedSignal)

local RenderSteppedConnection = Roact.PureComponent:extend("RenderSteppedConnection")

local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	Update = t.callback,
})

function RenderSteppedConnection:init(props)
	assert(typecheck(props))
	self.connection = RenderSteppedSignal:Connect(props.Update)
end

function RenderSteppedConnection:render()
	return nil
end

function RenderSteppedConnection:willUnmount()
	if self.connection then
		self.connection:Disconnect()
	end
end

return RenderSteppedConnection
