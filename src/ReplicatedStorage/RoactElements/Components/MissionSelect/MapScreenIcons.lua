--[[
	Renders a set of icons on a map screen.
	Respects the order of inputs.
	Checks for icon collision and moves icons over if they are too close.

	This component is only used by MapScreen.
]]

local COLLISION_RADIUS = 70
local WAIT_TIME = 0.2

local Roact = require(game.ReplicatedStorage.Packages.Roact)

local main = game.ReplicatedStorage.RoactElements
local MissionIcon = require(main.Components.MissionSelect.MissionIcon)
local ToMapSpace = require(main.Components.MissionSelect.ToMapSpace)
local HeartbeatConnection = require(main.Components.Signal.HeartbeatConnection)

local MapScreenIcons = Roact.PureComponent:extend("MapScreenIcons")
local t = require(game.ReplicatedStorage.Packages.t)
local typecheck = t.interface({
	Active = t.optional(t.boolean),
	AnimateOpening = t.optional(t.boolean),
	MissionInfos = t.table,
	MissionList = t.table,
	RecommendedMissions = t.optional(t.table),
	Scale = t.number,
	OnMissionSelected = t.optional(t.callback),
})

MapScreenIcons.defaultProps = {
	Active = true,
	AnimateOpening = false,
}

function MapScreenIcons:init(props)
	assert(typecheck(props))

	if props.AnimateOpening then
		self.nextOpen = tick() + WAIT_TIME
		self.state = {
			lastMission = 0,
			completed = false,
		}
	end

	self.missionInfoById = {}
	for _, missionInfo in pairs(props.MissionInfos) do
		self.missionInfoById[missionInfo.Module.Name] = missionInfo
	end

	self.update = function()
		local now = tick()
		if now > self.nextOpen then
			self.nextOpen = self.nextOpen + WAIT_TIME
			local lastMission = self.state.lastMission + 1
			self:setState({
				lastMission = lastMission,
				completed = lastMission > #self.props.MissionList,
			})
		end
	end

	self.onMissionSelected = function(missionId)
		return function()
			if self.props.OnMissionSelected then
				self.props.OnMissionSelected(missionId)
			end
		end
	end
end

function MapScreenIcons:circleCollision(uPos1, uPos2)
	local screenSize = Vector2.new(1920, 1080) * self.props.Scale
	local c1 = Vector2.new(uPos1.X.Scale * screenSize.X + uPos1.X.Offset,
		uPos1.Y.Scale * screenSize.Y + uPos1.Y.Offset)
	local c2 = Vector2.new(uPos2.X.Scale * screenSize.X + uPos2.X.Offset,
		uPos2.Y.Scale * screenSize.Y + uPos2.Y.Offset)
	local dist = (c2 - c1).Magnitude
	local totalRadius = COLLISION_RADIUS * 2
	if dist < totalRadius then
		local normal
		if dist < 0.01 then
			normal = Vector2.new(1, 1).Unit
		else
			normal = (c1 - c2).Unit
		end
		local depth = totalRadius - dist
		return {
			Depth = depth,
			Normal = normal,
		}
	else
		-- No collision
		return nil
	end
end

function MapScreenIcons:checkPosition(mapPosition)
	local testPos = mapPosition
	local collided = false
	for _ = 1, 5 do
		local foundCollision = false
		for _, oldPos in ipairs(self.positions) do
			local collision = self:circleCollision(oldPos, testPos)
			if collision then
				collided = true
				foundCollision = true
				local screenSize = Vector2.new(1920, 1080) * self.props.Scale
				local collisionVector = (-collision.Normal * collision.Depth)
				testPos = UDim2.fromScale(
					testPos.X.Scale + collisionVector.X / screenSize.X,
					testPos.Y.Scale + collisionVector.Y / screenSize.Y
				)
			end
		end
		if not foundCollision then
			break
		end
	end
	if collided then
		table.insert(self.positions, testPos)
		return testPos
	end
	table.insert(self.positions, mapPosition)
	return nil
end

function MapScreenIcons:render()
	local props = self.props
	local missionList = props.MissionList
	local missionInfoById = self.missionInfoById
	local active = props.Active
	local animate = props.AnimateOpening

	local state = self.state
	local lastMission = state.lastMission
	local completed = state.completed

	local missions = {}
	local positionsById = {}
	self.positions = {}

	for num, missionId in ipairs(missionList) do
		if animate and lastMission and num >= lastMission then
			break
		end

		local missionInfo = missionInfoById[missionId]
		local mission = require(missionInfo.Module)

		local worldPos = mission.MapPosition
		local mapPosition = ToMapSpace(worldPos)
		local newPos = self:checkPosition(mapPosition)
		positionsById[missionId] = newPos or mapPosition

		local isRecommended = props.RecommendedMissions and props.RecommendedMissions[missionId] or false

		missions[missionId] = Roact.createElement(MissionIcon, {
			Active = active,
			AnimateOpening = animate,
			Mission = mission,
			MissionInfo = missionInfo,
			IsRecommended = isRecommended,
			Position = newPos,
			PositionsById = positionsById,
			OnActivated = self.onMissionSelected(missionId),
		})
	end

	return Roact.createFragment({
		Update = animate and not completed and Roact.createElement(HeartbeatConnection, {
			Update = self.update,
		}) or nil,

		Missions = Roact.createFragment(missions)
	})
end

return MapScreenIcons
