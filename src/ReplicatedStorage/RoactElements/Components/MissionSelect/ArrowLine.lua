--[[
	Draws a line from FromPoint to ToPoint.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)

local ArrowLine = Roact.PureComponent:extend("ArrowLine")
local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	ZIndex = t.optional(t.integer),
	Thickness = t.integer,
	FromPoint = t.UDim2,
	ToPoint = t.UDim2,
	Color = t.optional(t.Color3),
})

ArrowLine.defaultProps = {
	ZIndex = 1,
	Color = Color3.new(),
}

function ArrowLine:init(props)
	assert(typecheck(props))
	self.clouds = Roact.createRef()
end

function ArrowLine:render()
	local props = self.props
	local center = props.FromPoint:Lerp(props.ToPoint, 0.5)
	local fromX = props.FromPoint.X.Scale
	local fromY = props.FromPoint.Y.Scale
	local toX = props.ToPoint.X.Scale
	local toY = props.ToPoint.Y.Scale
	local distX = fromX - toX
	local distY = (fromY - toY) / (16/9)
	local angle = math.deg(math.atan2(distY, distX))
	local length = math.sqrt(distX^2 + distY^2)

	return Roact.createFragment({
		Line = Roact.createElement("Frame", {
			ZIndex = props.ZIndex,
			Position = center,
			Rotation = angle,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(length, 0, 0, props.Thickness),
			BorderSizePixel = 0,
			BackgroundColor3 = props.Color,
		}),

		Endpoint = Roact.createElement("Frame", {
			ZIndex = props.ZIndex,
			Position = props.ToPoint,
			Size = UDim2.fromOffset(20, 20),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BorderSizePixel = 0,
			BackgroundColor3 = props.Color,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
		}),
	})
end

return ArrowLine
