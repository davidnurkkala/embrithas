--[[
	Contents scaled to match 1920x1080 at any input scale.
	Aspect ratio locked and centered on the screen.
	NOTE: Fullscreen elements should include a larger background
	to accomodate unusual screen sizes.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)

local ScaledContents = Roact.PureComponent:extend("ScaledContents")
local main = game.ReplicatedStorage.RoactElements
local GetBestScale = require(game.ReplicatedStorage.Packages.GetBestScale)
local Connection = require(main.Components.Signal.Connection)

function ScaledContents:init()
	self.state = {
		viewportSize = workspace.CurrentCamera.ViewportSize
	}

	self.updateViewportSize = function()
		self:setState({
			viewportSize = workspace.CurrentCamera.ViewportSize,
		})
	end
end

function ScaledContents:render()
	local state = self.state
	local viewportSize = state.viewportSize

	local width = viewportSize.X
	local height = viewportSize.Y
	local scale = GetBestScale()

	return Roact.createElement("Frame", {
		Size = UDim2.fromOffset(width / scale, height / scale),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
	}, {
		Scale = Roact.createElement("UIScale", {
			Scale = scale,
		}),

		Children = Roact.createElement("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, self.props[Roact.Children]),

		SizeChanged = Roact.createElement(Connection, {
			Signal = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"),
			Callback = self.updateViewportSize,
		}),
	})
end

return ScaledContents
