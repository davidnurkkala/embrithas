--[[
	Optional footer for a Tooltip.
	Indicates that a given mission is recommended.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)

local main = game.ReplicatedStorage.RoactElements
local AutomaticSize = require(main.Components.Base.AutomaticSize)

local RecommendedFooter = Roact.PureComponent:extend("RecommendedFooter")

local function formatTitle(title)
	return string.format("<b>%s</b>", string.upper(title))
end

function RecommendedFooter:render()
	return Roact.createFragment({
		Layout = Roact.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 2),
		}),

		Title = Roact.createElement("TextLabel", {
			LayoutOrder = 1,
			Text = formatTitle("💠 RECOMMENDED MISSION"),
			RichText = true,
			Font = Enum.Font.GothamBold,
			TextSize = 32,
			TextColor3 = Color3.new(1, 1, 1),
			Size = UDim2.fromScale(1, 0),
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, {
			AutomaticSize = Roact.createElement(AutomaticSize),
		}),

		Subtitle = Roact.createElement("TextLabel", {
			LayoutOrder = 2,
			Text = "This mission is recommended for you based on your level.",
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

return RecommendedFooter
