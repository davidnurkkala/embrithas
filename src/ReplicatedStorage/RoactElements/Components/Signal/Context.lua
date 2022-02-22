--[[
	Connects a function to a context value update.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)

local Context = Roact.PureComponent:extend("Context")

local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	Context = t.table,
	Callback = t.callback,
})

function Context:init(props)
	assert(typecheck(props))

	self.update = function(value)
		props.Callback(value)
		return nil
	end
end

function Context:render()
	local context = self.props.Context
	return Roact.createElement(context.Consumer, {
		render = self.update,
	})
end

return Context
