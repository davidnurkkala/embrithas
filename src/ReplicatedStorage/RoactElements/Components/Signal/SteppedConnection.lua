--[[
	Calls the Update function every step.
	Uses a Lua signal to prevent lag that occurs from C++/Lua Boundary.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)
local SteppedSignal = require(game.ReplicatedStorage.Packages.SteppedSignal)

local SteppedConnection = Roact.PureComponent:extend("SteppedConnection")

local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	Update = t.callback,
})

function SteppedConnection:init(props)
	assert(typecheck(props))
	self.connection = SteppedSignal:Connect(props.Update)
end

function SteppedConnection:render()
	return nil
end

function SteppedConnection:willUnmount()
	if self.connection then
		self.connection:Disconnect()
	end
end

return SteppedConnection
