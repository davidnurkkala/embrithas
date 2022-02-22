--[[
	Shows a list of MissionGroupIcons for a given MissionGroup list.
	These will be used to make up the majority of the Mission Select screen.
]]

local ICON_SIZE = UDim2.fromOffset(546, 120)
local ELEMENT_PADDING = Vector2.new(10, 10)
local CORNER_PADDING = Vector2.new(20, 10)

local Roact = require(game.ReplicatedStorage.Packages.Roact)

local main = game.ReplicatedStorage.RoactElements
local MissionGroupIcon = require(main.Components.MissionSelect.MissionGroupIcon)

local MissionGroupList = Roact.PureComponent:extend("MissionGroupList")
local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	Title = t.string,
	Columns = t.integer,
	Rows = t.integer,
	Position = t.optional(t.UDim2),
	AnchorPoint = t.optional(t.Vector2),
	MissionInfos = t.table,
	MissionGroups = t.table,
	OnGroupSelected = t.callback,
	Active = t.optional(t.boolean),
})

MissionGroupList.defaultProps = {
	Position = UDim2.new(),
	AnchorPoint = Vector2.new(),
	Active = true,
}

function MissionGroupList:init(props)
	assert(typecheck(props))

	self.onSelected = function(groupIndex)
		return self.props.OnGroupSelected(groupIndex)
	end
end

function MissionGroupList:render()
	local props = self.props
	local position = props.Position
	local missionInfos = props.MissionInfos
	local missionGroups = props.MissionGroups

	local width = (props.Columns * ICON_SIZE.X.Offset)
		+ ((props.Columns - 1) * ELEMENT_PADDING.X)
		+ (CORNER_PADDING.X * 2)

	local height = (props.Rows * ICON_SIZE.Y.Offset)
		+ ((props.Rows - 1) * ELEMENT_PADDING.Y)
		+ (CORNER_PADDING.Y * 2)

	local numMissions = #missionGroups
	local neededRows = math.ceil(numMissions / props.Columns)
	local canvasHeight = (neededRows * ICON_SIZE.Y.Offset)
		+ ((neededRows - 1) * ELEMENT_PADDING.Y)
		+ (CORNER_PADDING.Y * 2)
	local neededElements = math.max(props.Rows, neededRows) * props.Columns
	local numFillerElements = neededElements - numMissions

	local icons = {}
	local xPos = CORNER_PADDING.X
	local yPos = CORNER_PADDING.Y
	local xElements = 0
	for groupIndex, missionGroup in ipairs(missionGroups) do
		icons[missionGroup.MissionGroup] = Roact.createElement(MissionGroupIcon, {
			Position = UDim2.fromOffset(xPos, yPos),
			MissionInfos = missionInfos,
			MissionGroup = missionGroup,
			OnActivated = self.onSelected(groupIndex),
			Active = props.Active,
		})
		xPos = xPos + ICON_SIZE.X.Offset + ELEMENT_PADDING.X
		xElements = xElements + 1
		if xElements >= props.Columns then
			xElements = 0
			xPos = CORNER_PADDING.X
			yPos = yPos + ICON_SIZE.Y.Offset + ELEMENT_PADDING.Y
		end
	end

	for i = 1, numFillerElements do
		icons["Filler" .. i] = Roact.createElement("Frame", {
			Size = ICON_SIZE,
			Position = UDim2.fromOffset(xPos, yPos),
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.5,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0.25, 0),
			}),
		})
		xPos = xPos + ICON_SIZE.X.Offset + ELEMENT_PADDING.X
		xElements = xElements + 1
		if xElements >= props.Columns then
			xElements = 0
			xPos = CORNER_PADDING.X
			yPos = yPos + ICON_SIZE.Y.Offset + ELEMENT_PADDING.Y
		end
	end

	return Roact.createElement("Frame", {
		Size = UDim2.fromOffset(width, height),
		Position = position,
		AnchorPoint = props.AnchorPoint,
		BackgroundTransparency = 1,
	}, {
		Title = Roact.createElement("TextLabel", {
			Text = props.Title,
			Font = Enum.Font.GothamBold,
			TextSize = 48,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 0, -10),
			Size = UDim2.new(1, 0, 0, 60),
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.25,
			TextColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
		}),

		Background = Roact.createElement("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1),
			CanvasSize = UDim2.fromOffset(width, canvasHeight),
			ScrollBarThickness = 10,
			ScrollBarImageColor3 = Color3.new(1, 1, 1),
			ScrollingDirection = Enum.ScrollingDirection.Y,
			VerticalScrollBarInset = Enum.ScrollBarInset.Always,
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.25,
			BorderSizePixel = 0,
		}, icons),
	})
end

return MissionGroupList
