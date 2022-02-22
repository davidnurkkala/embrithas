local Super = require(script.Parent)
local ThemeMachine = Super:Extend()

function ThemeMachine:OnCreated()
	assert(self.Dungeon)
	assert(self.Random)
	
	local basePart = Instance.new("Part")
	basePart.TopSurface = Enum.SurfaceType.Smooth
	basePart.BottomSurface = Enum.SurfaceType.Smooth
	basePart.Anchored = true
	self.BasePart = basePart
end

function ThemeMachine:AddFeature(...)
	self.Dungeon:AddFeature(...)
end

function ThemeMachine:MakeVector2Odd(vector2, direction)
	direction = direction or -1
	
	local x = vector2.X
	if x % 2 == 0 then
		x = x + direction
	end
	
	local y = vector2.Y
	if y % 2 == 0 then
		y = y + direction
	end
	
	return Vector2.new(x, y)
end

function ThemeMachine:GenerateFeatures(cell)
	
end

function ThemeMachine:GetFloorPart()
	local floorPart = self.BasePart:Clone()
	floorPart.Material = Enum.Material.Cobblestone
	floorPart.Color = Color3.new(0.5, 0.5, 0.5)
	
	return floorPart
end
function ThemeMachine:CreateFloor(size, position)
	local part = self:GetFloorPart()
	part.Name = "_DungeonFloor"
	game:GetService("CollectionService"):RemoveTag(part, "MapIgnored")
	part.Size = size
	part.Position = position
	part.Parent = self.Dungeon.Model
end

function ThemeMachine:GetWallPart()
	local wallPart = self.BasePart:Clone()
	wallPart.Material = Enum.Material.Brick
	wallPart.Color = Color3.new(0.5, 0.5, 0.5)
	
	return wallPart
end
function ThemeMachine:CreateWall(size, position)
	local wall = self:GetWallPart()
	wall.Name = "_DungeonWall"
	game:GetService("CollectionService"):RemoveTag(wall, "MapIgnored")
	wall.Size = size
	wall.Position = position
	wall.Parent = self.Dungeon.Model
end
function ThemeMachine:CreateDoorjamb(size, position)
	local doorjamb
	if self.GetDoorjambPart then
		doorjamb = self:GetDoorjambPart()
	else
		doorjamb = self:GetWallPart()
	end
	doorjamb.Name = "_DungeonDoorjamb"
	doorjamb.Size = size
	doorjamb.Position = position
	doorjamb.Parent = self.Dungeon.Model
end

function ThemeMachine:GetDoorModel()
	return self.Storage.Models.Door:Clone()
end
function ThemeMachine:CreateDoor(cframe, rooms)
	self:CreateNew"Door"{
		Dungeon = self.Dungeon,
		CFrame = cframe,
		Rooms = rooms,
		Model = self:GetDoorModel(),
	}
end

function ThemeMachine:IsCellWall(cell)
	return self.Dungeon:IsCellWall(cell)
end

function ThemeMachine:SetUpLighting()
	local lighting = game:GetService("Lighting")
	lighting.Brightness = 0.1
	lighting.ClockTime = 0
	lighting.Ambient = Color3.new(0.2, 0.2, 0.2)
	
	lighting:ClearAllChildren()
	self.Storage.Models.BlackSky:Clone().Parent = lighting
end

function ThemeMachine:SetUpMusic()
	local playlist = require(self.Storage.Music.Playlists.GenericDungeon)
	self:GetService("MusicService"):PlayPlaylist(playlist)
end

function ThemeMachine:PostBuild(grid, min, max)

end

function ThemeMachine:TerrainFillTiles(option, grid, min, max, material, dy, leaveGaps)
	local dungeon = self.Dungeon
	
	if dy == nil then
		dy = 0
	end
	if leaveGaps == nil then
		leaveGaps = false
	end
	
	local border = 4
	for x = min.X - border, max.X + border do
		for y = min.Y - border, max.Y + border do
			if dungeon:GetCell(grid, Vector2.new(x, y)) == nil then
				local size = Vector3.new(1, 0, 1) * self.Dungeon.TileSize + Vector3.new(0, 16, 0)
				local position = Vector3.new(x * self.Dungeon.TileSize, 6 + dy, y * self.Dungeon.TileSize)

				workspace.Terrain:FillBlock(CFrame.new(position), size, material)
			end
		end
	end
end

function ThemeMachine:CreatePatterns(roomCount)
	
end

function ThemeMachine:CreatePatternSquareRing(size, width)
	local pattern = self:CreatePatternRectangle(size)
	
	for x = width + 1, size.X - width - 2 do
		for y = width + 1, size.Y - width - 2 do
			self.Dungeon:RemoveCell(pattern.Grid, Vector2.new(x, y))
		end
	end
	
	return pattern
end

function ThemeMachine:CreatePatternSquareRingWithInternalDoors(size, width)
	local pattern = self:CreatePatternSquareRing(size, width)
	local dungeon = self.Dungeon
	
	local n = dungeon:GetCell(pattern.Grid, Vector2.new(self.Random:NextInteger(width + 1, size.X - width - 2), size.Y - 1 - width))
	n.IsConnection = true
	n.Direction = Vector2.new(0, -1)
	
	local s = dungeon:GetCell(pattern.Grid, Vector2.new(self.Random:NextInteger(width + 1, size.X - width - 2), width))
	s.IsConnection = true
	s.Direction = Vector2.new(0, 1)
	
	local e = dungeon:GetCell(pattern.Grid, Vector2.new(width, self.Random:NextInteger(width + 1, size.Y - width - 2)))
	e.IsConnection = true
	e.Direction = Vector2.new(1, 0)
	
	local w = dungeon:GetCell(pattern.Grid, Vector2.new(size.X - 1 - width, self.Random:NextInteger(width + 1, size.Y - width - 2)))
	w.IsConnection = true
	w.Direction = Vector2.new(-1, 0)
	
	return pattern
end

function ThemeMachine:CreatePatternCorner(size, width)
	local sx, sy = size.X, size.Y
	local dungeon = self.Dungeon
	
	local pattern = {Position = Vector2.new(), Grid = {}}
	
	for x = 0, sx - 1 do
		for y = 0, sy - 1 do
			if (x <= width) or (y <= width) then
				local position = Vector2.new(x, y)
				dungeon:SetCell(pattern.Grid, position, {
					Position = position,
				})
			end
		end
	end
	
	local n = dungeon:GetCell(pattern.Grid, Vector2.new(self.Random:NextInteger(1, sx - 2), 0))
	n.IsConnection = true
	n.Direction = Vector2.new(0, -1)
	
	local e = dungeon:GetCell(pattern.Grid, Vector2.new(sx - 1, self.Random:NextInteger(1, width - 1)))
	e.IsConnection = true
	e.Direction = Vector2.new(1, 0)
	
	local w = dungeon:GetCell(pattern.Grid, Vector2.new(0, self.Random:NextInteger(1, sy - 2)))
	w.IsConnection = true
	w.Direction = Vector2.new(-1, 0)
	
	local s = dungeon:GetCell(pattern.Grid, Vector2.new(self.Random:NextInteger(1, width - 1), sy - 1))
	s.IsConnection = true
	s.Direction = Vector2.new(0, 1)
	
	return pattern
end

function ThemeMachine:CreatePatternRectangle(size)
	local sx, sy = size.X, size.Y
	local dungeon = self.Dungeon
	
	local pattern = {Position = Vector2.new(), Grid = {}}
	
	for x = 0, sx - 1 do
		for y = 0, sy - 1 do
			local position = Vector2.new(x, y)
			dungeon:SetCell(pattern.Grid, position, {
				Position = position,
			})
		end
	end

	local n = dungeon:GetCell(pattern.Grid, Vector2.new(self.Random:NextInteger(1, sx - 2), 0))
	n.IsConnection = true
	n.Direction = Vector2.new(0, -1)
	local e = dungeon:GetCell(pattern.Grid, Vector2.new(sx - 1, self.Random:NextInteger(1, sy - 2)))
	e.IsConnection = true
	e.Direction = Vector2.new(1, 0)
	local w = dungeon:GetCell(pattern.Grid, Vector2.new(0, self.Random:NextInteger(1, sy - 2)))
	w.IsConnection = true
	w.Direction = Vector2.new(-1, 0)
	local s = dungeon:GetCell(pattern.Grid, Vector2.new(self.Random:NextInteger(1, sx - 2), sy - 1))
	s.IsConnection = true
	s.Direction = Vector2.new(0, 1)
	
	return pattern
end

function ThemeMachine:CreatePatternOrganic(size, scale)
	local originalSize = size
	local smallSize = Vector2.new(math.ceil(size.X / scale), math.ceil(size.Y / scale))

	local initialChance = 0.45
	local birthLimit = 4
	local deathLimit = 2
	local steps = 1

	size = smallSize

	local pattern = {}
	for x = 0, size.X - 1 do
		pattern[x] = {}
		for y = 0, size.Y - 1 do
			pattern[x][y] = {Filled = self.Random:NextNumber() < initialChance} 
		end
	end

	local function countNeighbors(sx, sy)
		local wallCount = 0
		for dx = -1, 1 do
			for dy = -1, 1 do
				local x = sx + dx
				local y = sy + dy

				if (x < 0) or (x > size.X - 1) or (y < 0) or (y > size.Y - 1) then
					-- do nothing
				else
					local atCenter = (dx == 0) and (dy == 0)
					if (not atCenter) and pattern[x][y].Filled then
						wallCount = wallCount + 1
					end
				end
			end
		end
		return wallCount
	end

	local function simulationStep()
		local nextPattern = {}
		for x = 0, size.X - 1 do
			nextPattern[x] = {}
			for y = 0, size.Y - 1 do
				local neighborCount = countNeighbors(x, y)

				if pattern[x][y].Filled then
					if neighborCount < deathLimit then
						nextPattern[x][y] = {Filled = false}
					else
						nextPattern[x][y] = {Filled = true}
					end
				else
					if neighborCount > birthLimit then
						nextPattern[x][y] = {Filled = true}
					else
						nextPattern[x][y] = {Filled = false}
					end
				end
			end
		end
		pattern = nextPattern
	end

	for _ = 1, steps do
		simulationStep()
	end

	local scaledPattern = {}
	size = originalSize

	for x = 0, size.X - 1 do
		scaledPattern[x] = {}
		for y = 0, size.Y - 1 do
			local sx = math.floor(x / scale)
			local sy = math.floor(y / scale)
			local source = pattern[sx][sy]
			local tile = {}
			for key, val in pairs(source) do
				tile[key] = val
			end
			scaledPattern[x][y] = tile
		end
	end

	pattern = scaledPattern
	deathLimit = 3
	birthLimit = 3
	steps = 2

	for _ = 1, steps do
		simulationStep()
	end

	deathLimit = 4

	for _ = 1, steps do
		simulationStep()
	end

	local fx, fy
	repeat
		fx = self.Random:NextInteger(0, size.X - 1)
		fy = self.Random:NextInteger(0, size.Y - 1)
		local tile = pattern[fx][fy]
	until tile.Filled

	local filledCells = 0

	local function floodFill(x, y)
		if x < 0 then return end
		if x > size.X - 1 then return end
		if y < 0 then return end
		if y > size.Y - 1 then return end

		local tile = pattern[x][y]
		if not tile.Filled then return end
		if tile.FloodFilled then return end

		tile.FloodFilled = true

		filledCells = filledCells + 1

		floodFill(x - 1, y)
		floodFill(x + 1, y)
		floodFill(x, y - 1)
		floodFill(x, y + 1)
	end

	floodFill(fx, fy)

	local coverage = filledCells / (size.X * size.Y)
	if coverage < 0.4 then
		return self:CreatePatternOrganic(size, scale)
	end

	local function commitFloodFill()
		for x = 0, size.X - 1 do
			for y = 0, size.Y - 1 do
				local tile = pattern[x][y]
				if tile.Filled and (not tile.FloodFilled) then
					tile.Filled = false
				elseif tile.FloodFilled then
					tile.FloodFilled = nil
				end
			end
		end
	end

	commitFloodFill()

	local function placeDoorNear(position, direction)
		local bestDistanceSq = math.huge
		local bestPosition

		for x = 0, size.X - 1 do
			for y = 0, size.Y - 1 do
				if pattern[x][y].Filled then
					local distanceSq = (position.X - x) ^ 2 + (position.Y - y) ^ 2
					if distanceSq < bestDistanceSq then
						bestDistanceSq = distanceSq
						bestPosition = Vector2.new(x, y)
					end
				end
			end
		end

		-- clear out space around the chosen door so that we don't get awkward cutouts
		local function clear(x, y)
			if (x >= 0) and (x <= size.X - 1) and (y >= 0) and (y <= size.Y - 1) then
				pattern[x][y].Filled = false
				pattern[x][y].DoorTile = false
			end
		end
		local function fill(a, b)
			local sx = math.min(a.X, b.X)
			local fx = math.max(a.X, b.X)
			local sy = math.min(a.Y, b.Y)
			local fy = math.max(a.Y, b.Y)
			for x = sx, fx do
				for y = sy, fy do
					if (x >= 0) and (x <= size.X - 1) and (y >= 0) and (y <= size.Y - 1) then
						pattern[x][y].Filled = true
						pattern[x][y].DoorTile = true
					end
				end
			end
		end
		local x, y = bestPosition.X, bestPosition.Y
		local s = 3
		fill(Vector2.new(x - s, y - s), Vector2.new(x + s, y + s))

		local cell = pattern[bestPosition.X][bestPosition.Y]
		cell.Walls = {[direction] = "Door"}
		cell.DoorTile = true

		return bestPosition
	end

	placeDoorNear(Vector2.new(0, size.Y / 2), "NegX")
	placeDoorNear(Vector2.new(size.X - 1, size.Y / 2), "PosX")
	placeDoorNear(Vector2.new(size.X / 2, 0), "NegY")
	local doorPosition = placeDoorNear(Vector2.new(size.X / 2, size.Y - 1), "PosY")

	floodFill(doorPosition.X, doorPosition.Y)
	commitFloodFill()

	local function eliminateSmallGaps()
		local modified = false

		-- copy the previous pattern so we're not overriding anything accidentally
		local nextPattern = {}
		for x = 0, size.X - 1 do
			nextPattern[x] = {}
			for y = 0, size.Y - 1 do
				local cell = {}
				for key, val in pairs(pattern[x][y]) do
					cell[key] = val
				end

				nextPattern[x][y] = cell
			end
		end

		local function isInBounds(p)
			return (p.X >= 0) and (p.X <= size.X - 1) and (p.Y >= 0) and (p.Y <= size.Y - 1)
		end

		local function get(p)
			if not isInBounds(p) then
				return nil
			else
				return pattern[p.X][p.Y]
			end
		end

		local function set(p, v)
			if not isInBounds(p) then
				return
			end
			nextPattern[p.X][p.Y] = v
		end

		local function isWall(p)
			local cell = get(p)
			if not cell then
				return true
			else
				return (not cell.Filled)
			end
		end

		local function isFloor(p)
			return not isWall(p)
		end

		local function empty(p)
			local cell = get(p)
			if not cell then return end
			if cell.DoorTile then return end
			set(p, {Filled = true})
		end

		local function compareDelta(p, delta)
			local a = p + delta
			local b = p - delta
			if isWall(a) and isWall(b) then
				empty(a)
				empty(b)
			end
		end

		local function clear(p, r)
			modified = true

			for dx = -r, r do
				for dy = -r, r do
					empty(p + Vector2.new(dx, dy))
				end
			end
		end

		local function checkHorizontalPassage(p)
			local left = p + Vector2.new(-1, 0)
			local right = p + Vector2.new(1, 0)

			if isWall(left) or isWall(right) then return end

			local top, bot = false, false
			for dx = -1, 1 do
				if isWall(p + Vector2.new(dx, 1)) then
					top = true
				end
				if isWall(p + Vector2.new(dx, -1)) then
					bot = true
				end
			end

			if top and bot then
				clear(p, 1)
			end
		end

		local function checkVerticalPassage(p)
			local top = p + Vector2.new(0, 1)
			local bot = p + Vector2.new(0, -1)

			if isWall(top) or isWall(bot) then return end

			local left, right = false, false
			for dy = -1, 1 do
				if isWall(p + Vector2.new(-1, dy)) then
					left = true
				end
				if isWall(p + Vector2.new(1, dy)) then
					right = true
				end
			end

			if left and right then
				clear(p, 1)
			end
		end

		for x = 0, size.X - 1 do
			for y = 0, size.Y - 1 do
				local p = Vector2.new(x, y)
				local cell = get(p)
				if cell.Filled then
					checkHorizontalPassage(p)
					checkVerticalPassage(p)
				end
			end
		end

		pattern = nextPattern
		return modified
	end

	local passes = 0
	repeat
		passes = passes + 1
	until (not eliminateSmallGaps()) or (passes > 16)
	
	-- convert this to the modern format
	local dungeon = self.Dungeon
	local convertedPattern = {Position = Vector2.new(), Grid = {}}
	
	for x = 0, size.X - 1 do
		for y = 0, size.Y - 1 do
			local tile = pattern[x][y]
			if tile.Filled then
				local cell = {Position = Vector2.new(x, y)}
				
				-- is this a door?
				if tile.DoorTile and tile.Walls then
					cell.IsConnection = true
					
					if tile.Walls.PosX == "Door" then
						cell.Direction = Vector2.new(1, 0)
					elseif tile.Walls.NegX == "Door" then
						cell.Direction = Vector2.new(-1, 0)
					elseif tile.Walls.PosY == "Door" then
						cell.Direction = Vector2.new(0, 1)
					elseif tile.Walls.NegY == "Door" then
						cell.Direction = Vector2.new(0, -1)
					end
				end
				
				dungeon:SetCell(convertedPattern.Grid, cell.Position, cell)
			end
		end
	end
	
	return convertedPattern
end


-- Abraxxian was here 2/22/2021
function ThemeMachine:DebugPart(cframe, size, color)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Color = color
	part.CFrame = cframe
	part.Size = size
	part.TopSurface = "Smooth"
	part.BottomSurface = "Smooth"
	part.Parent = workspace
	return part
end

function ThemeMachine:DebugFootprint(feature, message)
	local retVal
	local size, position = feature:GetFootprint()
	for dx = 0, size.X - 1 do
		for dy = 0, size.Y - 1 do
			local a = position + Vector2.new(dx, dy)
			local p = Vector3.new(a.X * self.Dungeon.TileSize, 0, a.Y * self.Dungeon.TileSize)
			local part = self:DebugPart(CFrame.new(p), Vector3.new(4, 1, 4), (a == feature.Position) and Color3.new(1, 0, 0) or Color3.new(1, 1, 1))
			part.Name = message or ""
			part.Parent = self.Dungeon.Model
			retVal = part
		end
	end
	return retVal
end

return ThemeMachine

--[[
	for pass = 1, 16 do
		local sx = self.Random:NextInteger(12, 32)
		local sy = self.Random:NextInteger(12, 32)
		local px = self.Random:NextInteger(-64, 64)
		local py = self.Random:NextInteger(-64, 64)
		
		local choice = self.Random:NextInteger(1, 4)
		
		local pattern = {Position = Vector2.new(px, py), Grid = {}}
		if choice == 1 then
			for x = 0, sx - 1 do
				for y = 0, sy - 1 do
					local position = Vector2.new(x, y)
					self:SetCell(pattern.Grid, position, {
						Position = position,
					})
				end
			end
			
			local n = self:GetCell(pattern.Grid, Vector2.new(self.Random:NextInteger(1, sx - 2), 0))
			n.IsConnection = true
			n.Direction = Vector2.new(0, -1)
			local e = self:GetCell(pattern.Grid, Vector2.new(sx - 1, self.Random:NextInteger(1, sy - 2)))
			e.IsConnection = true
			e.Direction = Vector2.new(1, 0)
			local w = self:GetCell(pattern.Grid, Vector2.new(0, self.Random:NextInteger(1, sy - 2)))
			w.IsConnection = true
			w.Direction = Vector2.new(-1, 0)
			local s = self:GetCell(pattern.Grid, Vector2.new(self.Random:NextInteger(1, sx - 2), sy - 1))
			s.IsConnection = true
			s.Direction = Vector2.new(0, 1)
		elseif choice == 2 then
			local radius = sx / 2
			local center = Vector2.new(sx / 2, sx / 2) - Vector2.new(0.5, 0.5)
			for x = 0, sx - 1 do
				for y = 0, sx - 1 do
					local position = Vector2.new(x, y)
					local delta = center - position
					if delta.Magnitude < radius then
						local cell = {
							Position = position,
						}
						
						if x == 0 and y == math.floor(center.Y) then
							cell.IsConnection = true
							cell.Direction = Vector2.new(-1, 0)
						elseif x == sx - 1 and y == math.floor(center.Y) then
							cell.IsConnection = true
							cell.Direction = Vector2.new(1, 0)
						elseif x == math.floor(center.X) and y == 0 then
							cell.IsConnection = true
							cell.Direction = Vector2.new(0, -1)
						elseif x == math.floor(center.X) and y == sx - 1 then
							cell.IsConnection = true
							cell.Direction = Vector2.new(0, 1)
						end
						
						self:SetCell(pattern.Grid, position, cell)
					end
				end
			end
		elseif choice == 3 then
			local big = math.max(sx, sy)
			local small = math.min(sx, sy)
			
			for x = 0, big - 1 do
				for y = 0, big - 1 do
					if x < small or y < small then
						local position = Vector2.new(x, y)
						self:SetCell(pattern.Grid, position, {Position = position})
					end
				end
			end
			
			local n = self:GetCell(pattern.Grid, Vector2.new(self.Random:NextInteger(1, big - 2), 0))
			n.IsConnection = true
			n.Direction = Vector2.new(0, -1)
			local e = self:GetCell(pattern.Grid, Vector2.new(big - 1, self.Random:NextInteger(1, small - 2)))
			e.IsConnection = true
			e.Direction = Vector2.new(1, 0)
			local w = self:GetCell(pattern.Grid, Vector2.new(0, self.Random:NextInteger(1, big - 2)))
			w.IsConnection = true
			w.Direction = Vector2.new(-1, 0)
			local s = self:GetCell(pattern.Grid, Vector2.new(self.Random:NextInteger(1, small - 2), big - 1))
			s.IsConnection = true
			s.Direction = Vector2.new(0, 1)
		elseif choice == 4 then
			for x = 0, 32 do
				for y = 0, 8 do
					local position = Vector2.new(x, y)
					local cell = {Position = position}
					
					if (x + 6) % 12 == 0 then
						if y == 0 then
							cell.IsConnection = true
							cell.Direction = Vector2.new(0, -1)
						elseif y == 8 then
							cell.IsConnection = true
							cell.Direction = Vector2.new(0, 1)
						end
					end
					
					self:SetCell(pattern.Grid, position, cell)
				end
			end
		elseif choice == 5 then
			local r = 4
			local s = 48
			for x = 0, s - 1 do
				for y = 0, s - 1 do
					if
						(x <= r) or
						(x >= s - 1 - r) or
						(y <= r) or
						(y >= s - 1 - r)
					then
						local position = Vector2.new(x, y)
						self:SetCell(pattern.Grid, position, {Position = position})
					end
				end
			end
			
			self:UpdateCell(pattern.Grid, Vector2.new(0, s / 2), {IsConnection = true, Direction = Vector2.new(-1, 0)})
			self:UpdateCell(pattern.Grid, Vector2.new(s - 1, s / 2), {IsConnection = true, Direction = Vector2.new(1, 0)})
			self:UpdateCell(pattern.Grid, Vector2.new(s / 2, 0), {IsConnection = true, Direction = Vector2.new(0, -1)})
			self:UpdateCell(pattern.Grid, Vector2.new(s / 2, s - 1), {IsConnection = true, Direction = Vector2.new(0, 1)})
			
			self:UpdateCell(pattern.Grid, Vector2.new(s - 1 - r, s / 2), {IsConnection = true, Direction = Vector2.new(-1, 0)})
			self:UpdateCell(pattern.Grid, Vector2.new(r, s / 2), {IsConnection = true, Direction = Vector2.new(1, 0)})
			self:UpdateCell(pattern.Grid, Vector2.new(s / 2, s - 1 - r), {IsConnection = true, Direction = Vector2.new(0, -1)})
			self:UpdateCell(pattern.Grid, Vector2.new(s / 2, r), {IsConnection = true, Direction = Vector2.new(0, 1)})
		end]]