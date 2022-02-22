--[[
	Optional footer for a Tooltip.
	Indicates that a given mission is deadly.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)

local main = game.ReplicatedStorage.RoactElements
local AutomaticSize = require(main.Components.Base.AutomaticSize)

local DeadlyFooter = Roact.PureComponent:extend("DeadlyFooter")
local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	RecommendedLevel = t.integer,
	CurrentLevel = t.integer,
})

local function orange(text)
	return string.format([[<font color="#FFA500">%s</font>]], text)
end

local function formatTitle(title)
	return orange(string.format("<b>%s</b>", string.upper(title)))
end

function DeadlyFooter:init(props)
	assert(typecheck(props))
end

function DeadlyFooter:render()
	local props = self.props

	return Roact.createFragment({
		Layout = Roact.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 2),
		}),

		Title = Roact.createElement("TextLabel", {
			LayoutOrder = 1,
			Text = formatTitle("☠️ DEADLY MISSION"),
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
			Text = "You are underleveled for this mission. You can still attempt it, but it may be impossible.",
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

		CurrentLevel = Roact.createElement("TextLabel", {
			LayoutOrder = 3,
			Text = string.format("• Your Level: %s",
				orange(string.format("<b>%i</b>", props.CurrentLevel))),
			RichText = true,
			Font = Enum.Font.GothamSemibold,
			TextSize = 24,
			TextColor3 = Color3.new(1, 1, 1),
			Size = UDim2.fromScale(1, 0),
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, {
			AutomaticSize = Roact.createElement(AutomaticSize),
		}),

		RecommendedLevel = Roact.createElement("TextLabel", {
			LayoutOrder = 4,
			Text = string.format("• Recommended Level: %s",
				orange(string.format("<b>%i</b>", props.RecommendedLevel))),
			RichText = true,
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

return DeadlyFooter
