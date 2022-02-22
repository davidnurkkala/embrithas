--[[
	A shimmer effect.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)
local CreateTween = require(game.ReplicatedStorage.Packages.CreateTween)
local t = require(game.ReplicatedStorage.Packages.t)
local main = script.Parent.Parent
local HeartbeatConnection = require(main.Signal.HeartbeatConnection)

local Shimmer = Roact.PureComponent:extend("Shimmer")
local typecheck = t.interface({
	ZIndex = t.optional(t.integer),
	Time = t.optional(t.number),
	Offset = t.optional(t.number),
})

Shimmer.defaultProps = {
	ZIndex = 1,
	Time = 1.2,
	Offset = 1.5,
}

function Shimmer:init(props)
	assert(typecheck(props))
	self.shimmerRef = Roact.createRef()
	self.lastShimmer = math.floor(tick() * 0.5)

	self.initShimmer = function(shimmer)
		self.shimmer = shimmer

		self.shineEffect = CreateTween({
			Instance = shimmer.UIGradient,
			Time = props.Time,
			EasingDirection = Enum.EasingDirection.In,
			EasingStyle = Enum.EasingStyle.Linear,
			Props = {
				Offset = Vector2.new(self.props.Offset, 0),
			},
		})
	end

	self.update = function()
		local now = math.floor(tick() * 0.5)
		if self.shineEffect and self.shimmer and now > self.lastShimmer then
			self.lastShimmer = now
			self.shineEffect:Cancel()
			self.shimmer.UIGradient.Offset = Vector2.new(-self.props.Offset, 0)
			self.shineEffect:Play()
		end
	end
end

function Shimmer:didMount()
	local shimmer = self.shimmerRef:getValue()
	if shimmer then
		self.initShimmer(shimmer)
	end
end

function Shimmer:render()
	return Roact.createFragment({
		Update = Roact.createElement(HeartbeatConnection, {
			Update = self.update,
		}),

		Shimmer = Roact.createElement("Frame", {
			ZIndex = self.props.ZIndex,
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(1, 1, 1),
			[Roact.Ref] = self.shimmerRef,
		}, {
			UIGradient = Roact.createElement("UIGradient", {
				Offset = Vector2.new(-self.props.Offset, 0),
				Rotation = 45,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.3, 1),
					NumberSequenceKeypoint.new(0.5, 0.5),
					NumberSequenceKeypoint.new(0.7, 1),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),

			Children = self.props[Roact.Children] and Roact.createFragment(self.props[Roact.Children]),
		}),
	})
end

return Shimmer
