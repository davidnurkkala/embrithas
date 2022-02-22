--[[
	A generic tooltip that accepts any items inside.
	Renders inside a top-level screen gui.
]]

local UserInputService = game:GetService("UserInputService")
local MOUSE_OFFSET_DISTANCE = Vector2.new(10, 10)

local camera = workspace.CurrentCamera
local Roact = require(game.ReplicatedStorage.Packages.Roact)
local Promise = require(game.ReplicatedStorage.Packages.Promise)
local GetBestScale = require(game.ReplicatedStorage.Packages.GetBestScale)
local Spring = require(game.ReplicatedStorage.Packages.Spring)
local main = game.ReplicatedStorage.RoactElements
local HeartbeatConnection = require(main.Components.Signal.HeartbeatConnection)

local Tooltip = Roact.PureComponent:extend("Tooltip")

local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	DisplayOrder = t.optional(t.integer),
})

Tooltip.defaultProps = {
	DisplayOrder = 3,
}

function Tooltip:init(props)
	assert(typecheck(props))
	self.state = {
		visible = false,
	}

	self.size, self.updateSize = Roact.createBinding(Vector2.new())
	self.XanchorPoint, self.updateXAnchorPoint = Roact.createBinding(0)
	self.position, self.updatePosition = Roact.createBinding(UserInputService:GetMouseLocation())
	self.yOffset, self.updateYOffset = Roact.createBinding(0)
	self.yOffsetSpring = Spring.new()
	self.yOffsetSpring.Speed = 30
	self.yOffsetSpring.Target = self.yOffset:getValue()

	self.mainRef = Roact.createRef()
	self.layoutRef = Roact.createRef()

	self.checkFirstAnchorPoint = function()
		local position = self.position:getValue()
		local viewport = camera.ViewportSize

		local scale = GetBestScale()
		if (position.X + (500 * scale)) > viewport.X then
			self.XanchorPointSpring = Spring.new(1)
			self.updateXAnchorPoint(1)
		else
			self.XanchorPointSpring = Spring.new(0)
		end

		self.XanchorPointSpring.Speed = 30
		self.XanchorPointSpring.Target = self.XanchorPoint:getValue()
	end

	self.updateExtents = function(newPos)
		local layout = self.layoutRef:getValue()
		local mainFrame = self.mainRef:getValue()
		if layout == nil or mainFrame == nil then
			return
		end

		local position = t.Vector2(newPos) and newPos or mainFrame.AbsolutePosition
		local size = layout.AbsoluteContentSize
		self.updateSize(size)
		local viewport = camera.ViewportSize

		local scale = GetBestScale()
		if (position.X + (size.X * scale)) > viewport.X then
			self.XanchorPointSpring.Target = 1
		else
			self.XanchorPointSpring.Target = 0
		end

		local offset
		if position.Y + (size.Y * scale) > (viewport.Y - MOUSE_OFFSET_DISTANCE.Y) then
			offset = (position.Y + (size.Y * scale)) - (viewport.Y - MOUSE_OFFSET_DISTANCE.Y)
		else
			offset = 0
		end
		self.updateYOffset(-offset)
	end

	self.update = function()
		self.updatePosition(UserInputService:GetMouseLocation())
		self.updateXAnchorPoint(self.XanchorPointSpring.Position)
	end

	self.checkFirstAnchorPoint()
end

function Tooltip:didMount()
	Promise.defer(function()
		if self and not self.unmounted then
			self:setState({
				visible = true,
			})
		end
	end)
end

function Tooltip:render()
	local props = self.props
	local scale = GetBestScale()

	return Roact.createElement(Roact.Portal, {
		target = game.Players.LocalPlayer.PlayerGui,
	}, {
		Tooltip = Roact.createElement("ScreenGui", {
			IgnoreGuiInset = true,
			DisplayOrder = props.DisplayOrder,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			Enabled = self.state.visible,
		}, {
			Main = Roact.createElement("Frame", {
				BackgroundTransparency = 1,
				Size = self.size:map(function(value)
					return UDim2.fromOffset(value.X * scale, value.Y * scale)
				end),
				Position = self.position:map(function(value)
					value = value + MOUSE_OFFSET_DISTANCE
					self.updateExtents(value)
					local XanchorPoint = self.XanchorPoint:getValue()
					local xValue
					if XanchorPoint > 0.5 then
						xValue = value.X - (MOUSE_OFFSET_DISTANCE.X * 2)
					else
						xValue = value.X
					end
					return UDim2.fromOffset(xValue, value.Y)
				end),
				AnchorPoint = self.XanchorPoint:map(function(value)
					return Vector2.new(value, 0)
				end),
				[Roact.Ref] = self.mainRef,
			}, {
				Offset = Roact.createElement("Frame", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Position = self.yOffset:map(function(value)
						return UDim2.fromOffset(0, value)
					end),
				}, {
					Layout = Roact.createElement("UIListLayout", {
						[Roact.Change.AbsoluteContentSize] = self.updateExtents,
						[Roact.Ref] = self.layoutRef,
					}),

					Contents = Roact.createFragment(props[Roact.Children]),
				}),
			}),
		}),

		Update = Roact.createElement(HeartbeatConnection, {
			Update = self.update,
		})
	})
end

function Tooltip:willUnmount()
	self.unmounted = true
end

return Tooltip
