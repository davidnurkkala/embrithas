--[[
	Creates a tooltip for a mission group given its info.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)

local main = game.ReplicatedStorage.RoactElements
local BaseTooltip = require(main.Components.Base.BaseTooltip)
local DefaultHeader = require(main.Components.Tooltip.DefaultHeader)
local BodyText = require(main.Components.Tooltip.BodyText)

local MissionGroupTooltip = Roact.PureComponent:extend("MissionGroupTooltip")
local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	GroupData = t.interface({
		Name = t.string,
		Description = t.string,
		Color = t.Color3,
	}),
	LevelInfo = t.string,
})

function MissionGroupTooltip:init(props)
	assert(typecheck(props))
end

function MissionGroupTooltip:render()
	local props = self.props
	local groupData = props.GroupData
	local levelInfo = props.LevelInfo

	return Roact.createElement(BaseTooltip, {
		HeaderColor = groupData.Color,
		RenderHeader = function()
			return Roact.createElement(DefaultHeader, {
				Title = groupData.Name,
				Subtitle = levelInfo,
			})
		end,

		RenderBody = function(layout)
			return Roact.createFragment({
				Description = Roact.createElement(BodyText, {
					LayoutOrder = layout(),
					Text = groupData.Description,
				}),
			})
		end,
	})
end

return MissionGroupTooltip
