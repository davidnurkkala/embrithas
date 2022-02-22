--[[
	A component which can be placed under a TextLabel to scale the text.
	Scales text vertically based on a fixed width.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)
local Promise = require(game.ReplicatedStorage.Packages.Promise)
local GetBestScale = require(game.ReplicatedStorage.Packages.GetBestScale)

local AutomaticSize = Roact.PureComponent:extend("AutomaticSize")
local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	ScaleWidth = t.optional(t.boolean),
	PaddingWidth = t.optional(t.integer),
	PaddingHeight = t.optional(t.integer),
})

AutomaticSize.defaultProps = {
	ScaleWidth = false,
	PaddingWidth = 0,
	PaddingHeight = 0,
}

function AutomaticSize:init(props)
	assert(typecheck(props))
	self.catchRef = Roact.createRef()
end

function AutomaticSize:didMount()
	Promise.defer(function()
		if self and self.catchRef and not self.unmounted then
			local catch = self.catchRef:getValue()
			if catch and catch.Parent then
				local props = self.props
				local label = catch.Parent
				local widthScale = GetBestScale()
				if props.ScaleWidth then
					label.Size = UDim2.fromOffset(
						label.TextBounds.X / widthScale + props.PaddingWidth,
						label.TextBounds.Y / widthScale + props.PaddingHeight
					)
				else
					label.Size = UDim2.new(
						label.Size.X.Scale,
						label.Size.X.Offset,
						0,
						label.TextBounds.Y / widthScale + props.PaddingHeight
					)
				end
			end
		end
	end)
end

function AutomaticSize:render()
	return Roact.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		[Roact.Ref] = self.catchRef,
	})
end

function AutomaticSize:willUnmount()
	self.unmounted = true
end

return AutomaticSize
