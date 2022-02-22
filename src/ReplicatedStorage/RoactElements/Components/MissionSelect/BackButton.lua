--[[
	Displays a non-scaled Back button for the Mission Select screen.
	Follows the design of the generic UI buttons for the main UI.
]]

local Camera = workspace.CurrentCamera
local Roact = require(game.ReplicatedStorage.Packages.Roact)
local LocalPlayer = game.Players.LocalPlayer

local main = game.ReplicatedStorage.RoactElements
local GuiObjectContext = require(main.Contexts.GuiObjectContext)
local ButtonPressConnection = require(main.Components.Signal.ButtonPressConnection)

local BackButton = Roact.PureComponent:extend("BackButton")
local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	Text = t.optional(t.string),
	OnActivated = t.callback,
})

BackButton.defaultProps = {
	Text = "Back",
}

function BackButton:init(props)
	assert(typecheck(props))
end

function BackButton:render()
	local props = self.props
	local GuiObject = GuiObjectContext:Get(self)
	local currentScale = GuiObject:GetService("OptionsClient").Options.UIScaling
	local currentPadding = 4

	if Camera.ViewportSize.X >= 1024 then
		currentScale = currentScale + 0.4
		currentPadding = 8
	end

	return Roact.createElement(Roact.Portal, {
		target = LocalPlayer.PlayerGui,
	}, {
		BackButton = Roact.createElement("ScreenGui", {
			IgnoreGuiInset = true,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			DisplayOrder = 2,
		}, {
			Padding = Roact.createElement("UIPadding", {
				PaddingRight = UDim.new(0, currentPadding),
				PaddingBottom = UDim.new(0, currentPadding),
			}),

			UIScale = Roact.createElement("UIScale", {
				Scale = currentScale,
			}),

			Button = Roact.createElement("TextButton", {
				AnchorPoint = Vector2.new(1, 1),
				Size = UDim2.fromOffset(96, 24),
				Position = UDim2.fromScale(1, 1),
				Text = props.Text,
				Font = Enum.Font.GothamBold,
				TextSize = 12,
				TextColor3 = Color3.new(1, 1, 1),
				BackgroundColor3 = Color3.new(),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 1,
				BorderMode = Enum.BorderMode.Inset,
				[Roact.Event.Activated] = props.OnActivated,
			}, {
				KeyboardButtonLabel = Roact.createElement("TextLabel", {
					AnchorPoint = Vector2.new(1, 0.5),
					Size = UDim2.fromOffset(18, 18),
					Position = UDim2.new(0, -4, 0.5, 0),
					Text = "E",
					Font = Enum.Font.GothamBold,
					TextSize = 12,
					TextColor3 = Color3.new(1, 1, 1),
					BackgroundColor3 = Color3.new(),
					BackgroundTransparency = 0.5,
					BorderColor3 = Color3.new(1, 1, 1),
					BorderSizePixel = 1,
					BorderMode = Enum.BorderMode.Inset,
					TextStrokeTransparency = 0,
					TextStrokeColor3 = Color3.new(),
				}),
			}),
		}),

		KeyShortcut = Roact.createElement(ButtonPressConnection, {
			KeyCode = Enum.KeyCode.E,
			Callback = props.OnActivated,
		}),
	})
end

return BackButton
