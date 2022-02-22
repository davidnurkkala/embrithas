--[[
	Creates a tooltip for a mission given its mission info.
]]

local LOCKED_DESCRIPTION = [[Complete the requirements to reveal this mission.]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)
local MissionGroupData = require(game.ReplicatedStorage.MissionGroupData)

local main = game.ReplicatedStorage.RoactElements
local GuiObjectContext = require(main.Contexts.GuiObjectContext)
local BaseTooltip = require(main.Components.Base.BaseTooltip)
local DefaultHeader = require(main.Components.Tooltip.DefaultHeader)
local BodyText = require(main.Components.Tooltip.BodyText)
local BodyBulletPoints = require(main.Components.Tooltip.BodyBulletPoints)
local BodyHeader = require(main.Components.Tooltip.BodyHeader)
local BodyRequirements = require(main.Components.Tooltip.BodyRequirements)
local BodyRewards = require(main.Components.Tooltip.BodyRewards)
local LockedFooter = require(main.Components.Tooltip.LockedFooter)
local DeadlyFooter = require(main.Components.Tooltip.DeadlyFooter)
local RecommendedFooter = require(main.Components.Tooltip.RecommendedFooter)

local MissionTooltip = Roact.PureComponent:extend("MissionTooltip")
local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	IsRecommended = t.optional(t.boolean),
	MissionInfo = t.interface({
		Module = t.instanceIsA("ModuleScript"),
		UnmetRequirements = t.table,
	}),
	Mission = t.interface({
		Name = t.string,
		MissionType = t.string,
		MissionGroup = t.string,
		Description = t.string,
		LockedDescription = t.optional(t.string),
		PartySize = t.integer,
		Level = t.integer,
		Floors = t.table,
		Requirements = t.optional(t.table),
		Rewards = t.optional(t.table),
		FirstTimeRewards = t.optional(t.table),
		Cost = t.optional(t.table),
	}),
})

MissionTooltip.defaultProps = {
	IsRecommended = false,
}

local FooterColors = {
	Recommended = Color3.fromRGB(25, 25, 112),
	Locked = Color3.fromRGB(139, 0, 0),
	Deadly = Color3.fromRGB(128, 0, 0),
}

function MissionTooltip:init(props)
	assert(typecheck(props))
end

function MissionTooltip:render()
	local GuiObject = GuiObjectContext:Get(self)
	local LobbyClient = GuiObject:GetService("LobbyClient")

	local props = self.props
	local mission = props.Mission
	local missionInfo = props.MissionInfo
	local missionId = props.MissionInfo.Module.Name
	local currentLevel = GuiObject:GetService("GuiClient").Level
	local alignment = LobbyClient.Alignment
	local requirements = mission.Requirements and #mission.Requirements > 0 or false
	local rewards = mission.Rewards and #mission.Rewards > 0 or false
	local firstTimeRewards = mission.FirstTimeRewards and #mission.FirstTimeRewards > 0 or false
	local completed = LobbyClient:HasCompletedMission(missionId)
	local missionType = mission.MissionType

	local isLocked = #missionInfo.UnmetRequirements > 0
	local isDeadly = mission.Level >= currentLevel + 10
	local isRecommended = props.IsRecommended

	local description
	if isLocked then
		description = mission.LockedDescription or LOCKED_DESCRIPTION
	else
		description = mission.Description
	end

	local footerColor
	if isLocked then
		footerColor = FooterColors.Locked
	elseif isDeadly then
		footerColor = FooterColors.Deadly
	elseif isRecommended then
		footerColor = FooterColors.Recommended
	else
		footerColor = Color3.new()
	end

	return Roact.createElement(BaseTooltip, {
		HeaderColor = MissionGroupData[mission.MissionGroup].Color,
		RenderHeader = function()
			return Roact.createElement(DefaultHeader, {
				Title = mission.Name,
				Subtitle = string.format("Level %i %s", mission.Level, missionType),
			})
		end,

		RenderBody = function(layout)
			return Roact.createFragment({
				Description = Roact.createElement(BodyText, {
					LayoutOrder = layout(),
					Text = description,
				}),

				BulletPoints = Roact.createElement(BodyBulletPoints, {
					LayoutOrder = layout(),
					Entries = {
						string.format("Mission Type: %s", missionType),
						string.format("Party Size: %s", mission.PartySize),
						string.format("Floors: %i", #mission.Floors),
					},
				}),

				RequirementsHeader = requirements and Roact.createElement(BodyHeader, {
					LayoutOrder = layout(),
					Text = "Requirements",
				}) or nil,

				Requirements = requirements and Roact.createElement(BodyRequirements, {
					LayoutOrder = layout(),
					Requirements = mission.Requirements,
					UnmetRequirements = missionInfo.UnmetRequirements,
					Mission = mission,
					Alignment = alignment,
				}) or nil,

				FirstTimeRewardsHeader = not completed and firstTimeRewards and Roact.createElement(BodyHeader, {
					LayoutOrder = layout(),
					Text = "Rewards (First Completion)",
				}) or nil,

				FirstTimeRewards = not completed and firstTimeRewards and Roact.createElement(BodyRewards, {
					LayoutOrder = layout(),
					Rewards = mission.FirstTimeRewards,
				}) or nil,

				RewardsHeader = rewards and Roact.createElement(BodyHeader, {
					LayoutOrder = layout(),
					Text = "Rewards",
				}) or nil,

				Rewards = rewards and Roact.createElement(BodyRewards, {
					LayoutOrder = layout(),
					Rewards = mission.Rewards,
				}) or nil,
			})
		end,

		FooterColor = footerColor,
		RenderFooter = (isLocked or isDeadly or isRecommended) and function()
			if isLocked then
				return Roact.createElement(LockedFooter)
			elseif isDeadly then
				return Roact.createElement(DeadlyFooter, {
					RecommendedLevel = mission.Level,
					CurrentLevel = currentLevel,
				})
			elseif isRecommended then
				return Roact.createElement(RecommendedFooter)
			else
				return nil
			end
		end or nil,
	})
end

return MissionTooltip
