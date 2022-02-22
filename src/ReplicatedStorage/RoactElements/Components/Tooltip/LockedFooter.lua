--[[
	Optional footer for a Tooltip.
	Indicates that a given mission is locked.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)

local main = game.ReplicatedStorage.RoactElements
local AutomaticSize = require(main.Components.Base.AutomaticSize)

local LockedFooter = Roact.PureComponent:extend("LockedFooter")

local function orange(text)
	return string.format([[<font color="#FFA500">%s</font>]], text)
end

local function formatTitle(title)
	return orange(string.format("<b>%s</b>", string.upper(title)))
end

function LockedFooter:render()
	return Roact.createFragment({
		Layout = Roact.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 2),
		}),

		Title = Roact.createElement("TextLabel", {
			LayoutOrder = 1,
			Text = formatTitle("🔒 MISSION LOCKED"),
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
			Text = "You do not meet the requirements for this mission.",
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

return LockedFooter
