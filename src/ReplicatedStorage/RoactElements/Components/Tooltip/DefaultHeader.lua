--[[
	Default header for a Tooltip.
	Contains a title and subtitle.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)

local main = game.ReplicatedStorage.RoactElements
local AutomaticSize = require(main.Components.Base.AutomaticSize)

local DefaultHeader = Roact.PureComponent:extend("DefaultHeader")
local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	Title = t.string,
	Subtitle = t.optional(t.string),
})

local function formatTitle(title)
	return string.format("<b>%s</b>", string.upper(title))
end

function DefaultHeader:init(props)
	assert(typecheck(props))
end

function DefaultHeader:render()
	local props = self.props

	return Roact.createFragment({
		Layout = Roact.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),

		Title = Roact.createElement("TextLabel", {
			LayoutOrder = 1,
			Text = formatTitle(props.Title),
			RichText = true,
			TextWrapped = true,
			Font = Enum.Font.Fantasy,
			TextSize = 36,
			TextColor3 = Color3.new(1, 1, 1),
			Size = UDim2.fromScale(1, 0),
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, {
			AutomaticSize = Roact.createElement(AutomaticSize),
		}),

		Subtitle = props.Subtitle and Roact.createElement("TextLabel", {
			LayoutOrder = 2,
			Text = props.Subtitle,
			RichText = true,
			TextWrapped = true,
			Font = Enum.Font.GothamSemibold,
			TextSize = 24,
			TextColor3 = Color3.new(1, 1, 1),
			Size = UDim2.fromScale(1, 0),
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, {
			AutomaticSize = Roact.createElement(AutomaticSize),
		}),
	})
end

return DefaultHeader
