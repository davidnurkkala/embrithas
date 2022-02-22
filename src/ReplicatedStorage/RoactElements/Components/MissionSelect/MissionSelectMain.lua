--[[
	Main Mission Select screen.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)
local Cryo = require(game.ReplicatedStorage.Packages.Cryo)

local main = game.ReplicatedStorage.RoactElements
local MissionGroupScreen = require(main.Components.MissionSelect.MissionGroupScreen)
local MissionSelectControls = require(main.Components.MissionSelect.MissionSelectControls)
local WarRoomBackground = require(main.Components.MissionSelect.WarRoomBackground)
local BackButton = require(main.Components.MissionSelect.BackButton)
local GuiObjectContext = require(main.Contexts.GuiObjectContext)
local GroupTweenJob = require(main.Components.Base.GroupTweenJob)
local AutomaticSize = require(main.Components.Base.AutomaticSize)

local MissionSelectMain = Roact.PureComponent:extend("MissionSelectMain")
local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	MissionInfos = t.table,
	MissionData = t.table,
	OnClose = t.callback,
})

-- Selects recommended missions for the player based on their level.
-- These missions are both unlocked and near the player's current level.
function MissionSelectMain:getRecommendedMissions(story)
	local GuiObject = GuiObjectContext:Get(self)
	local currentLevel = GuiObject:GetService("GuiClient").Level
	local LobbyClient = GuiObject:GetService("LobbyClient")

	local recommendedMissions = {}
	local recommendedById = {}
	for _, missionGroup in ipairs(story) do
		for _, missionId in ipairs(missionGroup.Missions) do
			local missionInfo = self.missionInfoById[missionId]
			local mission = require(missionInfo.Module)
			local isLocked = #missionInfo.UnmetRequirements > 0
			local level = mission.Level
			local completed = LobbyClient:HasCompletedMission(missionId)
			if not isLocked
				and currentLevel + 5 >= level
				and (math.abs(currentLevel - level) <= 10 or not completed) then
				table.insert(recommendedMissions, missionId)
				recommendedById[missionId] = true
			end
		end
	end

	if #recommendedMissions == 0 then
		local completedTraining = LobbyClient:HasCompletedMission("recruitTraining")
		local completedGrave = LobbyClient:HasCompletedMission("rookiesGrave")
		if completedGrave then
			-- Weird edge case: We are in a desert of unlocked missions near this level.
			-- Recommend Lorithas so the player can level up.
			recommendedMissions = {"lorithasExpedition"}
			recommendedById = {lorithasExpedition = true}
		elseif completedTraining then
			recommendedMissions = {"rookiesGrave"}
			recommendedById = {rookiesGrave = true}
		else
			recommendedMissions = {"recruitTraining"}
			recommendedById = {recruitTraining = true}
		end
	end

	return {
		MissionGroup = "Recommended",
		Missions = recommendedMissions,
	}, recommendedById
end

function MissionSelectMain:init(props)
	assert(typecheck(props))
	self.missionInfoById = {}
	for _, missionInfo in pairs(props.MissionInfos) do
		self.missionInfoById[missionInfo.Module.Name] = missionInfo
	end

	local missionData = props.MissionData
	local recommended, recommendedById = self:getRecommendedMissions(missionData.Story)
	local storyList = Cryo.List.join({recommended}, missionData.Story)
	self.missionData = Cryo.Dictionary.join(missionData, {
		Story = storyList,
	})
	self.recommendedById = recommendedById

	self.state = {
		showControls = true,
		showMap = false,
		mapActive = false,
		missionGroup = nil,
		missionGroupIndex = nil,
	}

	self.onGroupSelected = function(group, groupIndex)
		self:setState({
			showMap = true,
			showControls = false,
			missionGroup = group,
			missionGroupIndex = groupIndex,
		})
	end

	self.onGroupClosed = function()
		self:setState({
			showControls = true,
			mapActive = false,
		})
	end

	self.onBackgroundTweenCompleted = function(visible)
		if visible then
			self:setState({
				showMap = false,
				missionGroup = Roact.None,
				missionGroupIndex = Roact.None,
			})
		else
			self:setState({
				mapActive = true,
			})
		end
	end
end

function MissionSelectMain:render()
	local state = self.state
	local missionGroup = state.missionGroup
	local missionGroupIndex = state.missionGroupIndex
	local showControls = state.showControls
	local showMap = state.showMap
	local mapActive = state.mapActive

	local props = self.props
	local missionInfos = props.MissionInfos
	local missionData = self.missionData
	local missions = missionGroup and missionGroupIndex
		and missionData[missionGroup][missionGroupIndex]
		or nil

	return Roact.createFragment({
		MapScreen = showMap and Roact.createElement(MissionGroupScreen, {
			ZIndex = -2,
			AnimateOpening = true,
			Active = mapActive,
			MissionInfos = missionInfos,
			MissionGroup = missions,
			RecommendedMissions = self.recommendedById,
			OnClose = self.onGroupClosed,
		}),

		Background = Roact.createElement(WarRoomBackground, {
			Visible = showControls,
			ZIndex = -1,
			OnTweenCompleted = self.onBackgroundTweenCompleted,
		}),

		NameLabel = Roact.createElement(GroupTweenJob, {
			ZIndex = 2,
			Visible = showControls,
			Offset = UDim2.fromOffset(0, -20),
			Time = 0.5,
			TweenIn = true,
		}, {
			Label = Roact.createElement("TextLabel", {
				Text = "<b>SELECT A CAMPAIGN</b>",
				Font = Enum.Font.Fantasy,
				TextSize = 54,
				RichText = true,
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0.05, 0),
				BackgroundColor3 = Color3.new(),
				BackgroundTransparency = 0.2,
				TextColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
			}, {
				AutomaticSize = Roact.createElement(AutomaticSize, {
					ScaleWidth = true,
					PaddingWidth = 120,
					PaddingHeight = 25,
				}),

				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(1, 0),
				}),
			}),
		}),

		Controls = Roact.createElement(MissionSelectControls, {
			Visible = showControls,
			Active = showControls and not showMap,
			MissionInfos = missionInfos,
			MissionData = missionData,
			OnGroupSelected = self.onGroupSelected,
		}),

		CloseMissions = showControls and not mapActive
			and Roact.createElement(BackButton, {
			Text = "Close",
			OnActivated = self.props.OnClose,
		}),
	})
end

return MissionSelectMain
