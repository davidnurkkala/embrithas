--[[
	Default text content for a Tooltip.
	A multi-line body of text.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)

local main = game.ReplicatedStorage.RoactElements
local AutomaticSize = require(main.Components.Base.AutomaticSize)

local BodyText = Roact.PureComponent:extend("BodyText")
local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	Text = t.string,
	LayoutOrder = t.optional(t.integer),
})

BodyText.defaultProps = {
	LayoutOrder = 1,
}

function BodyText:init(props)
	assert(typecheck(props))
end

function BodyText:render()
	local props = self.props

	return Roact.createElement("TextLabel", {
		LayoutOrder = props.LayoutOrder,
		Text = props.Text,
		RichText = true,
		TextWrapped = true,
		Font = Enum.Font.Merriweather,
		TextSize = 24,
		TextColor3 = Color3.new(0.8, 0.8, 0.8),
		Size = UDim2.fromScale(1, 0),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, {
		AutomaticSize = Roact.createElement(AutomaticSize),
	})
end

return BodyText
