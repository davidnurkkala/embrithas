--[[
	Converts a mission's position from WorldSpace to 2D MapSpace.
]]

local WorldMap = workspace:WaitForChild("Dungeon"):WaitForChild("MapTable"):WaitForChild("Map")

local function toMapSpace(worldPos)
	local worldMapPos = Vector2.new(WorldMap.CFrame.Position.Z, WorldMap.CFrame.Position.X)
	local worldMapSize = Vector2.new(WorldMap.Size.Z, WorldMap.Size.Y)
	worldPos = Vector2.new(worldPos.Z, worldPos.X)
	local halfSize = worldMapSize * 0.5
	local mapSpaceX = (worldMapPos.X - worldPos.X) + halfSize.X
	local mapSpaceY = (worldPos.Y - worldMapPos.Y) + halfSize.Y
	local scaledX = mapSpaceX / worldMapSize.X
	local scaledY = mapSpaceY / worldMapSize.Y
	return UDim2.fromScale(scaledX, scaledY)
end

return toMapSpace
