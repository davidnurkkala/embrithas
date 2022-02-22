--[[
	Default bullet point content for a Tooltip.
	A collection of multiple bulleted entries.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)

local main = game.ReplicatedStorage.RoactElements
local AutomaticSize = require(main.Components.Base.AutomaticSize)

local BodyBulletPoints = Roact.PureComponent:extend("BodyBulletPoints")
local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	Entries = t.table,
	LayoutOrder = t.optional(t.integer),
})

BodyBulletPoints.defaultProps = {
	LayoutOrder = 1,
}

local function renderBulletPoint(text, layoutOrder)
	return Roact.createElement("TextLabel", {
		LayoutOrder = layoutOrder,
		Text = "• " .. text,
		RichText = true,
		TextWrapped = true,
		Font = Enum.Font.GothamSemibold,
		TextSize = 24,
		TextColor3 = Color3.new(0.8, 0.8, 0.8),
		Size = UDim2.fromScale(1, 0),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, {
		AutomaticSize = Roact.createElement(AutomaticSize),
	})
end

function BodyBulletPoints:init(props)
	assert(typecheck(props))
end

function BodyBulletPoints:render()
	local props = self.props

	local bulletPoints = {}
	for num, entry in ipairs(props.Entries) do
		bulletPoints[num] = renderBulletPoint(entry, num)
	end

	return Roact.createElement("Frame", {
		LayoutOrder = props.LayoutOrder,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.fromScale(1, 0),
		BackgroundTransparency = 1,
	}, {
		Layout = Roact.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 5),
		}),

		BulletPoints = Roact.createFragment(bulletPoints),
	})
end

return BodyBulletPoints
