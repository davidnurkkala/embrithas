--[[
	Shows a MissionGroup on the map.
	If a mission is selected from here, the map will deactivate.
]]

local MissionGroupData = require(game.ReplicatedStorage.MissionGroupData)
local CreateTween = require(game.ReplicatedStorage.Packages.CreateTween)

local Roact = require(game.ReplicatedStorage.Packages.Roact)

local main = game.ReplicatedStorage.RoactElements
local MapScreen = require(main.Components.MissionSelect.MapScreen)
local AutomaticSize = require(main.Components.Base.AutomaticSize)
local BackButton = require(main.Components.MissionSelect.BackButton)
local MissionScreen = require(main.Components.MissionSelect.MissionScreen)
local GroupTweenJob = require(main.Components.Base.GroupTweenJob)

local MissionGroupScreen = Roact.PureComponent:extend("MissionGroupScreen")
local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	Active = t.optional(t.boolean),
	ZIndex = t.optional(t.integer),
	MissionInfos = t.table,
	MissionGroup = t.interface({
		Missions = t.table,
		MissionGroup = t.string,
	}),
	RecommendedMissions = t.optional(t.table),
	OnClose = t.optional(t.callback),
})

MissionGroupScreen.defaultProps = {
	Active = true,
	ZIndex = 1,
}

local function formatTitle(title)
	return string.format("%s", string.upper(title))
end

function MissionGroupScreen:init(props)
	assert(typecheck(props))
	self.darkenRef = Roact.createRef()

	self.state = {
		selectedMission = nil,
	}

	self.missionInfoById = {}
	for _, missionInfo in pairs(props.MissionInfos) do
		self.missionInfoById[missionInfo.Module.Name] = missionInfo
	end

	self.closeMap = function()
		if self.props.OnClose then
			self.props.OnClose()
		end
	end

	self.onMissionSelected = function(missionId)
		self:setState({
			selectedMission = missionId,
		})
	end

	self.closeSelected = function()
		self:setState({
			selectedMission = Roact.None,
		})
	end
end

function MissionGroupScreen:didUpdate(_, lastState)
	if lastState.selectedMission ~= self.state.selectedMission then
		local darken = self.darkenRef:getValue()
		if darken then
			if self.state.selectedMission ~= nil then
				CreateTween({
					Instance = darken,
					EasingStyle = Enum.EasingStyle.Quad,
					EasingDirection = Enum.EasingDirection.Out,
					Time = 0.3,
					Props = {
						BackgroundTransparency = 0.3,
					}
				}):Play()
			else
				CreateTween({
					Instance = darken,
					EasingStyle = Enum.EasingStyle.Quad,
					EasingDirection = Enum.EasingDirection.Out,
					Time = 0.3,
					Props = {
						BackgroundTransparency = 1,
					}
				}):Play()
			end
		end
	end
end

function MissionGroupScreen:render()
	local props = self.props
	local missionInfos = props.MissionInfos
	local missionGroup = props.MissionGroup
	local missionList = missionGroup.Missions
	local active = props.Active

	local groupId = missionGroup.MissionGroup
	local groupData = MissionGroupData[groupId]
	local groupName = groupData.Name

	local state = self.state
	local selectedMission = state.selectedMission
	local missionInfo, mission, isRecommended
	if selectedMission then
		missionList = {selectedMission}
		missionInfo = self.missionInfoById[selectedMission]
		mission = require(missionInfo.Module)
		isRecommended = props.RecommendedMissions and props.RecommendedMissions[selectedMission] or false
	end

	local mapActive = active and selectedMission == nil

	return Roact.createElement("Frame", {
		ZIndex = props.ZIndex,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		NameLabel = Roact.createElement(GroupTweenJob, {
			ZIndex = 2,
			Visible = mapActive,
			Offset = UDim2.fromOffset(0, 20),
			Time = 0.3,
			TweenIn = true,
		}, {
			Label = Roact.createElement("TextLabel", {
				Text = formatTitle(groupName),
				Font = Enum.Font.Fantasy,
				TextSize = 48,
				RichText = true,
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 0.95, 0),
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

		MapScreen = Roact.createElement(MapScreen, {
			ZIndex = 1,
			Active = mapActive,
			AnimateOpening = true,
			MissionInfos = missionInfos,
			MissionList = missionList,
			RecommendedMissions = props.RecommendedMissions,
			OnMissionSelected = self.onMissionSelected,
		}),

		-- Darkens the map when we have a selection.
		Darken = Roact.createElement("Frame", {
			ZIndex = 2,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BackgroundColor3 = Color3.new(),
			BorderSizePixel = 0,
			[Roact.Ref] = self.darkenRef,
		}),

		MissionScreen = selectedMission ~= nil and Roact.createElement(MissionScreen, {
			ZIndex = 3,
			IsRecommended = isRecommended,
			MissionInfo = missionInfo,
			Mission = mission,
		}),

		Controls = Roact.createFragment({
			CloseMap = mapActive and Roact.createElement(BackButton, {
				OnActivated = self.closeMap,
			}),

			CloseSelected = selectedMission ~= nil and Roact.createElement(BackButton, {
				OnActivated = self.closeSelected,
			}),
		}),
	})
end

return MissionGroupScreen
