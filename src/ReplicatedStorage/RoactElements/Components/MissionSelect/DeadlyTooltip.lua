--[[
	Shows that a mission is deadly as a tooltip.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)

local main = game.ReplicatedStorage.RoactElements
local GuiObjectContext = require(main.Contexts.GuiObjectContext)
local BaseTooltip = require(main.Components.Base.BaseTooltip)
local DefaultHeader = require(main.Components.Tooltip.DefaultHeader)
local BodyText = require(main.Components.Tooltip.BodyText)
local BodyBulletPoints = require(main.Components.Tooltip.BodyBulletPoints)

local DeadlyTooltip = Roact.PureComponent:extend("DeadlyTooltip")
local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	Mission = t.interface({
		Level = t.integer,
	}),
})

function DeadlyTooltip:init(props)
	assert(typecheck(props))
end

function DeadlyTooltip:render()
	local GuiObject = GuiObjectContext:Get(self)

	local props = self.props
	local mission = props.Mission
	local currentLevel = GuiObject:GetService("GuiClient").Level
	local missionLevel = mission.Level

	return Roact.createElement(BaseTooltip, {
		RenderHeader = function()
			return Roact.createElement(DefaultHeader, {
				Title = "Low Player Level",
			})
		end,

		RenderBody = function(layout)
			return Roact.createFragment({
				Description = Roact.createElement(BodyText, {
					LayoutOrder = layout(),
					Text = "You are underleveled for this mission. You can still attempt it, but it may be impossible.",
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

return DeadlyTooltip
