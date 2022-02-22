--[[
	Draws the War Room using a ViewportFrame.
]]

local DARK = Color3.fromRGB(64, 64, 64)
local LIGHT = Color3.fromRGB(192, 192, 192)

local Roact = require(game.ReplicatedStorage.Packages.Roact)
local CreateTween = require(game.ReplicatedStorage.Packages.CreateTween)

local main = game.ReplicatedStorage.RoactElements
local ModelView = require(main.Components.Base.ModelView)
local WarRoom = game.ReplicatedStorage.Models:WaitForChild("WarRoomViewport")

local WarRoomBackground = Roact.PureComponent:extend("WarRoomBackground")
local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	Visible = t.optional(t.boolean),
	ZIndex = t.optional(t.integer),
	OnTweenCompleted = t.optional(t.callback),
})

WarRoomBackground.defaultProps = {
	Visible = true,
	ZIndex = 1,
}

function WarRoomBackground:init(props)
	assert(typecheck(props))
	self.camera = nil
	self.viewport = nil

	self.onCompleted = function(visible)
		if self.props.OnTweenCompleted then
			self.props.OnTweenCompleted(visible)
		end
	end
end

function WarRoomBackground:didUpdate(lastProps)
	if lastProps.Visible ~= self.props.Visible then
		if self.props.Visible then
			if self.camera then
				CreateTween({
					Instance = self.camera,
					EasingStyle = Enum.EasingStyle.Back,
					EasingDirection = Enum.EasingDirection.Out,
					Time = 0.5,
					Props = {
						FieldOfView = 70,
					},
				}):Play()
			end
			if self.viewport then
				local viewTween = CreateTween({
					Instance = self.viewport,
					EasingStyle = Enum.EasingStyle.Quad,
					EasingDirection = Enum.EasingDirection.Out,
					Time = 0.5,
					Props = {
						BackgroundTransparency = 0,
						ImageTransparency = 0,
					},
				})
				viewTween.Completed:Connect(function()
					self.onCompleted(true)
				end)
				viewTween:Play()
			end
		else
			if self.camera then
				CreateTween({
					Instance = self.camera,
					EasingStyle = Enum.EasingStyle.Quad,
					EasingDirection = Enum.EasingDirection.Out,
					Time = 0.5,
					Props = {
						FieldOfView = 50,
					},
				}):Play()
			end
			if self.viewport then
				local viewTween = CreateTween({
					Instance = self.viewport,
					EasingStyle = Enum.EasingStyle.Quad,
					EasingDirection = Enum.EasingDirection.Out,
					Time = 0.5,
					Props = {
						BackgroundTransparency = 1,
						ImageTransparency = 1,
					},
				})
				viewTween.Completed:Connect(function()
					self.onCompleted(false)
				end)
				viewTween:Play()
			end
		end
	end
end

function WarRoomBackground:render()
	local props = self.props

	return Roact.createElement(ModelView, {
		Model = WarRoom,
		ZIndex = props.ZIndex,
		CurrentCamera = false,
		ShowOriginal = false,
		Start = function(model, camera, viewport)
			local camPos = model:WaitForChild("CameraPos")
			local camLook = model:WaitForChild("CameraLook")
			camera.CFrame = camPos.CFrame
			camera.Focus = camLook.CFrame
			viewport.BackgroundTransparency = 0
			viewport.BackgroundColor3 = Color3.new()
			camera.FieldOfView = 70
			self.camera = camera
			self.viewport = viewport
		end,
	}, {
		Gradient = Roact.createElement("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, DARK),
				ColorSequenceKeypoint.new(0.25, DARK),
				ColorSequenceKeypoint.new(0.5, LIGHT),
				ColorSequenceKeypoint.new(1, DARK),
			}),
			[Roact.Ref] = self.gradientRef,
		}),
	})
end

return WarRoomBackground
