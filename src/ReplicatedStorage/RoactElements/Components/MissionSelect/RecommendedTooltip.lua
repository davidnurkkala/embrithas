--[[
	Shows that a mission is recommended as a tooltip.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)

local main = game.ReplicatedStorage.RoactElements
local GuiObjectContext = require(main.Contexts.GuiObjectContext)
local BaseTooltip = require(main.Components.Base.BaseTooltip)
local DefaultHeader = require(main.Components.Tooltip.DefaultHeader)
local BodyText = require(main.Components.Tooltip.BodyText)
local BodyBulletPoints = require(main.Components.Tooltip.BodyBulletPoints)

local RecommendedTooltip = Roact.PureComponent:extend("RecommendedTooltip")
local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	Mission = t.interface({
		Level = t.integer,
	}),
})

function RecommendedTooltip:init(props)
	assert(typecheck(props))
end

function RecommendedTooltip:render()
	local GuiObject = GuiObjectContext:Get(self)

	local props = self.props
	local mission = props.Mission
	local currentLevel = GuiObject:GetService("GuiClient").Level
	local missionLevel = mission.Level

	return Roact.createElement(BaseTooltip, {
		RenderHeader = function()
			return Roact.createElement(DefaultHeader, {
				Title = "Recommended Mission",
			})
		end,

		RenderBody = function(layout)
			return Roact.createFragment({
				Description = Roact.createElement(BodyText, {
					LayoutOrder = layout(),
					Text = "This mission is recommended for you based on your level.",
				}),

				Levels = Roact.createElement(BodyBulletPoints, {
					LayoutOrder = layout(),
					Entries = {
						string.format("Player Level: %s", currentLevel),
						string.format("Mission Level: %s", missionLevel),
					},
				}),
			})
		end,
	})
end

return RecommendedTooltip
