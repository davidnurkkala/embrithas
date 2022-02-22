--[[
	Draws a small label that can be hovered to show a tooltip.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)

local main = game.ReplicatedStorage.RoactElements
local AutomaticSize = require(main.Components.Base.AutomaticSize)

local HoverLabel = Roact.PureComponent:extend("HoverLabel")
local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	LayoutOrder = t.optional(t.integer),
	Text = t.string,
	Color = t.optional(t.Color3),
})

HoverLabel.defaultProps = {
	LayoutOrder = 1,
	Color = Color3.new(1, 1, 1),
}

function HoverLabel:init(props)
	assert(typecheck(props))
	self.state = {
		hovered = false,
	}

	self.mouseEnter = function()
		self:setState({
			hovered = true,
		})
	end

	self.mouseLeave = function()
		self:setState({
			hovered = false,
		})
	end
end

function HoverLabel:render()
	local props = self.props
	local tooltip = props[Roact.Children]

	local state = self.state
	local hovered = state.hovered

	return Roact.createElement("TextLabel", {
		LayoutOrder = props.LayoutOrder,
		Text = props.Text,
		TextSize = 32,
		RichText = true,
		Font = Enum.Font.GothamSemibold,
		TextColor3 = props.Color or Color3.new(1, 1, 1),
		BackgroundColor3 = Color3.new(),
		BackgroundTransparency = 0.2,
		[Roact.Event.MouseEnter] = self.mouseEnter,
		[Roact.Event.MouseLeave] = self.mouseLeave,
	}, {
		AutomaticSize = Roact.createElement(AutomaticSize, {
			ScaleWidth = true,
			PaddingWidth = 50,
			PaddingHeight = 25,
		}),

		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(1, 0),
		}),

		Tooltip = hovered and Roact.createFragment(tooltip),
	})
end

return HoverLabel
