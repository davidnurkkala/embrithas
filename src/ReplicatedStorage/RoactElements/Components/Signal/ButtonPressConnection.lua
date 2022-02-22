--[[
	A simple connection to a button press.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)

local main = game.ReplicatedStorage.RoactElements
local ContextAction = require(main.Components.Base.ContextAction)

local ButtonPressConnection = Roact.PureComponent:extend("ButtonPressConnection")

local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	KeyCode = t.optional(t.any),
	InputTypes = t.optional(t.table),
	Callback = t.callback,
})

function ButtonPressConnection:init(props)
	assert(typecheck(props))

	self.onInput = function(_, inputState)
		if inputState == Enum.UserInputState.End then
			self.props.Callback()
		end
		return Enum.ContextActionResult.Sink
	end
end

function ButtonPressConnection:render()
	local props = self.props
	local inputs
	if props.KeyCode then
		inputs = {props.KeyCode}
	else
		inputs = props.InputTypes
	end

	return Roact.createElement(ContextAction, {
		InputTypes = inputs,
		OnInput = self.onInput,
	})
end

return ButtonPressConnection
