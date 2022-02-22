--[[
	Controls for selecting a MissionGroup.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)

local main = game.ReplicatedStorage.RoactElements
local MissionGroupList = require(main.Components.MissionSelect.MissionGroupList)
local GroupTweenJob = require(main.Components.Base.GroupTweenJob)

local MissionSelectControls = Roact.PureComponent:extend("MissionSelectControls")
local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	Visible = t.optional(t.boolean),
	Active = t.optional(t.boolean),
	MissionInfos = t.table,
	MissionData = t.table,
	OnGroupSelected = t.callback,
})

MissionSelectControls.defaultProps = {
	Visible = true,
	Active = true,
}

function MissionSelectControls:init(props)
	assert(typecheck(props))
	self.state = {
		showLeft = true,
		showRight = true,
	}

	self.onSelected = function(group)
		return function(groupIndex)
			return function()
				self.props.OnGroupSelected(group, groupIndex)
			end
		end
	end

	self.onLeftCompleted = function(visible)
		self:setState({
			showLeft = visible,
		})
	end

	self.onRightCompleted = function(visible)
		self:setState({
			showRight = visible,
		})
	end
end

function MissionSelectControls.getDerivedStateFromProps(nextProps)
	if nextProps.Visible then
		return {
			showLeft = true,
			showRight = true,
		}
	end
end

function MissionSelectControls:render()
	local props = self.props
	local missionInfos = props.MissionInfos
	local missionData = props.MissionData
	local visible = props.Visible
	local active = props.Active

	local state = self.state
	local showLeft = state.showLeft
	local showRight = state.showRight

	return Roact.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
	}, {
		AspectRatio = Roact.createElement("UIAspectRatioConstraint", {
			AspectRatio = 16 / 9,
			AspectType = Enum.AspectType.FitWithinMaxSize,
		}),

		RightElements = showRight and Roact.createElement(GroupTweenJob, {
			Offset = UDim2.fromOffset(100, 0),
			Visible = visible,
			TweenIn = true,
			Time = 0.5,
			OnCompleted = self.onRightCompleted,
		}, {
			Story = Roact.createElement(MissionGroupList, {
				Active = active,
				Position = UDim2.fromScale(0.975, 0.7),
				AnchorPoint = Vector2.new(1, 1),
				Rows = 4,
				Columns = 2,
				Title = "STORY",
				MissionInfos = missionInfos,
				MissionGroups = missionData.Story,
				OnGroupSelected = self.onSelected("Story"),
			}),

			Expeditions = Roact.createElement(MissionGroupList, {
				Active = active,
				Position = UDim2.fromScale(0.975, 0.95),
				AnchorPoint = Vector2.new(1, 1),
				Rows = 1,
				Columns = 2,
				Title = "EXPEDITIONS",
				MissionInfos = missionInfos,
				MissionGroups = missionData.Expeditions,
				OnGroupSelected = self.onSelected("Expeditions"),
			}),
		}),

		LeftElements = showLeft and Roact.createElement(GroupTweenJob, {
			Offset = UDim2.fromOffset(-100, 0),
			Visible = visible,
			TweenIn = true,
			Time = 0.5,
			OnCompleted = self.onLeftCompleted,
		}, {
			Tutorials = Roact.createElement(MissionGroupList, {
				Active = active,
				Position = UDim2.fromScale(0.025, 0.7),
				AnchorPoint = Vector2.new(0, 1),
				Rows = 1,
				Columns = 1,
				Title = "TUTORIALS",
				MissionInfos = missionInfos,
				MissionGroups = missionData.Tutorials,
				OnGroupSelected = self.onSelected("Tutorials"),
			}),

			Raids = Roact.createElement(MissionGroupList, {
				Active = active,
				Position = UDim2.fromScale(0.025, 0.95),
				AnchorPoint = Vector2.new(0, 1),
				Rows = 1,
				Columns = 1,
				Title = "RAIDS",
				MissionInfos = missionInfos,
				MissionGroups = missionData.Raids,
				OnGroupSelected = self.onSelected("Raids"),
			}),
		}),
	})
end

return MissionSelectControls
