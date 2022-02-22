--[[
	Default text header for a Tooltip.
	Starts a block of contents.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)

local main = game.ReplicatedStorage.RoactElements
local AutomaticSize = require(main.Components.Base.AutomaticSize)

local BodyHeader = Roact.PureComponent:extend("BodyHeader")
local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	Text = t.string,
	LayoutOrder = t.optional(t.integer),
})

BodyHeader.defaultProps = {
	LayoutOrder = 1,
}

local function formatTitle(title)
	return string.format("<b>%s</b>", string.upper(title))
end

function BodyHeader:init(props)
	assert(typecheck(props))
end

function BodyHeader:render()
	local props = self.props

	return Roact.createElement("TextLabel", {
		LayoutOrder = props.LayoutOrder,
		Text = formatTitle(props.Text),
		RichText = true,
		TextWrapped = true,
		Font = Enum.Font.Fantasy,
		TextSize = 28,
		TextColor3 = Color3.new(1, 1, 1),
		Size = UDim2.fromScale(1, 0),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, {
		AutomaticSize = Roact.createElement(AutomaticSize),
	})
end

return BodyHeader
