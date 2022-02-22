--[[
	Shows a mission's requirements as a tooltip.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)

local main = game.ReplicatedStorage.RoactElements
local GuiObjectContext = require(main.Contexts.GuiObjectContext)
local BaseTooltip = require(main.Components.Base.BaseTooltip)
local BodyText = require(main.Components.Tooltip.BodyText)
local BodyRequirements = require(main.Components.Tooltip.BodyRequirements)
local DefaultHeader = require(main.Components.Tooltip.DefaultHeader)

local RequirementsTooltip = Roact.PureComponent:extend("RequirementsTooltip")
local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	MissionInfo = t.interface({
		UnmetRequirements = t.table,
	}),
	Mission = t.interface({
		Requirements = t.optional(t.table),
	}),
})

function RequirementsTooltip:init(props)
	assert(typecheck(props))
end

function RequirementsTooltip:render()
	local GuiObject = GuiObjectContext:Get(self)
	local LobbyClient = GuiObject:GetService("LobbyClient")

	local props = self.props
	local mission = props.Mission
	local missionInfo = props.MissionInfo
	local alignment = LobbyClient.Alignment

	return Roact.createElement(BaseTooltip, {
		RenderHeader = function()
			return Roact.createElement(DefaultHeader, {
				Title = "Requirements Not Met",
			})
		end,

		RenderBody = function(layout)
			return Roact.createFragment({
				Description = Roact.createElement(BodyText, {
					LayoutOrder = layout(),
					Text = "Complete the following requirements to unlock the mission.",
				}),

				Requirements = Roact.createElement(BodyRequirements, {
					LayoutOrder = layout(),
					Requirements = mission.Requirements,
					UnmetRequirements = missionInfo.UnmetRequirements,
					Mission = mission,
					Alignment = alignment,
				}),
			})
		end,
	})
end

return RequirementsTooltip
