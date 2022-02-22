--[[
	Renders a map screen.
	We want to render a large Offset-scaled image and use UIScale.
	Children can be rendered as icons. Use FromScale to position properly.
]]

local MAP_SIZE = Vector2.new(1920, 1080)
local FEATHER = 500

local Roact = require(game.ReplicatedStorage.Packages.Roact)
local GetBestScale = require(game.ReplicatedStorage.Packages.GetBestScale)

local main = game.ReplicatedStorage.RoactElements
local CloudEffect = require(main.Components.MissionSelect.CloudEffect)
local MapScreenIcons = require(main.Components.MissionSelect.MapScreenIcons)

local MapScreen = Roact.PureComponent:extend("MapScreen")
local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	ZIndex = t.optional(t.integer),
	Active = t.optional(t.boolean),
	AnimateOpening = t.optional(t.boolean),
	MissionInfos = t.optional(t.table),
	MissionList = t.optional(t.table),
	RecommendedMissions = t.optional(t.table),
	OnMissionSelected = t.optional(t.callback),
})

MapScreen.defaultProps = {
	ZIndex = 1,
	Active = true,
	AnimateOpening = false,
}

function MapScreen:init(props)
	assert(typecheck(props))

	local bestScale = GetBestScale()
	local feather = FEATHER * bestScale
	self.corner, self.updateCorner = Roact.createBinding(Vector2.new(feather, feather))
	self.scrollingFrame = Roact.createRef()

	self.mouseDown = false
	self.dragging = false
	self.baseScale = nil

	self.minScale = 1
	self.maxScale = 2
	self.defaultScale = 1

	self.state = {
		scale = self.defaultScale,
	}

	self.onMouseUpdate = function(delta)
		if not self.props.Active then return end
		local scale = self.state.scale
		local newCorner = self.corner:getValue() - Vector2.new(delta.X, delta.Y)
		local windowSize = self.scrollingFrame:getValue().AbsoluteWindowSize
		bestScale = GetBestScale()
		feather = FEATHER * bestScale
		local absoluteImageSize = (windowSize + Vector2.new(feather * 2, feather * 2)) * scale
		local furthestCorner = absoluteImageSize - windowSize
		local x = math.clamp(newCorner.X, 0, furthestCorner.X)
		local y = math.clamp(newCorner.Y, 0, furthestCorner.Y)
		self.updateCorner(Vector2.new(x, y))
	end

	self.setZoom = function(zoomAmount)
		if not self.props.Active then return end
		local newScale = self.state.scale + zoomAmount
		newScale = math.clamp(newScale, self.minScale, self.maxScale)
		if newScale ~= self.state.scale then
			self:setState({
				scale = newScale,
			})
		end
	end

	self.inputChanged = function(_, input)
		if not self.props.Active then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if self.mouseDown then
				self.onMouseUpdate(input.Position - self.mouseDown)
				self.mouseDown = input.Position
			end
		elseif input.UserInputType == Enum.UserInputType.MouseWheel then
			local scale = self.state.scale
			self.setZoom(input.Position.Z / (10 / scale))
		end
	end

	self.inputBegan = function(_, input)
		if not self.props.Active then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.MouseButton3 then
			self.mouseDown = input.Position
		end
	end

	self.inputEnded = function(_, input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.MouseButton3 then
			self.mouseDown = false
		end
	end

	self.onMissionSelected = function(missionId)
		if self.props.OnMissionSelected then
			self.props.OnMissionSelected(missionId)
		end
	end
end

function MapScreen:didMount()
	local frame = self.scrollingFrame:getValue()
	if frame then
		local corner = self.corner:getValue()
		frame.CanvasPosition = corner
	end
end

function MapScreen:didUpdate(_, previousState)
	local frame = self.scrollingFrame:getValue()
	if frame then
		local scale = self.state.scale
		if previousState.scale ~= scale then
			local windowSize = frame.AbsoluteSize
			local corner = self.corner:getValue()
			local center = corner + (windowSize * 0.5)
			local newCenter = center / previousState.scale * scale
			local newCorner = newCenter - (windowSize * 0.5)
			self.updateCorner(newCorner)
		end
	end
end

function MapScreen:render()
	local scale = self.state.scale
	local props = self.props
	local missionList = props.MissionList
	local missionInfos = props.MissionInfos
	local active = props.Active

	return Roact.createElement("Frame", {
		ZIndex = props.ZIndex,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		VignetteLabel = Roact.createElement("ImageLabel", {
			ZIndex = 2,
			BackgroundTransparency = 1,
			Image = "rbxassetid://228322184",
			Size = UDim2.new(1, 10, 1, 10),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
		}),

		VignetteLabel2 = Roact.createElement("ImageLabel", {
			ZIndex = 2,
			BackgroundTransparency = 1,
			Image = "rbxassetid://228322184",
			Size = UDim2.new(1, 10, 1, 10),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
		}),

		Main = Roact.createElement("Frame", {
			ZIndex = 1,
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.new(),
			BorderSizePixel = 0,
			[Roact.Event.InputBegan] = self.inputBegan,
			[Roact.Event.InputEnded] = self.inputEnded,
			[Roact.Event.InputChanged] = self.inputChanged,
		}, {
			AspectRatio = Roact.createElement("UIAspectRatioConstraint", {
				AspectRatio = 16 / 9,
				AspectType = Enum.AspectType.FitWithinMaxSize,
			}),

			Scroll = Roact.createElement("ScrollingFrame", {
				Size = UDim2.fromScale(1, 1),
				CanvasSize = UDim2.fromOffset((MAP_SIZE.X + FEATHER * 2) * scale,
					(MAP_SIZE.Y + FEATHER * 2) * scale),
				CanvasPosition = self.corner,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 0,
				HorizontalScrollBarInset = Enum.ScrollBarInset.None,
				VerticalScrollBarInset = Enum.ScrollBarInset.None,
				ScrollingEnabled = false,
				ClipsDescendants = false,
				[Roact.Ref] = self.scrollingFrame,
			}, {
				Padding = Roact.createElement("UIPadding", {
					PaddingTop = UDim.new(0, FEATHER),
					PaddingBottom = UDim.new(0, FEATHER),
					PaddingLeft = UDim.new(0, FEATHER),
					PaddingRight = UDim.new(0, FEATHER),
				}),

				Background = Roact.createElement("Frame", {
					ZIndex = 1,
					Size = UDim2.fromScale(2, 2),
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.new(),
				}),

				Map = Roact.createElement("ImageLabel", {
					ZIndex = 2,
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Image = "rbxassetid://5021439106",
				}),

				CloudShadow = Roact.createElement("Frame", {
					ZIndex = 3,
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(3, 3),
				}, {
					CloudEffect = Roact.createElement(CloudEffect, {
						Color = Color3.new(),
						Transparency = 0.25,
					}),
				}),

				Clouds = Roact.createElement("Frame", {
					ZIndex = 4,
					Position = self.corner:map(function(value)
						local offset = value * 0.5
						return UDim2.new(0.5, -20 - offset.X, 0.5, -20 - offset.Y)
					end),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(3, 3),
				}, {
					CloudEffect = Roact.createElement(CloudEffect, {
						Color = Color3.new(1, 1, 1),
						Transparency = 0.5,
					}),
				}),

				IconsContainer = missionList and Roact.createElement("Frame", {
					ZIndex = 5,
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
				}, {
					Icons = Roact.createElement(MapScreenIcons, {
						Active = active,
						AnimateOpening = props.AnimateOpening,
						MissionInfos = missionInfos,
						MissionList = missionList,
						RecommendedMissions = props.RecommendedMissions,
						Scale = scale,
						OnMissionSelected = self.onMissionSelected,
					}),
				}),
			})
		}),
	})
end

return MapScreen
