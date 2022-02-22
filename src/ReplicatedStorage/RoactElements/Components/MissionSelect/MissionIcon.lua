--[[
	Shows an icon on the map screen for a given mission.
]]

local Roact = require(game.ReplicatedStorage.Packages.Roact)
local CreateTween = require(game.ReplicatedStorage.Packages.CreateTween)
local MissionGroupData = require(game.ReplicatedStorage.MissionGroupData)

local main = game.ReplicatedStorage.RoactElements
local GuiObjectContext = require(main.Contexts.GuiObjectContext)
local MissionTooltip = require(main.Components.MissionSelect.MissionTooltip)
local ArrowLine = require(main.Components.MissionSelect.ArrowLine)
local ToMapSpace = require(main.Components.MissionSelect.ToMapSpace)

local MissionIcon = Roact.PureComponent:extend("MissionIcon")
local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	Position = t.optional(t.UDim2),
	Active = t.optional(t.boolean),
	AnimateOpening = t.optional(t.boolean),
	IsRecommended = t.optional(t.boolean),
	PositionsById = t.optional(t.table),
	MissionInfo = t.interface({
		Module = t.instanceIsA("ModuleScript"),
		UnmetRequirements = t.table,
	}),
	Mission = t.interface({
		Level = t.integer,
		MapPosition = t.Vector3,
		MissionGroup = t.string,
	}),
	OnActivated = t.optional(t.callback),
})

MissionIcon.defaultProps = {
	Active = true,
	IsRecommended = false,
	AnimateOpening = false,
}

function MissionIcon:init(props)
	assert(typecheck(props))
	self.iconRef = Roact.createRef()
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
		if self.props.OnActivated then
			local props = self.props
			local missionId = props.MissionInfo.Module.Name
			if missionId == "recruitTraining" then
				local LobbyClient = GuiObjectContext:GetLobbyClient(self)
				if LobbyClient.IsTutorial then
					LobbyClient.MissionSelected:Fire()
				end
			end
			self.props.OnActivated()
		end
	end
end

function MissionIcon.getDerivedStateFromProps(nextProps, lastState)
	if lastState.hovered and not nextProps.Active then
		return {
			hovered = false,
		}
	else
		return nil
	end
end

function MissionIcon:didUpdate(_, lastState)
	local icon = self.iconRef:getValue()
	if icon and self.state.hovered ~= lastState.hovered then
		if self.state.hovered then
			CreateTween({
				Instance = icon,
				EasingDirection = Enum.EasingDirection.Out,
				EasingStyle = Enum.EasingStyle.Back,
				Time = 0.25,
				Props = {
					Size = UDim2.fromOffset(125, 125),
				},
			}):Play()
		else
			CreateTween({
				Instance = icon,
				EasingDirection = Enum.EasingDirection.Out,
				EasingStyle = Enum.EasingStyle.Quad,
				Time = 0.25,
				Props = {
					Size = UDim2.fromOffset(100, 100),
				},
			}):Play()
		end
	end
end

function MissionIcon:didMount()
	if self.props.AnimateOpening then
		local icon = self.iconRef:getValue()
		if icon and not self.state.hovered then
			CreateTween({
				Instance = icon,
				EasingDirection = Enum.EasingDirection.Out,
				EasingStyle = Enum.EasingStyle.Back,
				Time = 0.5,
				Props = {
					Size = UDim2.fromOffset(100, 100),
				},
			}):Play()
		end
	end
end

function MissionIcon:render()
	local GuiObject = GuiObjectContext:Get(self)
	local LobbyClient = GuiObject:GetService("LobbyClient")

	local props = self.props
	local state = self.state
	local mission = props.Mission
	local missionInfo = props.MissionInfo
	local missionId = props.MissionInfo.Module.Name
	local worldPos = mission.MapPosition
	local mapPosition = ToMapSpace(worldPos)
	local overridePosition = props.Position or nil
	local hovered = state.hovered
	local active = props.Active
	local animate = props.AnimateOpening

	local currentLevel = GuiObject:GetService("GuiClient").Level
	local isLocked = #missionInfo.UnmetRequirements > 0
	local isDeadly = mission.Level >= currentLevel + 10
	local isRecommended = props.IsRecommended
	local completed = LobbyClient:HasCompletedMission(missionId)

	local missionIcon
	local missionIconSize
	if isLocked then
		missionIcon = "🔒"
		missionIconSize = 42
	elseif isDeadly then
		missionIcon = "☠️"
		missionIconSize = 52
	else
		missionIcon = "⚔️"
		missionIconSize = 52
	end

	local positonsById = props.PositionsById
	local unmetLines
	if hovered and positonsById and isLocked then
		for _, unmet in ipairs(missionInfo.UnmetRequirements) do
			if unmet.Type == "Mission" and positonsById[unmet.Id] then
				unmetLines = unmetLines or {}
				unmetLines[unmet.Id] = Roact.createElement(ArrowLine, {
					ZIndex = -1,
					Thickness = 5,
					FromPoint = overridePosition or mapPosition,
					ToPoint = positonsById[unmet.Id],
					Color = Color3.new(1, 0, 0),
				})
			end
		end
	end

	return Roact.createFragment({
		Line = overridePosition and Roact.createElement(ArrowLine, {
			ZIndex = -2,
			Thickness = 3,
			FromPoint = overridePosition,
			ToPoint = mapPosition,
		}),

		UnmetLines = hovered and unmetLines and Roact.createFragment(unmetLines) or nil,

		Icon = Roact.createElement("ImageLabel", {
			Image = "rbxassetid://7036710853",
			Size = animate and UDim2.fromOffset(0, 0) or UDim2.fromOffset(100, 100),
			ScaleType = Enum.ScaleType.Fit,
			Position = overridePosition or mapPosition,
			AnchorPoint = Vector2.new(0.5, 0.5),
			ImageColor3 = MissionGroupData[mission.MissionGroup].Color,
			BackgroundTransparency = 1,
			[Roact.Ref] = self.iconRef,
		}, {
			Button = active and Roact.createElement("ImageButton", {
				Size = UDim2.fromOffset(100, 100),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				ImageTransparency = 1,
				BackgroundTransparency = 1,
				[Roact.Event.MouseEnter] = self.mouseEnter,
				[Roact.Event.MouseLeave] = self.mouseLeave,
				[Roact.Event.Activated] = self.onActivated,
			}),

			TextShadow = Roact.createElement("TextLabel", {
				ZIndex = 1,
				Text = missionIcon,
				TextSize = missionIconSize,
				AutomaticSize = Enum.AutomaticSize.XY,
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
			}, {
				Gradient = Roact.createElement("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.new()),
						ColorSequenceKeypoint.new(1, Color3.new()),
					}),
				}),
			}),

			Text = Roact.createElement("TextLabel", {
				ZIndex = 2,
				Text = missionIcon,
				TextSize = missionIconSize,
				AutomaticSize = Enum.AutomaticSize.XY,
				Position = UDim2.new(0.5, 0, 0.5, -5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
			}),

			Level = Roact.createElement("TextLabel", {
				ZIndex = 3,
				Text = mission.Level,
				TextSize = 24,
				Font = Enum.Font.GothamSemibold,
				TextColor3 = (isDeadly or isLocked) and Color3.new(1, 0, 0) or Color3.new(1, 1, 1),
				BackgroundColor3 = Color3.new(),
				AutomaticSize = Enum.AutomaticSize.XY,
				Position = UDim2.new(0.5, 0, 0, 15),
				AnchorPoint = Vector2.new(0.5, 1),
				BorderSizePixel = 0,
			}, {
				Padding = Roact.createElement("UIPadding", {
					PaddingTop = UDim.new(0, 5),
					PaddingBottom = UDim.new(0, 5),
					PaddingLeft = UDim.new(0, 10),
					PaddingRight = UDim.new(0, 10),
				}),

				Corner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0.25, 0),
				}),
			}),

			CompletedIcon = completed and Roact.createElement("TextLabel", {
				ZIndex = 3,
				Text = "✅",
				TextSize = 24,
				AutomaticSize = Enum.AutomaticSize.XY,
				Position = UDim2.new(1, -20, 1, -10),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
			}),

			RecommendedIcon = isRecommended and Roact.createElement("TextLabel", {
				ZIndex = 3,
				Text = "💠",
				TextSize = 28,
				AutomaticSize = Enum.AutomaticSize.XY,
				Position = UDim2.new(0, 20, 1, -10),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
			}),

			Tooltip = hovered and active and Roact.createElement(MissionTooltip, {
				MissionInfo = missionInfo,
				Mission = mission,
				IsRecommended = isRecommended,
			}),
		}),
	})
end

return MissionIcon
