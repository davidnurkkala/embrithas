--[[
	A customizable, basic tooltip.
	Consists of a header, body, and footer.
	Fixed width based on total screen width, sizes vertically from contents.
	Design for fitting into a 500-px-wide frame.
]]

local PADDING = 20
local PADDING2 = 10
local INNER_PADDING = UDim.new(0, PADDING)
local HEADER_PADDING = UDim.new(0, PADDING2)

local Roact = require(game.ReplicatedStorage.Packages.Roact)
local GetBestScale = require(game.ReplicatedStorage.Packages.GetBestScale)

local Tooltip = require(script.Parent.Tooltip)
local BaseTooltip = Roact.PureComponent:extend("BaseTooltip")

local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	HeaderColor = t.optional(t.Color3),
	FooterColor = t.optional(t.Color3),
	RenderHeader = t.optional(t.callback),
	RenderBody = t.optional(t.callback),
	RenderFooter = t.optional(t.callback),
})

BaseTooltip.defaultProps = {
	HeaderColor = Color3.new(),
	FooterColor = Color3.new(),
}

function BaseTooltip:init(props)
	assert(typecheck(props))
end

function BaseTooltip:render()
	local props = self.props
	local scale = GetBestScale()

	local layoutOrder = 0
	local function layout()
		layoutOrder = layoutOrder + 1
		return layoutOrder
	end

	local header = props.RenderHeader and props.RenderHeader() or nil
	local body = props.RenderBody and props.RenderBody(layout) or nil
	local footer = props.RenderFooter and props.RenderFooter() or nil

	return Roact.createElement(Tooltip, {}, {
		Extents = Roact.createElement("Frame", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.fromOffset(500, 0),
		}, {
			Scale = Roact.createElement("UIScale", {
				Scale = scale,
			}),

			Layout = Roact.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			Header = props.RenderHeader and Roact.createElement("Frame", {
				LayoutOrder = 1,
				BorderSizePixel = 0,
				BackgroundColor3 = props.HeaderColor,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromScale(1, 0),
			}, {
				Padding = Roact.createElement("UIPadding", {
					PaddingTop = INNER_PADDING,
					PaddingBottom = HEADER_PADDING,
					PaddingLeft = INNER_PADDING,
					PaddingRight = INNER_PADDING,
				}),

				Contents = Roact.createFragment(header),
			}),

			Body = props.RenderBody and Roact.createElement("Frame", {
				LayoutOrder = 2,
				BorderSizePixel = 0,
				BackgroundTransparency = 0.1,
				BackgroundColor3 = Color3.fromRGB(16, 12, 8),
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromScale(1, 0),
			}, {
				Padding = Roact.createElement("UIPadding", {
					PaddingTop = HEADER_PADDING,
					PaddingBottom = INNER_PADDING,
					PaddingLeft = INNER_PADDING,
					PaddingRight = INNER_PADDING,
				}),

				Layout = Roact.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = HEADER_PADDING,
				}),

				Contents = Roact.createFragment(body),
			}),

			Footer = props.RenderFooter and Roact.createElement("Frame", {
				LayoutOrder = 3,
				BorderSizePixel = 0,
				BackgroundColor3 = props.FooterColor,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromScale(1, 0),
			}, {
				Padding = Roact.createElement("UIPadding", {
					PaddingTop = HEADER_PADDING,
					PaddingBottom = INNER_PADDING,
					PaddingLeft = INNER_PADDING,
					PaddingRight = INNER_PADDING,
				}),

				Contents = Roact.createFragment(footer),
			}),
		}),
	})
end

return BaseTooltip
