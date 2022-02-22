--[[
	Shows a mission's in-depth details.
	Used to review a mission before selecting it.
]]

local LOCKED_DESCRIPTION = [[Complete the requirements to reveal this mission.]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)

local main = game.ReplicatedStorage.RoactElements
local GuiObjectContext = require(main.Contexts.GuiObjectContext)
local SelectMissionContext = require(main.Contexts.SelectMissionContext)
local AutomaticSize = require(main.Components.Base.AutomaticSize)
local HoverLabel = require(main.Components.MissionSelect.HoverLabel)
local RequirementsTooltip = require(main.Components.MissionSelect.RequirementsTooltip)
local DeadlyTooltip = require(main.Components.MissionSelect.DeadlyTooltip)
local RecommendedTooltip = require(main.Components.MissionSelect.RecommendedTooltip)
local FloorsTooltip = require(main.Components.MissionSelect.FloorsTooltip)
local RewardsList = require(main.Components.MissionSelect.RewardsList)
local GroupTweenJob = require(main.Components.Base.GroupTweenJob)
local Shimmer = require(main.Components.Base.Shimmer)

local MissionScreen = Roact.PureComponent:extend("MissionScreen")
local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	ZIndex = t.optional(t.integer),
	Active = t.optional(t.boolean),
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

MissionScreen.defaultProps = {
	ZIndex = 1,
	Active = true,
	IsRecommended = false,
}

local function formatTitle(title)
	return string.format("<b>%s</b>", string.upper(title))
end

function MissionScreen:init(props)
	assert(typecheck(props))

	self.showStats = function()
		local GuiObject = GuiObjectContext:Get(self)
		local LobbyClient = GuiObject:GetService("LobbyClient")
		local missionInfo = self.props.MissionInfo
		local missionId = missionInfo.Module.Name
		local missionLog = LobbyClient:GetMissionLogEntry(missionId, "Rookie")
		LobbyClient:ShowMissionStats(missionId, missionLog, "Rookie")
	end

	self.selectMission = function()
		local selectFunc = SelectMissionContext:Get(self)
		local missionInfo = self.props.MissionInfo
		local mission = self.props.Mission

		local expansionPack = nil
		if mission.RequiredExpansion then
			local GuiObject = GuiObjectContext:Get(self)
			local LobbyClient = GuiObject:GetService("LobbyClient")
			if not LobbyClient:IsExpansionOwned(mission.RequiredExpansion) then
				expansionPack = mission.RequiredExpansion
			end
		end

		selectFunc(missionInfo.Module.Name, expansionPack)
	end
end

function MissionScreen:render()
	local GuiObject = GuiObjectContext:Get(self)
	local LobbyClient = GuiObject:GetService("LobbyClient")

	local props = self.props
	local mission = props.Mission
	local missionInfo = props.MissionInfo
	local missionId = props.MissionInfo.Module.Name

	local currentLevel = GuiObject:GetService("GuiClient").Level
	local isLocked = #missionInfo.UnmetRequirements > 0
	local isDeadly = mission.Level >= currentLevel + 10
	local isRecommended = props.IsRecommended
	local completed = LobbyClient:HasCompletedMission(missionId)

	local rewards = mission.Rewards and #mission.Rewards > 0 or false
	local firstTimeRewards = mission.FirstTimeRewards and #mission.FirstTimeRewards > 0 or false

	local description
	if isLocked then
		description = mission.LockedDescription or LOCKED_DESCRIPTION
	else
		description = mission.Description
	end

	local layout = 0
	local getLayout = function()
		layout = layout + 1
		return layout
	end

	return Roact.createElement(GroupTweenJob, {
		ZIndex = props.ZIndex,
		Time = 0.3,
		Offset = UDim2.fromOffset(-100, 0),
		Visible = true,
		TweenIn = true,
	}, {
		Padding = Roact.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 100),
			PaddingBottom = UDim.new(0.05, 0),
		}),

		Layout = Roact.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Vertical,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			Padding = UDim.new(0, 10),
		}),

		Name = Roact.createElement("TextLabel", {
			LayoutOrder = getLayout(),
			Text = formatTitle(mission.Name),
			Font = Enum.Font.Fantasy,
			TextSize = 76,
			RichText = true,
			BackgroundTransparency = 1,
			TextColor3 = Color3.new(1, 1, 1),
		}, {
			AutomaticSize = Roact.createElement(AutomaticSize, {
				ScaleWidth = true,
			}),
		}),

		Description = Roact.createElement("TextLabel", {
			LayoutOrder = getLayout(),
			Text = description,
			Font = Enum.Font.Merriweather,
			TextSize = 32,
			RichText = true,
			BackgroundTransparency = 1,
			TextColor3 = Color3.new(1, 1, 1),
			Size = UDim2.fromOffset(1820, 0),
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
		}, {
			AutomaticSize = Roact.createElement(AutomaticSize),
		}),

		Floors = mission.Floors and #mission.Floors > 0 and Roact.createElement(HoverLabel, {
			LayoutOrder = getLayout(),
			Text = string.format("%i Floor%s (Hover to Reveal)", #mission.Floors,
				#mission.Floors == 1 and "" or "s"),
		}, {
			Tooltip = Roact.createElement(FloorsTooltip, {
				Mission = mission,
			}),
		}),

		FirstTimeRewards = firstTimeRewards and Roact.createFragment({
			FirstTimeRewardsHeader = Roact.createElement("TextLabel", {
				LayoutOrder = getLayout(),
				Text = formatTitle("Rewards (First Completion)"),
				Font = Enum.Font.Fantasy,
				TextSize = 42,
				RichText = true,
				BackgroundTransparency = 1,
				TextColor3 = Color3.new(1, 1, 1),
			}, {
				AutomaticSize = Roact.createElement(AutomaticSize, {
					ScaleWidth = true,
				}),
			}),

			FirstRewardsList = Roact.createElement(RewardsList, {
				LayoutOrder = getLayout(),
				Rewards = mission.FirstTimeRewards,
				Claimed = completed,
			}),
		}),

		EachTimeRewards = rewards and Roact.createFragment({
			EachTimeRewardsHeader = Roact.createElement("TextLabel", {
				LayoutOrder = getLayout(),
				Text = formatTitle("Rewards (Each Completion)"),
				Font = Enum.Font.Fantasy,
				TextSize = 42,
				RichText = true,
				BackgroundTransparency = 1,
				TextColor3 = Color3.new(1, 1, 1),
			}, {
				AutomaticSize = Roact.createElement(AutomaticSize, {
					ScaleWidth = true,
				}),
			}),

			EachRewardsList = Roact.createElement(RewardsList, {
				LayoutOrder = getLayout(),
				Rewards = mission.Rewards,
			}),
		}),

		Buttons = Roact.createElement("Frame", {
			LayoutOrder = getLayout(),
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 70),
		}, {
			Layout = Roact.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 20),
			}),

			StatsButton = Roact.createElement("TextButton", {
				LayoutOrder = 1,
				Size = UDim2.fromOffset(150, 70),
				Text = "Stats",
				Font = Enum.Font.GothamBold,
				TextSize = 32,
				TextColor3 = Color3.new(1, 1, 1),
				BackgroundColor3 = Color3.new(),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 1,
				BorderMode = Enum.BorderMode.Inset,
				[Roact.Event.Activated] = self.showStats,
			}),

			SelectButton = not isLocked and Roact.createElement("TextButton", {
				LayoutOrder = 2,
				Size = UDim2.fromOffset(300, 70),
				Text = "Select Mission",
				Font = Enum.Font.GothamBold,
				TextSize = 32,
				TextColor3 = Color3.new(1, 1, 1),
				BackgroundColor3 = Color3.fromRGB(34, 139, 34),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 1,
				BorderMode = Enum.BorderMode.Inset,
				[Roact.Event.Activated] = self.selectMission,
			}, {
				Shimmer = Roact.createElement(Shimmer),
			}),

			SelectLocked = isLocked and Roact.createElement("TextLabel", {
				LayoutOrder = 2,
				Size = UDim2.fromOffset(300, 70),
				Text = "🔒 Mission Locked",
				Font = Enum.Font.GothamBold,
				TextSize = 32,
				TextColor3 = Color3.new(1, 1, 1),
				BackgroundColor3 = Color3.fromRGB(139, 0, 0),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 1,
				BorderMode = Enum.BorderMode.Inset,
			}),

			Recommended = isRecommended and Roact.createElement(HoverLabel, {
				LayoutOrder = 3,
				Text = "💠 Recommended Mission",
			}, {
				Tooltip = Roact.createElement(RecommendedTooltip, {
					Mission = mission,
				}),
			}),

			Locked = isLocked and Roact.createElement(HoverLabel, {
				LayoutOrder = 4,
				Text = "⚠️ Requirements Not Met",
				Color = Color3.new(1, 0, 0),
			}, {
				Tooltip = Roact.createElement(RequirementsTooltip, {
					Mission = mission,
					MissionInfo = missionInfo,
				}),
			}),

			Deadly = isDeadly and Roact.createElement(HoverLabel, {
				LayoutOrder = 5,
				Text = "⚠️ Low Player Level",
				Color = Color3.new(1, 0, 0),
			}, {
				Tooltip = Roact.createElement(DeadlyTooltip, {
					Mission = mission,
				}),
			}),
		}),
	})
end

return MissionScreen
