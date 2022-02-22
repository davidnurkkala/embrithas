--[[
	Transitions to and from a black frame.
	The OnTransition function yields and waits to be ready.
]]

local CreateTween = require(game.ReplicatedStorage.Packages.CreateTween)
local Roact = require(game.ReplicatedStorage.Packages.Roact)

local BlackFrameTransition = Roact.PureComponent:extend("BlackFrameTransition")

local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	FadeTime = t.number,
	OnTransition = t.callback,
	OnCompleted = t.callback,
})

function BlackFrameTransition:init(props)
	assert(typecheck(props))
	self.frameRef = Roact.createRef()
	self.mounted = true
end

function BlackFrameTransition:didMount()
	local frame = self.frameRef:getValue()
	local props = self.props
	local tweenIn = CreateTween({
		Instance = frame,
		Props = {
			BackgroundTransparency = 0,
		},
		Time = props.FadeTime,
		EasingStyle = Enum.EasingStyle.Linear,
	})
	tweenIn.Completed:Connect(function()
		if not self.mounted then return end
		props.OnTransition()
		local tweenOut = CreateTween({
			Instance = frame,
			Props = {
				BackgroundTransparency = 1,
			},
			Time = props.FadeTime,
			EasingStyle = Enum.EasingStyle.Linear,
		})
		tweenOut.Completed:Connect(function()
			if not self.mounted then return end
			props.OnCompleted()
		end)
		tweenOut:Play()
	end)
	tweenIn:Play()
end

function BlackFrameTransition:render()
	return Roact.createElement("Frame", {
		ZIndex = 15,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(),
		[Roact.Ref] = self.frameRef,
	})
end

function BlackFrameTransition:willUnmount()
	self.mounted = false
end

return BlackFrameTransition
