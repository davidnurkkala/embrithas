--[[
	Shows an icon for a given mission group.
]]

local ICON_SIZE = UDim2.fromOffset(546, 120)
local RECOMMENDED = "Recommended Missions"

local Roact = require(game.ReplicatedStorage.Packages.Roact)
local CreateTween = require(game.ReplicatedStorage.Packages.CreateTween)
local MissionGroupData = require(game.ReplicatedStorage.MissionGroupData)

local main = game.ReplicatedStorage.RoactElements
local GuiObjectContext = require(main.Contexts.GuiObjectContext)
local MissionGroupTooltip = require(main.Components.MissionSelect.MissionGroupTooltip)
local Shimmer = require(main.Components.Base.Shimmer)

local MissionGroupIcon = Roact.PureComponent:extend("MissionGroupIcon")
local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	Active = t.optional(t.boolean),
	OnActivated = t.optional(t.callback),
	Position = t.optional(t.UDim2),
	MissionInfos = t.table,
	MissionGroup = t.interface({
		Missions = t.table,
		MissionGroup = t.string,
	}),
})

MissionGroupIcon.defaultProps = {
	Active = true,
	Position = UDim2.new(),
}

local function formatTitle(title)
	return string.format("<b>%s</b>", string.upper(title))
end

function MissionGroupIcon:init(props)
	assert(typecheck(props))
	self.iconRef = Roact.createRef()
	self.gradientRef = Roact.createRef()
	self.state = {
		hovered = false,
	}

	self.mouseEnter = function()
		self:setState({
			hovered = true,
		})
	end

	self.mouseLeave = function()
		self:setState({
			hovered = false,
		})
	end

	self.onActivated = function()
		if self.props.Active and self.props.OnActivated then
			local props = self.props
			local missionGroup = props.MissionGroup
			local groupData = MissionGroupData[missionGroup.MissionGroup]
			local groupName = groupData.Name
			if groupName == RECOMMENDED then
				local LobbyClient = GuiObjectContext:GetLobbyClient(self)
				if LobbyClient.IsTutorial then
					LobbyClient.MissionExamined:Fire()
				end
			end
			self.props.OnActivated()
		end
	end

	self.missionInfoById = {}
	for _, missionInfo in pairs(props.MissionInfos) do
		self.missionInfoById[missionInfo.Module.Name] = missionInfo
	end
end

function MissionGroupIcon.getDerivedStateFromProps(nextProps, lastState)
	if lastState.hovered and not nextProps.Active then
		return {
			hovered = false,
		}
	else
		return nil
	end
end

function MissionGroupIcon:didUpdate(_, lastState)
	if self.state.hovered ~= lastState.hovered then
		local icon = self.iconRef:getValue()
		if icon then
			if self.state.hovered then
				CreateTween({
					Instance = icon,
					EasingDirection = Enum.EasingDirection.Out,
					EasingStyle = Enum.EasingStyle.Back,
					Time = 0.25,
					Props = {
						Size = UDim2.fromOffset(88, 110),
					},
				}):Play()
			else
				CreateTween({
					Instance = icon,
					EasingDirection = Enum.EasingDirection.Out,
					EasingStyle = Enum.EasingStyle.Quad,
					Time = 0.25,
					Props = {
						Size = UDim2.fromOffset(80, 100),
					},
				}):Play()
			end
		end

		local gradient = self.gradientRef:getValue()
		if gradient then
			if self.state.hovered then
				CreateTween({
					Instance = gradient,
					EasingDirection = Enum.EasingDirection.Out,
					EasingStyle = Enum.EasingStyle.Quad,
					Time = 0.25,
					Props = {
						Offset = Vector2.new(0, 0),
					},
				}):Play()
			else
				CreateTween({
					Instance = gradient,
					EasingDirection = Enum.EasingDirection.Out,
					EasingStyle = Enum.EasingStyle.Quad,
					Time = 0.25,
					Props = {
						Offset = Vector2.new(0, 0.5),
					},
				}):Play()
			end
		end
	end
end

function MissionGroupIcon:render()
	local GuiObject = GuiObjectContext:Get(self)
	local currentLevel = GuiObject:GetService("GuiClient").Level
	local state = self.state
	local hovered = state.hovered

	local props = self.props
	local position = props.Position
	local missionGroup = props.MissionGroup
	local groupData = MissionGroupData[missionGroup.MissionGroup]
	local groupColor = groupData.Color
	local groupName = groupData.Name
	local description = groupData.Description
	local active = props.Active

	local missionList = missionGroup.Missions
	local minLevel, maxLevel

	for _, missionId in ipairs(missionList) do
		local missionInfo = require(self.missionInfoById[missionId].Module)
		local level = missionInfo.Level
		minLevel = minLevel and math.min(minLevel, level) or level
		maxLevel = maxLevel and math.max(maxLevel, level) or level
	end

	local isDeadly = minLevel >= currentLevel + 10
	local levelInfo = minLevel == maxLevel
		and string.format("Level %i", minLevel)
		or string.format("Levels %i-%i", minLevel, maxLevel)

	return Roact.createFragment({
		Background = Roact.createElement("ImageButton", {
			Size = ICON_SIZE,
			Position = position,
			BackgroundColor3 = Color3.new(1, 1, 1),
			AutoButtonColor = false,
			[Roact.Event.MouseEnter] = self.mouseEnter,
			[Roact.Event.MouseLeave] = self.mouseLeave,
			[Roact.Event.Activated] = self.onActivated,
		}, {
			Shimmer = groupName == RECOMMENDED and maxLevel <= 1 and Roact.createElement(Shimmer, {
				ZIndex = 2,
			}, {
				Corner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0.25, 0),
				}),
			}),

			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0.25, 0),
			}),

			Gradient = Roact.createElement("UIGradient", {
				Offset = Vector2.new(0, 0.5),
				Rotation = 90,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 34, 34)),
					ColorSequenceKeypoint.new(1, groupColor),
				}),
				[Roact.Ref] = self.gradientRef,
			}),

			InnerContents = Roact.createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
			}, {
				Padding = Roact.createElement("UIPadding", {
					PaddingLeft = UDim.new(0, 20),
					PaddingRight = UDim.new(0, 20),
					PaddingTop = UDim.new(0, 10),
					PaddingBottom = UDim.new(0, 10),
				}),

				Icon = Roact.createElement("ImageLabel", {
					Image = "rbxassetid://7036710853",
					Size = UDim2.fromOffset(80, 100),
					Position = UDim2.new(0, 40, 0.5, 0),
					AnchorPoint = Vector2.new(0.5, 0.5),
					ScaleType = Enum.ScaleType.Crop,
					ImageColor3 = groupColor,
					BackgroundTransparency = 1,
					[Roact.Ref] = self.iconRef,
				}),

				Text = Roact.createElement("TextLabel", {
					Text = formatTitle(groupName),
					RichText = true,
					Font = Enum.Font.Fantasy,
					TextSize = 36,
					TextColor3 = Color3.new(1, 1, 1),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					Position = UDim2.fromOffset(100, 0, 0, 0),
					Size = UDim2.new(1, -100, 1, 0),
					BackgroundTransparency = 1,
					TextWrapped = true,
				}),

				LevelInfo = Roact.createElement("TextLabel", {
					Text = levelInfo,
					Font = Enum.Font.GothamSemibold,
					TextSize = 24,
					TextColor3 = isDeadly and Color3.new(1, 0, 0) or Color3.new(0.8, 0.8, 0.8),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Bottom,
					Position = UDim2.fromOffset(100, 0, 0, 0),
					Size = UDim2.new(1, -100, 1, 0),
					BackgroundTransparency = 1,
				}),
			}),

			Tooltip = hovered and description ~= nil and active
				and Roact.createElement(MissionGroupTooltip, {
				GroupData = groupData,
				LevelInfo = levelInfo,
			}),
		}),
	})
end

return MissionGroupIcon
