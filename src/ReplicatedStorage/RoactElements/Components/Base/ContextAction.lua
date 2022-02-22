--[[
	A simple context action handler.
]]

local ContextActionService = game:GetService("ContextActionService")

local Roact = require(game.ReplicatedStorage.Packages.Roact)
local generateId = require(game.ReplicatedStorage.Packages.generateId)

local ContextAction = Roact.PureComponent:extend("ContextAction")

local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	InputTypes = t.table,
	OnInput = t.callback,
})

function ContextAction:init(props)
	assert(typecheck(props))
	self.id = generateId()
	ContextActionService:BindAction(self.id,
		props.OnInput,
		false,
		table.unpack(props.InputTypes))
end

function ContextAction:render()
	return nil
end

function ContextAction:willUnmount()
	ContextActionService:UnbindAction(self.id)
end

return ContextAction
