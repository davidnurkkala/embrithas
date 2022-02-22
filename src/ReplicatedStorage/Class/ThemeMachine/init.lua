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

function ThemeMachine:CreateLargeCaveRoom(size, position, scale)
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
		return self:CreateLargeCaveRoom(size, position, scale)
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
				pattern[x][y].DoorTile = true
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
		local d = 5
		local width = 3
		local depth = 5
		if direction == "PosX" then
			for dx = 0, d do
				clear(x + dx, y + 2)
				clear(x + dx, y - 2)
			end
			fill(Vector2.new(x - 1, y + width), Vector2.new(x - 1 - depth, y - width))
		elseif direction == "NegX" then
			for dx = -d, 0 do
				clear(x + dx, y + 2)
				clear(x + dx, y - 2)
			end
			fill(Vector2.new(x + 1, y + width), Vector2.new(x + 1 + depth, y - width))
		elseif direction == "PosY" then
			for dy = 0, d do
				clear(x + 2, y + dy)
				clear(x - 2, y + dy)
			end
			fill(Vector2.new(x + width, y - 1), Vector2.new(x - width, y - 1 - depth))
		elseif direction == "NegY" then
			for dy = -d, 0 do
				clear(x + 2, y + dy)
				clear(x - 2, y + dy)
			end
			fill(Vector2.new(x + width, y + 1), Vector2.new(x - width, y + 1 + depth))
		end
		
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
	
	return pattern, size, position
end

function ThemeMachine:CreateCaveRoom(size, position)
	local initialChance = 0.45
	local birthLimit = 4
	local deathLimit = 3
	local steps = 6
	
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
		return self:CreateCaveRoom(size, position)
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
				pattern[x][y].DoorTile = true
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
		local d = 5
		local width = 3
		local depth = 5
		if direction == "PosX" then
			for dx = 0, d do
				clear(x + dx, y + 2)
				clear(x + dx, y - 2)
			end
			fill(Vector2.new(x - 1, y + width), Vector2.new(x - 1 - depth, y - width))
		elseif direction == "NegX" then
			for dx = -d, 0 do
				clear(x + dx, y + 2)
				clear(x + dx, y - 2)
			end
			fill(Vector2.new(x + 1, y + width), Vector2.new(x + 1 + depth, y - width))
		elseif direction == "PosY" then
			for dy = 0, d do
				clear(x + 2, y + dy)
				clear(x - 2, y + dy)
			end
			fill(Vector2.new(x + width, y - 1), Vector2.new(x - width, y - 1 - depth))
		elseif direction == "NegY" then
			for dy = -d, 0 do
				clear(x + 2, y + dy)
				clear(x - 2, y + dy)
			end
			fill(Vector2.new(x + width, y + 1), Vector2.new(x - width, y + 1 + depth))
		end
		
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
	
	return pattern, size, position
end

function ThemeMachine:CreateOpenCaveRoom(size, position)
	local pattern, size, position = self:CreateCaveRoom(size, position)
	
	local function floodFill(x, y)
		if x < 0 then return end
		if x > size.X - 1 then return end
		if y < 0 then return end
		if y > size.Y - 1 then return end
		
		local tile = pattern[x][y]
		if tile.Filled then return end
		if tile.FloodFilled then return end
		
		tile.FloodFilled = true
		
		floodFill(x - 1, y)
		floodFill(x + 1, y)
		floodFill(x, y - 1)
		floodFill(x, y + 1)
	end
	
	for x = 0, size.X - 1 do
		floodFill(x, 0)
		floodFill(x, size.Y - 1)
	end
	for y = 0, size.Y - 1 do
		floodFill(0, y)
		floodFill(size.X - 1, y)
	end
	
	for x = 0, size.X - 1 do
		for y = 0, size.Y - 1 do
			local tile = pattern[x][y]
			if tile.FloodFilled then
				tile.FloodFilled = nil
			else
				if not tile.Filled then
					tile.Filled = true
				end
			end
		end
	end
	
	return pattern, size, position
end

function ThemeMachine:CreateSquareRoom(size, position)
	local border = 4
	local posXDoorY = self.Random:NextInteger(border, size.Y - 1 - border)
	local negXDoorY = self.Random:NextInteger(border, size.Y - 1 - border)
	local posYDoorX = self.Random:NextInteger(border, size.X - 1 - border)
	local negYDoorX = self.Random:NextInteger(border, size.X - 1 - border)
	
	local pattern = {}
	for row = 0, size.X - 1 do
		pattern[row] = {}
		for col = 0, size.Y - 1 do
			local tile = {Filled = true}
			
			if row == 0 and col == negXDoorY then
				tile.Walls = {NegX = "Door"}
			elseif row == size.X - 1 and col == posXDoorY then
				tile.Walls = {PosX = "Door"}
			elseif col == 0 and row == negYDoorX then
				tile.Walls = {NegY = "Door"}
			elseif col == size.Y - 1 and row == posYDoorX then
				tile.Walls = {PosY = "Door"}
			end
			
			if row == 0 then
				if col == 0 then
					--self:AddFeature(tile, "Light")
				elseif col == size.Y - 1 then
					--self:AddFeature(tile, "Light")
				end
			elseif row == size.X - 1 then
				if col == 0 then
					--self:AddFeature(tile, "Light")
				elseif col == size.Y - 1 then
					--self:AddFeature(tile, "Light")
				end
			end
			
			pattern[row][col] = tile
		end
	end
	
	return pattern, size, position
end

function ThemeMachine:CreateCircularRoom(diameter, position)
	if diameter % 2 == 0 then
		diameter = diameter - 1
	end
	
	local size = Vector2.new(diameter, diameter)
	
	local radius = diameter / 2
	local radiusSq = radius ^ 2
	
	local center = (size - Vector2.new(1, 1)) / 2
	
	local pattern = {}
	for row = 0, size.X - 1 do
		pattern[row] = {}
		for col = 0, size.Y - 1 do
			local delta = center - Vector2.new(row, col)
			local distanceSq = delta.X ^ 2 + delta.Y ^ 2
			
			pattern[row][col] = {Filled = distanceSq <= radiusSq}
			
			if delta == Vector2.new(0, 0) then
				--self:AddFeature(pattern[row][col], "Light")
			end
			
			if (row == 0) or (row == size.X - 1) then
				local delta = math.floor(math.abs(col - center.Y))
				if delta == 0 then
					pattern[row][col].Walls = {[row == 0 and "NegX" or "PosX"] = "Door"}
				end
			
			elseif (col == 0) or (col == size.Y - 1) then
				local delta = math.floor(math.abs(row - center.X))
				if delta == 0 then
					pattern[row][col].Walls = {[col == 0 and "NegY" or "PosY"] = "Door"}
				end
			end
		end
	end
	
	return pattern, size, position
end

function ThemeMachine:CreateRingRoom(outerDiameter, innerDiameter, position)
	if outerDiameter % 2 == 0 then
		outerDiameter = outerDiameter - 1
	end
	
	if innerDiameter % 2 == 0 then
		innerDiameter = innerDiameter - 1
	end
	
	local size = Vector2.new(outerDiameter, outerDiameter)
	
	local outerRadius = outerDiameter / 2
	local outerRadiusSq = outerRadius ^ 2
	
	local innerRadius = innerDiameter / 2
	local innerRadiusSq = innerRadius ^ 2
	
	local center = (size - Vector2.new(1, 1)) / 2
	
	local pattern = {}
	for row = 0, size.X - 1 do
		pattern[row] = {}
		for col = 0, size.Y - 1 do
			local delta = center - Vector2.new(row, col)
			local distanceSq = delta.X ^ 2 + delta.Y ^ 2
			
			pattern[row][col] = {Filled = (distanceSq <= outerRadiusSq) and (distanceSq >= innerRadiusSq)}
			
			if delta == Vector2.new(0, 0) then
				--self:AddFeature(pattern[row][col], "Light")
			end
			
			if (row == 0) or (row == size.X - 1) then
				local delta = math.floor(math.abs(col - center.Y))
				if delta == 0 then
					pattern[row][col].Walls = {[row == 0 and "NegX" or "PosX"] = "Door"}
				end
			
			elseif (col == 0) or (col == size.Y - 1) then
				local delta = math.floor(math.abs(row - center.X))
				if delta == 0 then
					pattern[row][col].Walls = {[col == 0 and "NegY" or "PosY"] = "Door"}
				end
			end
		end
	end
	
	return pattern, size, position
end

function ThemeMachine:CreateSquareRoomWithLargePillar(size, position)
	size = self:MakeVector2Odd(size, -1)
	local pattern, size, position = self:CreateSquareRoom(size, position)
	
	local maxThickness = math.floor(math.min(size.X, size.Y) / 2)
	local minThickness = 4
	local thickness = self.Random:NextInteger(minThickness, maxThickness)
	
	for x = 0, size.X - 1 do
		for y = 0, size.Y - 1 do
			local d = math.min(x, size.X - 1 - x, y, size.Y - 1 - y)
			if d > thickness then
				pattern[x][y] = {Filled = false}
			end
		end
	end
	
	return pattern, size, position
end

function ThemeMachine:CreateStarRoom(size, position, shape)
	local pattern = {}
	for x = 0, size.X - 1 do
		pattern[x] = {}
		for y = 0, size.Y - 1 do
			pattern[x][y] = {Filled = false}
		end
	end
	
	local function square(rx0, ry0, rx1, ry1)
		local sx = size.X - 1
		local sy = size.Y - 1
		
		local x0 = math.floor(sx * rx0)
		local y0 = math.floor(sy * ry0)
		local x1 = math.ceil(sx * rx1)
		local y1 = math.ceil(sy * ry1)
		
		for x = x0, x1 do
			for y = y0, y1 do
				pattern[x][y] = {Filled = true}
			end
		end
	end
	
	local border = 2
	local function door(facing, position, scanDirection)
		local tiles = {}
		
		local function done()
			if scanDirection.X == 0 then
				return position.Y >= size.Y - border
			else
				return position.X >= size.X - border
			end
		end
		
		while not done() do
			local tile = pattern[position.X][position.Y]
			if tile.Filled then
				table.insert(tiles, tile)
			end
			position += scanDirection
		end
		local tile = tiles[self.Random:NextInteger(1, #tiles)]
		tile.Walls = {[facing] = "Door"}
	end
	
	if shape == "Corners" then
		square(0, 0, 1/3, 1/3)
		square(2/3, 2/3, 1, 1)
		square(1/4, 1/4, 3/4, 3/4)
		square(0, 2/3, 1/3, 1)
		square(2/3, 0, 1, 1/3)
		
	elseif shape == "Plus" then
		square(1/3, 0, 2/3, 1/3)
		square(1/3, 1/3, 2/3, 2/3)
		square(0, 1/3, 1/3, 2/3)
		square(2/3, 1/3, 1, 2/3)
		square(1/3, 2/3, 2/3, 1)
		
	elseif shape == "HVertical" then
		square(0, 0, 1/3, 1)
		square(1/3, 1/3, 2/3, 2/3)
		square(2/3, 0, 1, 1)
		
	elseif shape == "HHorizontal" then
		square(0, 0, 1, 1/3)
		square(1/3, 1/3, 2/3, 2/3)
		square(0, 2/3, 1, 1)
		
	elseif shape == "SVertical" then
		square(0, 0, 1, 1/5)
		square(0, 2/5, 1, 3/5)
		square(0, 4/5, 1, 1)
		
		local mutation = self.Random:NextInteger(1, 2)
		if mutation == 1 then
			square(0, 1/5, 1/5, 2/5)
			square(4/5, 3/5, 1, 4/5)
		else
			square(4/5, 1/5, 1, 2/5)
			square(0, 3/5, 1/5, 4/5)
		end
		
	elseif shape == "SHorizontal" then
		square(0, 0, 1/5, 1)
		square(2/5, 0, 3/5, 1)
		square(4/5, 0, 1, 1)
		
		local mutation = self.Random:NextInteger(1, 2)
		if mutation == 1 then
			square(1/5, 0, 2/5, 1/5)
			square(3/5, 4/5, 4/5, 1)
		else
			square(1/5, 4/5, 2/5, 1)
			square(3/5, 0, 4/5, 1/5)
		end
	end
	
	door("NegX", Vector2.new(0, border), Vector2.new(0, 1))
	door("PosX", Vector2.new(size.X - 1, border), Vector2.new(0, 1))
	door("NegY", Vector2.new(border, 0), Vector2.new(1, 0))
	door("PosY", Vector2.new(border, size.Y - 1), Vector2.new(1, 0))
	
	return pattern, size, position
end

function ThemeMachine:CreateSquareRoomWithPillars(size, position)
	-- this room works best when given an odd numbered size
	size = self:MakeVector2Odd(size, -1)
	
	-- generate blank square room
	local pattern, size, position = self:CreateSquareRoom(size, position)
	
	-- filler it with pillars
	local radius = self.Random:NextInteger(0, 2)
	
	local function pillar(row, col)
		for dr = -radius, radius do
			for dc = -radius, radius do
				pattern[row + dr][col + dc] = {Filled = false}
			end
		end
	end
	
	local padding = 4
	local step = radius * 2 + 6
	
	if size.X > size.Y then
		local remainder = (size.X - 1 - (padding * 2)) % step
		local offset = math.floor(remainder / 2)
		for row = padding, size.X - 1 - padding, step do
			pillar(row + offset, padding)
			pillar(row + offset, size.Y - 1 - padding)
		end
	else
		local remainder = (size.Y - 1 - (padding * 2)) % step
		local offset = math.floor(remainder / 2)
		for col = padding, size.Y - 1 - padding, step do
			pillar(padding, col + offset)
			pillar(size.X - 1 - padding, col + offset)
		end
	end
	
	return pattern, size, position
end

function ThemeMachine:CreateCrossRoom(size, position)
	size = self:MakeVector2Odd(size, -1)
	
	local min = 5
	local max = math.ceil(math.min(size.X, size.Y) / 4)
	local radius = self.Random:NextInteger(min, max)
	
	local axisX = self.Random:NextInteger(radius, size.X - 1 - radius)
	local axisY = self.Random:NextInteger(radius, size.Y - 1 - radius)
		
	local pattern = {}
	for row = 0, size.X - 1 do
		pattern[row] = {}
		for col = 0, size.Y - 1 do
			local ax = math.abs(axisX - row)
			local ay = math.abs(axisY - col)
			
			local tile = {Filled = (ax < radius) or (ay < radius)}
			
			if ax == ay and ax == (radius - 1) then
				--self:AddFeature(tile, "Light")
			end
			
			if (row == 0) or (row == size.X - 1) then
				if ay == 0 then
					tile.Walls = {[row == 0 and "NegX" or "PosX"] = "Door"}
				end
			
			elseif (col == 0) or (col == size.Y - 1) then
				if ax == 0 then
					tile.Walls = {[col == 0 and "NegY" or "PosY"] = "Door"}
				end
			end
			
			pattern[row][col] = tile
		end
	end
	
	return pattern, size, position
end

function ThemeMachine:GenerateChunk(chunkPosition)
	local chunkSize = self.Dungeon.ChunkSize
	local roomSize = chunkSize - self.Dungeon.ChunkPadding
	local choice = self.Random:NextInteger(1, 4)
	
	local patternArgs = {}
			
	if choice == 1 then
		local size = Vector2.new(
			self.Random:NextInteger(16, 32),
			self.Random:NextInteger(16, 32)
		)
		
		local position = Vector2.new(
			self.Random:NextInteger(0, roomSize.X - size.X - 1),
			self.Random:NextInteger(0, roomSize.Y - size.Y - 1)
		)
		position = position + chunkPosition * chunkSize
		
		local subChoice = self.Random:NextInteger(1, 3)
		
		if subChoice == 1 then
			patternArgs = {self:CreateSquareRoom(size, position)}
		elseif subChoice == 2 then
			patternArgs = {self:CreateSquareRoomWithPillars(size, position)}
		elseif subChoice == 3 then
			patternArgs = {self:CreateSquareRoomWithLargePillar(size, position)}
		end
	
	elseif choice == 2 then
		local diameter = self.Random:NextInteger(16, 32)
		
		local position = Vector2.new(
			self.Random:NextInteger(0, roomSize.X - diameter - 1),
			self.Random:NextInteger(0, roomSize.Y - diameter - 1)
		)
		position = position + chunkPosition * chunkSize
		
		local subChoice = self.Random:NextInteger(1, 2)
		
		if subChoice == 1 then
			patternArgs = {self:CreateCircularRoom(diameter, position)}
		elseif subChoice == 2 then
			local innerDiameter = diameter - self.Random:NextInteger(12, diameter - 4)
			
			patternArgs = {self:CreateRingRoom(diameter, innerDiameter, position)}
		end
	elseif choice == 3 then
		local size = Vector2.new(
			self.Random:NextInteger(16, 32),
			self.Random:NextInteger(16, 32)
		)
		
		local position = Vector2.new(
			self.Random:NextInteger(0, roomSize.X - size.X - 1),
			self.Random:NextInteger(0, roomSize.Y - size.Y - 1)
		)
		position = position + chunkPosition * chunkSize
		
		patternArgs = {self:CreateCrossRoom(size, position)}
	elseif choice == 4 then
		local size = Vector2.new(
			self.Random:NextInteger(16, 32),
			self.Random:NextInteger(16, 32)
		)
		
		local position = Vector2.new(
			self.Random:NextInteger(0, roomSize.X - size.X - 1),
			self.Random:NextInteger(0, roomSize.Y - size.Y - 1)
		)
		position = position + chunkPosition * chunkSize
		
		local shapes = {"Corners", "Plus", "HVertical", "HHorizontal", "SVertical", "SHorizontal"}
		local shape = shapes[self.Random:NextInteger(1, #shapes)]
		
		patternArgs = {self:CreateStarRoom(size, position, shape)}
	end
	
	self.Dungeon:ApplyPattern(unpack(patternArgs))
end

function ThemeMachine:GenerateRooms()
	for chunkRow = self.Dungeon.PaddingChunks, self.Dungeon.SizeInChunks.X - 1 - self.Dungeon.PaddingChunks do
		for chunkCol = self.Dungeon.PaddingChunks, self.Dungeon.SizeInChunks.Y - 1 - self.Dungeon.PaddingChunks do
			self:GenerateChunk(Vector2.new(chunkRow, chunkCol))
		end
	end
end

function ThemeMachine:GenerateFeatures(tile)
	
end

function ThemeMachine:TileToWorldPosition(position)
	return Vector3.new(position.X, 0, position.Y) * self.Dungeon.TileSize
end

function ThemeMachine:CreateFeatures(tile)
	local worldPosition = self:TileToWorldPosition(tile.Position)
	
	for _, feature in pairs(tile.Features) do
		if feature == "Light" then
			local torch = self.Storage.Models.Torch:Clone()
			torch:SetPrimaryPartCFrame(CFrame.new(worldPosition + Vector3.new(0, 2, 0)))
			torch.Parent = self.Dungeon.Model
		end
	end
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

function ThemeMachine:IsTileWall(tile)
	return self.Dungeon:IsTileWall(tile)
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

function ThemeMachine:TerrainFillEmptyTiles(...)
	self:TerrainFillTiles("Empty", ...)
end

function ThemeMachine:TerrainFillFilledTiles(...)
	self:TerrainFillTiles("Filled", ...)
end

function ThemeMachine:TerrainFillTiles(option, position, material, dy, leaveGaps)
	if dy == nil then dy = 0 end
	if leaveGaps == nil then leaveGaps = true end
	
	local tile = self.Dungeon:Get(position)
	
	local function check(tile)
		if tile.TerrainFilled then return false end
		if option == "Empty" then
			return (not tile.Filled)
		elseif option == "Filled" then
			return tile.Filled
		end
	end
	
	-- now for the floor
	if not check(tile) then return end
	local row = position.X
	local col = position.Y
	
	while true do --breaks
		if row > (self.Dungeon.Size.X - 1) then break end
		
		tile = self.Dungeon:Get(Vector2.new(row, col))
		if not check(tile) then break end
		
		tile.TerrainFilled = true
		
		row = row + 1
	end
	row = row - 1
	
	local function canAddRow()
		for r = position.X, row do
			local tile = self.Dungeon:Get(Vector2.new(r, col))
			if not check(tile) then
				return false
			end
		end
		return true
	end
	
	while true do --breaks
		col = col + 1
		
		if col > (self.Dungeon.Size.Y - 1) then break end
		
		if canAddRow() then
			for r = position.X, row do
				tile = self.Dungeon:Get(Vector2.new(r, col))
				tile.TerrainFilled = true
			end
		else
			break
		end
	end
	col = col - 1
	
	local delta = Vector2.new(row, col) - position
	local size = delta + Vector2.new(1, 1)
	local center = position + (size / 2) - Vector2.new(0.5, 0.5)
	
	local dw = -3.9
	if not leaveGaps then
		dw = 1
	end
	
	local size = Vector3.new(size.X, 0, size.Y) * self.Dungeon.TileSize + Vector3.new(dw, 16, dw)
	local position = Vector3.new(center.X * self.Dungeon.TileSize, 6 + dy, center.Y * self.Dungeon.TileSize)
	
	workspace.Terrain:FillBlock(CFrame.new(position), size, material)
end



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