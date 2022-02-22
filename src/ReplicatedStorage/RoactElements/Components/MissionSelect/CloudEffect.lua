--[[
	A gradient shimmer effect for the clouds on the map screen.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)
local CreateTween = require(game.ReplicatedStorage.Packages.CreateTween)

local CloudEffect = Roact.PureComponent:extend("CloudEffect")
local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	Color = t.Color3,
	Transparency = t.number,
})

function CloudEffect:init(props)
	assert(typecheck(props))
	self.clouds = Roact.createRef()
end

function CloudEffect:didMount()
	local clouds = self.clouds:getValue()
	if clouds then
		CreateTween({
			Instance = clouds,
			Time = 120,
			EasingDirection = Enum.EasingDirection.In,
			EasingStyle = Enum.EasingStyle.Linear,
			RepeatCount = -1,
			Props = {
				Position = UDim2.fromScale(0, 0.5),
			},
		}):Play()
	end
end

function CloudEffect:render()
	local props = self.props

	return Roact.createElement("ImageLabel", {
		Position = UDim2.fromScale(-2, 0.5),
		AnchorPoint = Vector2.new(0, 0.5),
		Image = "rbxassetid://1788841511",
		ImageColor3 = props.Color,
		ImageTransparency = props.Transparency,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(4, 1),
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromScale(0.5, 2),
		[Roact.Ref] = self.clouds,
	})
end

return CloudEffect
