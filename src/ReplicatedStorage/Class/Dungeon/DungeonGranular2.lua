local Super = require(script.Parent)
local DungeonGranular = Super:Extend()

DungeonGranular.CellSize = 4
DungeonGranular.WallHeight = 12
DungeonGranular.FloorThickness = 1

DungeonGranular.TileSize = DungeonGranular.CellSize

function DungeonGranular:OnCreated()
	Super.OnCreated(self)
	
	local seed = math.floor(tick())
	print("Dungeon generating with seed", seed)
	workspace.DungeonSeed.Value = seed
	self.Random = Random.new(seed)
	
	self.ThemeMachine = self:CreateNew("ThemeMachine2"..self.Theme){
		Dungeon = self,
		Random = self.Random,
	}
	
	self.ThemeMachine:SetUpLighting()
	self.ThemeMachine:SetUpMusic()
	
	self.RoomTileGroups = {}
	self.Rooms = {}
	
	local grid, patterns
	
	repeat
		grid = {}
		patterns = {}
		
		local generatedPatterns = self.ThemeMachine:CreatePatterns(self.RoomCount)
		local roomsAttached = 0
		
		for index, pattern in pairs(generatedPatterns) do
			local rotations = self.Random:NextInteger(0, 3)
			for rotation = 1, rotations do
				pattern = self:RotatePattern(pattern)
			end
			
			if index == 1 then
				self:ApplyPattern(grid, pattern)
				table.insert(patterns, pattern)
				
				roomsAttached += 1
			else
				local success
				local attempts = 1
				repeat
					local newGrid
					success, newGrid, pattern = self:TryAttachingPattern(grid, pattern)
					if success then
						table.insert(patterns, pattern)
						grid = newGrid
					else
						pattern = self:RotatePattern(pattern)
					end
					attempts += 1
				until success or attempts >= 4
				
				if success then
					roomsAttached += 1
				end
			end
		end
	until roomsAttached == self.RoomCount
	
	self.Patterns = patterns
	
	for index, pattern in pairs(self.Patterns) do
		for _, row in pairs(pattern.Grid) do
			for _, cell in pairs(row) do
				local position = pattern.Position + cell.Position
				self:GetCell(grid, position).PatternId = index
			end
		end
	end
	
	grid = self:ConstructHallways(grid)
	
	
	
	self:BuildGrid(grid)
end

function DungeonGranular:GetCell(grid, position)
	if grid[position.Y] then
		return grid[position.Y][position.X]
	else
		return nil
	end
end

function DungeonGranular:SetCell(grid, position, cellIn)
	local cell
	
	if cellIn then
		cell = {
			Position = position,
			Walls = {},
		}
		for key, val in pairs(cellIn) do
			cell[key] = val
		end
	end
	
	if not grid[position.Y] then
		grid[position.Y] = {}
	end
	grid[position.Y][position.X] = cell
end

function DungeonGranular:RemoveCell(grid, position)
	if grid[position.Y] then
		grid[position.Y][position.X] = nil
	end
end

function DungeonGranular:UpdateCell(grid, position, data)
	if not self:GetCell(grid, position) then
		self:SetCell(grid, position)
	end
	
	for key, val in pairs(data) do
		grid[position.Y][position.X][key] = val
	end
end

function DungeonGranular:DoesFeatureFit(grid, feature)
	local size, position = feature:GetFootprint()

	for dx = 0, size.X - 1 do
		for dy = 0, size.Y - 1 do
			local cell = self:GetCell(grid, position + Vector2.new(dx, dy))
			if feature.RequiresFilled and (not cell) then
				return false, "Missing cell"
			end
			if cell.Features and #cell.Features > 0 then
				return false, "Existing features"
			end
			if cell.Occupied then
				return false, "Cell occupied"
			end
			if cell.NoFeatures then
				return false, "No features allowed"
			end
		end
	end
	return true
end

function DungeonGranular:IsFeatureAgainstWall(grid, feature)
	local cell = self:GetCell(grid, feature.Position)
	if not cell then return false end
	if not self:IsCellWall(cell) then return false end

	local wall = "NegX"
	local vertical = true
	if feature.Rotation == 1 then
		wall = "NegY"
		vertical = false
	elseif feature.Rotation == 2 then
		wall = "PosX"
	elseif feature.Rotation == 3 then
		wall = "PosY"
		vertical = false
	end

	local size, position = feature:GetFootprint()
	for dx = 0, size.X - 1 do
		for dy = 0, size.Y - 1 do
			local otherCell = self:GetCell(grid, position + Vector2.new(dx, dy))
			if not otherCell then return false end

			if vertical and (otherCell.Position.X == cell.Position.X) then
				if not (otherCell.Walls and otherCell.Walls[wall] == "Wall") then
					return false
				end

			elseif (not vertical) and (otherCell.Position.Y == cell.Position.Y) then
				if not (otherCell.Walls and otherCell.Walls[wall] == "Wall") then
					return false
				end
			end
		end
	end

	return true
end

function DungeonGranular:ApplyFeature(grid, feature)
	local size, position = feature:GetFootprint()

	for dx = 0, size.X - 1 do
		for dy = 0, size.Y - 1 do
			self:UpdateCell(grid, position + Vector2.new(dx, dy), {
				Occupied = true,
			})
		end
	end

	self:AddFeature(self:GetCell(grid, feature.Position), feature)
end

function DungeonGranular:ApplyFeatureIfFits(grid, feature)
	local success, reason = self:DoesFeatureFit(grid, feature) 
	if success then
		self:ApplyFeature(grid, feature)
		return true
	else
		return false, reason
	end
end

function DungeonGranular:AddFeature(cell, feature)
	if not cell.Features then
		cell.Features = {}
	end
	
	table.insert(cell.Features, feature)
end

function DungeonGranular:ConstructHallways(grid)
	grid = self:DeepCopy(grid)
	
	local gridConnections = {}
	for _, row in pairs(grid) do
		for _, cell in pairs(row) do
			if cell.IsConnection then
				table.insert(gridConnections, cell)
			end
		end
	end
	
	local rangeSq = 64 ^ 2
	local possibilities = {}
	for hereIndex = 1, #gridConnections do
		for thereIndex = hereIndex, #gridConnections do
			local here = gridConnections[hereIndex]
			local there = gridConnections[thereIndex]
			
			if there ~= here then
				local delta = (there.Position - here.Position)
				local distanceSq = delta.X ^ 2 + delta.Y ^ 2
				if distanceSq <= rangeSq then
					table.insert(possibilities, {here, there})
				end
			end
		end
	end
	self:Shuffle(possibilities)
	
	local function sign(number)
		if number < 0 then
			return -1
		else
			-- intentionally returns 1 on number == 0
			return 1
		end
	end
	
	for _, possibility in pairs(possibilities) do
		local a = possibility[1]
		local b = possibility[2]
		
		local cornerA = a.Position + a.Direction * 2
		local cornerB = b.Position + b.Direction * 2
		
		local pattern = {
			Position = Vector2.new(0, 0),
			Grid = {},
		}
		
		if a.Direction == b.Direction then
			-- do nothing
		elseif a.Direction == -b.Direction then
			if a.Direction.X == 0 then
				local midY = math.floor((a.Position.Y + b.Position.Y) / 2)
				
				for y = cornerA.Y, midY, sign(midY - cornerA.Y) do
					for dx = -1, 1 do
						local position = Vector2.new(cornerA.X + dx, y)
						self:SetCell(pattern.Grid, position, {Position = position, Occupied = dx == 0})
					end
				end
				
				for y = cornerB.Y, midY, sign(midY - cornerB.Y) do
					for dx = -1, 1 do
						local position = Vector2.new(cornerB.X + dx, y)
						self:SetCell(pattern.Grid, position, {Position = position, Occupied = dx == 0})
					end
				end
				
				for x = cornerA.X, cornerB.X, sign(cornerB.X - cornerA.X) do
					for dy = -1, 1 do
						local position = Vector2.new(x, midY + dy)
						self:SetCell(pattern.Grid, position, {Position = position, Occupied = dy == 0})
					end
				end
				
				for dx = -1, 1 do
					for dy = -1, 1 do
						local position
						
						position = Vector2.new(cornerA.X + dx, midY + dy)
						self:SetCell(pattern.Grid, position, {Position = position, Occupied = (dx == 0) and (dy == 0)})
						
						position = Vector2.new(cornerB.X + dx, midY + dy)
						self:SetCell(pattern.Grid, position, {Position = position, Occupied = (dx == 0) and (dy == 0)})
					end
				end
			else
				local midX = math.floor((a.Position.X + b.Position.X) / 2)
				
				for x = cornerA.X, midX, sign(midX - cornerA.X) do
					for dy = -1, 1 do
						local position = Vector2.new(x, cornerA.Y + dy)
						self:SetCell(pattern.Grid, position, {Position = position, Occupied = (dy == 0)})
					end
				end
				
				for x = cornerB.X, midX, sign(midX - cornerB.X) do
					for dy = -1, 1 do
						local position = Vector2.new(x, cornerB.Y + dy)
						self:SetCell(pattern.Grid, position, {Position = position, Occupied = (dy == 0)})
					end
				end
				
				for y = cornerA.Y, cornerB.Y, sign(cornerB.Y - cornerA.Y) do
					for dx = -1, 1 do
						local position = Vector2.new(midX + dx, y)
						self:SetCell(pattern.Grid, position, {Position = position, Occupied = (dx == 0)})
					end
				end
				
				for dx = -1, 1 do
					for dy = -1, 1 do
						local position

						position = Vector2.new(midX + dx, cornerA.Y + dy)
						self:SetCell(pattern.Grid, position, {Position = position, Occupied = (dx == 0) and (dy == 0)})

						position = Vector2.new(midX + dx, cornerB.Y + dy)
						self:SetCell(pattern.Grid, position, {Position = position, Occupied = (dx == 0) and (dy == 0)})
					end
				end
			end
		else
			if a.Direction.X == 0 then
				for y = cornerA.Y, cornerB.Y, sign(cornerB.Y - cornerA.Y) do
					for dx = -1, 1 do
						local position = Vector2.new(cornerA.X + dx, y)
						self:SetCell(pattern.Grid, position, {Position = position, Occupied = dx == 0})
					end
				end
				
				for x = cornerB.X, cornerA.X, sign(cornerA.X - cornerB.X) do
					for dy = -1, 1 do
						local position = Vector2.new(x, cornerB.Y + dy)
						self:SetCell(pattern.Grid, position, {Position = position, Occupied = dy == 0})
					end
				end
				
				for dx = -1, 1 do
					for dy = -1, 1 do
						local position = Vector2.new(cornerA.X + dx, cornerB.Y + dy)
						self:SetCell(pattern.Grid, position, {Position = position, Occupied = (dx == 0) and (dy == 0)})
					end
				end
			else
				for y = cornerB.Y, cornerA.Y, sign(cornerA.Y - cornerB.Y) do
					for dx = -1, 1 do
						local position = Vector2.new(cornerB.X + dx, y)
						self:SetCell(pattern.Grid, position, {Position = position, Occupied = dx == 0})
					end
				end
				
				for x = cornerA.X, cornerB.X, sign(cornerB.X - cornerA.X) do
					for dy = -1, 1 do
						local position = Vector2.new(x, cornerA.Y + dy)
						self:SetCell(pattern.Grid, position, {Position = position, Occupied = dy == 0})
					end
				end
				
				for dx = -1, 1 do
					for dy = -1, 1 do
						local position = Vector2.new(cornerB.X + dx, cornerA.Y + dy)
						self:SetCell(pattern.Grid, position, {Position = position, Occupied = (dx == 0) and (dy == 0)})
					end
				end
			end
		end
		
		if self:DoesPatternFit(grid, pattern) then
			self:ApplyPattern(grid, pattern)
			self:BuildDoorCell(grid, a.Position, cornerA, {a.PatternId, b.PatternId})
			self:BuildDoorCell(grid, b.Position, cornerB, {a.PatternId, b.PatternId})
		end
	end
	
	return grid
end

function DungeonGranular:BuildDoorCell(grid, a, b, patternIds)
	grid[a.Y][a.X].IsConnection = false
	grid[b.Y][b.X].IsConnection = false
	
	local c = (a + b) / 2
	local direction = grid[a.Y][a.X].Direction

	if direction.Y == 0 then
		for dy = -1, 1 do
			local position = c + Vector2.new(0, dy)
			self:SetCell(grid, position, {Position = position})
		end
	else
		for dx = -1, 1 do
			local position = c + Vector2.new(dx, 0)
			self:SetCell(grid, position, {Position = position})
		end
	end

	self:SetCell(grid, c, {
		Position = c,
		IsDoor = true,
		Direction = direction,
		PatternIds = patternIds,
	})
end

function DungeonGranular:TryAttachingPattern(grid, pattern)
	pattern = self:DeepCopy(pattern)
	
	local gridConnections = {}
	for _, row in pairs(grid) do
		for _, cell in pairs(row) do
			if cell.IsConnection then
				table.insert(gridConnections, cell)
			end
		end
	end
	
	local patternConnections = {}
	for _, row in pairs(pattern.Grid) do
		for _, cell in pairs(row) do
			if cell.IsConnection then
				table.insert(patternConnections, cell)
			end
		end
	end
	
	local possiblePairs = {}
	for _, gridConnection in pairs(gridConnections) do
		for _, patternConnection in pairs(patternConnections) do
			if gridConnection.Direction + patternConnection.Direction == Vector2.new(0, 0) then
				table.insert(possiblePairs, {gridConnection, patternConnection})
			end
		end
	end
	
	self:Shuffle(possiblePairs)
	
	for _, pair in pairs(possiblePairs) do
		local gridCell = pair[1]
		local patternCell = pair[2]
		
		local desiredPatternCellPosition = gridCell.Position + gridCell.Direction * 2
		pattern.Position = desiredPatternCellPosition - patternCell.Position
		
		if self:DoesPatternFit(grid, pattern) then
			grid = self:DeepCopy(grid)
			self:ApplyPattern(grid, pattern)
			
			local a = gridCell.Position
			local b = desiredPatternCellPosition
			
			self:BuildDoorCell(grid, a, b)
			
			return true, grid, pattern
		end
	end
	
	return false, nil, pattern
end

function DungeonGranular:RotatePattern(pattern)
	local grid = pattern.Grid
	local newGrid = {}
	
	-- transpose
	for _, row in pairs(grid) do
		for _, cell in pairs(row) do
			local newCell = self:DeepCopy(cell)
			
			-- position
			local position = Vector2.new(cell.Position.Y, cell.Position.X)
			newCell.Position = position
			
			-- direction
			if newCell.Direction == Vector2.new(1, 0) then
				newCell.Direction = Vector2.new(0, 1)
			elseif newCell.Direction == Vector2.new(0, -1) then
				newCell.Direction = Vector2.new(1, 0)
			elseif newCell.Direction == Vector2.new(-1, 0) then
				newCell.Direction = Vector2.new(0, -1)
			elseif newCell.Direction == Vector2.new(0, 1) then
				newCell.Direction = Vector2.new(-1, 0)
			end
			
			self:SetCell(newGrid, position, newCell)
		end
	end
	
	-- reverse rows
	local size = self:GetGridSize(newGrid)
	local cx = math.floor((size.X - 1) / 2)
	for y = 0, size.Y - 1 do
		for x = 0, cx do
			local rx = (size.X - 1) - x
			local a = Vector2.new(x, y)
			local b = Vector2.new(rx, y)
			
			local cellA = self:GetCell(newGrid, a)
			if cellA then cellA.Position = b end
			
			local cellB = self:GetCell(newGrid, b)
			if cellB then cellB.Position = a end
			
			self:SetCell(newGrid, a, cellB)
			self:SetCell(newGrid, b, cellA)
		end
	end
	
	local newPattern = self:DeepCopy(pattern)
	newPattern.Grid = newGrid
	
	return newPattern
end

function DungeonGranular:GetGridBounds(grid)
	local minX, minY, maxX, maxY = 0, 0, 0, 0
	for _, row in pairs(grid) do
		for _, cell in pairs(row) do
			local position = cell.Position
			minX = math.min(minX, position.X)
			minY = math.min(minY, position.Y)
			maxX = math.max(maxX, position.X)
			maxY = math.max(maxY, position.Y)
		end
	end
	
	return Vector2.new(minX, minY), Vector2.new(maxX, maxY)
end

function DungeonGranular:GetGridSize(grid)
	local min, max = self:GetGridBounds(grid)
	return max - min + Vector2.new(1, 1)
end

function DungeonGranular:ApplyPattern(grid, pattern)
	for _, row in pairs(pattern.Grid) do
		for _, cell in pairs(row) do
			local position = pattern.Position + cell.Position
			
			local newCell = self:DeepCopy(cell)
			newCell.Position = position
			self:SetCell(grid, position, newCell)
		end
	end
end

function DungeonGranular:DoesPatternFit(grid, pattern)
	local cellCount = 0
	
	for _, row in pairs(pattern.Grid) do
		for _, cell in pairs(row) do
			cellCount += 1
			for dx = -1, 1 do
				for dy = -1, 1 do
					local position = pattern.Position + cell.Position + Vector2.new(dx, dy)

					if self:GetCell(grid, position) then
						return false
					end
				end
			end
		end
	end
	
	if cellCount == 0 then
		return false
	end
	
	return true
end

function DungeonGranular:BuildWalls(grid, position)
	local cell = self:GetCell(grid, position)

	local function scan(startPosition, moveDirection, wallDirection)
		local cursor = startPosition

		local hereWall, thereWall
		if wallDirection == Vector2.new(1, 0) then
			hereWall = "PosX"
			thereWall = "NegX"
		elseif wallDirection == Vector2.new(-1, 0) then
			hereWall = "NegX"
			thereWall = "PosX"
		elseif wallDirection == Vector2.new(0, 1) then
			hereWall = "PosY"
			thereWall = "NegY"
		elseif wallDirection == Vector2.new(0, -1) then
			hereWall = "NegY"
			thereWall = "PosY"
		end

		local function check()
			local here = self:GetCell(grid, cursor)
			if not here then return false, "external" end
			if here.Walls and here.Walls[hereWall] then return false, "other" end

			local there = self:GetCell(grid, cursor + wallDirection)
			if there then
				if there then return false, "internal" end
				if there.Walls and there.Walls[thereWall] then return false, "other" end
			end

			return true
		end

		local tiles = {}
		local pass, reason
		repeat
			pass, reason = check()

			if pass then
				table.insert(tiles, self:GetCell(grid, cursor))
				cursor = cursor + moveDirection
			end
		until not pass

		return tiles, reason
	end

	local function fullScan(startPosition, moveDirection, wallDirection)
		local tiles, reasonStart, reasonEnd

		tiles, reasonStart = scan(startPosition, -moveDirection, wallDirection)
		if tiles[1] then
			tiles, reasonEnd = scan(tiles[#tiles].Position, moveDirection, wallDirection)

			return true, tiles, reasonStart, reasonEnd
		end

		return false
	end

	local wallDirection

	-- posX
	wallDirection = Vector2.new(1, 0)
	local success, tiles, reasonStart, reasonEnd = fullScan(position, Vector2.new(0, 1), wallDirection)
	if success then
		for _, tile in pairs(tiles) do
			tile.Walls.PosX = "Wall"

			local other = self:GetCell(grid, tile.Position + wallDirection)
			if other then
				other.Walls.NegX = "Wall"
			end
		end

		local tileStart = tiles[1]
		local tileEnd = tiles[#tiles]

		local x = (tileStart.Position.X + 0.5) * self.CellSize + 0.5

		local zStart = (tileStart.Position.Y - 0.5) * self.CellSize
		if reasonStart == "internal" then
			zStart = zStart + 1
		elseif reasonStart == "external" then
			zStart = zStart - 1
		end

		local zEnd = (tileEnd.Position.Y + 0.5) * self.CellSize
		if reasonEnd == "internal" then
			zEnd = zEnd - 1
		elseif reasonEnd == "external" then
			zEnd = zEnd + 1
		end

		local z = (zStart + zEnd) / 2

		self.ThemeMachine:CreateWall(Vector3.new(1, self.WallHeight, math.abs(zEnd - zStart)), Vector3.new(x, self.WallHeight / 2, z))
	end

	-- posY
	wallDirection = Vector2.new(0, 1)
	local success, tiles, reasonStart, reasonEnd = fullScan(position, Vector2.new(1, 0), wallDirection)
	if success then
		for _, tile in pairs(tiles) do
			tile.Walls.PosY = "Wall"

			local other = self:GetCell(grid, tile.Position + wallDirection)
			if other then
				other.Walls.NegY = "Wall"
			end
		end

		local tileStart = tiles[1]
		local tileEnd = tiles[#tiles]

		local z = (tileStart.Position.Y + 0.5) * self.CellSize + 0.5

		local xStart = (tileStart.Position.X - 0.5) * self.CellSize
		local xEnd = (tileEnd.Position.X + 0.5) * self.CellSize
		local x = (xStart + xEnd) / 2

		self.ThemeMachine:CreateWall(Vector3.new(math.abs(xEnd - xStart), self.WallHeight, 1), Vector3.new(x, self.WallHeight / 2, z))
	end

	-- negX
	wallDirection = Vector2.new(-1, 0)
	local success, tiles, reasonStart, reasonEnd = fullScan(position, Vector2.new(0, 1), wallDirection)
	if success then
		for _, tile in pairs(tiles) do
			tile.Walls.NegX = "Wall"

			local other = self:GetCell(grid, tile.Position + wallDirection)
			if other then
				other.Walls.PosX = "Wall"
			end
		end

		local tileStart = tiles[1]
		local tileEnd = tiles[#tiles]

		local x = (tileStart.Position.X - 0.5) * self.CellSize - 0.5

		local zStart = (tileStart.Position.Y - 0.5) * self.CellSize
		if reasonStart == "internal" then
			zStart = zStart + 1
		elseif reasonStart == "external" then
			zStart = zStart - 1
		end

		local zEnd = (tileEnd.Position.Y + 0.5) * self.CellSize
		if reasonEnd == "internal" then
			zEnd = zEnd - 1
		elseif reasonEnd == "external" then
			zEnd = zEnd + 1
		end

		local z = (zStart + zEnd) / 2

		self.ThemeMachine:CreateWall(Vector3.new(1, self.WallHeight, math.abs(zEnd - zStart)), Vector3.new(x, self.WallHeight / 2, z))
	end

	-- negY
	wallDirection = Vector2.new(0, -1)
	local success, tiles, reasonStart, reasonEnd = fullScan(position, Vector2.new(1, 0), wallDirection)
	if success then
		for _, tile in pairs(tiles) do
			tile.Walls.NegY = "Wall"

			local other = self:GetCell(grid, tile.Position + wallDirection)
			if other then
				other.Walls.PosY = "Wall"
			end
		end

		local tileStart = tiles[1]
		local tileEnd = tiles[#tiles]

		local z = (tileStart.Position.Y - 0.5) * self.CellSize - 0.5

		local xStart = (tileStart.Position.X - 0.5) * self.CellSize
		local xEnd = (tileEnd.Position.X + 0.5) * self.CellSize
		local x = (xStart + xEnd) / 2

		self.ThemeMachine:CreateWall(Vector3.new(math.abs(xEnd - xStart), self.WallHeight, 1), Vector3.new(x, self.WallHeight / 2, z))
	end
end

function DungeonGranular:BuildCell(grid, position)
	local tile = self:GetCell(grid, position)
	if not tile then return end
	if tile.Rendered then return end
	
	local row = position.X
	local col = position.Y

	while true do --breaks
		tile = self:GetCell(grid, Vector2.new(row, col))
		if not tile then break end
		if tile.Rendered then break end

		tile.Rendered = true

		row = row + 1
	end
	row = row - 1

	local function canAddRow()
		for r = position.X, row do
			local tile = self:GetCell(grid, Vector2.new(r, col))
			if (not tile) or tile.Rendered then
				return false
			end
		end
		return true
	end

	while true do --breaks
		col = col + 1

		if canAddRow() then
			for r = position.X, row do
				tile = self:GetCell(grid, Vector2.new(r, col))
				tile.Rendered = true
			end
		else
			break
		end
	end
	col = col - 1

	local delta = Vector2.new(row, col) - position
	local size = delta + Vector2.new(1, 1)
	local center = position + (size / 2) - Vector2.new(0.5, 0.5)

	local size = Vector3.new(size.X, 0, size.Y) * self.CellSize + Vector3.new(0, self.FloorThickness, 0)
	local position = Vector3.new(center.X * self.CellSize, -self.FloorThickness / 2, center.Y * self.CellSize)

	self.ThemeMachine:CreateFloor(size, position)
end

function DungeonGranular:BuildDoor(grid, cell)
	local rotation = CFrame.Angles(0, math.atan2(cell.Direction.Y, cell.Direction.X) + math.pi / 2, 0)
	local position = Vector3.new(cell.Position.X, 0, cell.Position.Y) * self.CellSize + Vector3.new(0, 6, 0)
	
	local cframe = CFrame.new(position) * rotation
	self.ThemeMachine:CreateDoor(cframe, {
		self.Rooms[cell.PatternIds[1]],
		self.Rooms[cell.PatternIds[2]],
	})

	-- door jam (i'm pretty sure it's spelled differently and may not even be this)
	local jamSize
	local jamWidth = 2
	if cell.Direction.Y == 0 then
		jamSize = Vector3.new(1, self.WallHeight, jamWidth)
	else
		jamSize = Vector3.new(jamWidth, self.WallHeight, 1)
	end
	local jamDistance = 5
	local jamRightCFrame = cframe * CFrame.new(jamDistance, 0, 0)
	local jamLeftCFrame = cframe * CFrame.new(-jamDistance, 0, 0)
	self.ThemeMachine:CreateDoorjamb(jamSize, jamRightCFrame.Position)
	self.ThemeMachine:CreateDoorjamb(jamSize, jamLeftCFrame.Position)

	-- occupy spaces
	local radius = 1
	for dx = -radius, radius do
		for dy = -radius, radius do
			local other = self:GetCell(grid, cell.Position + Vector2.new(dx, dy))
			if other then
				other.Occupied = true
			end
		end
	end
end

function DungeonGranular:IsCellWall(cell)
	return
		cell.Walls ~= nil and
		cell.Walls.NegX == "Wall" or
		cell.Walls.PosX == "Wall" or
		cell.Walls.NegY == "Wall" or
		cell.Walls.PosY == "Wall"
end

function DungeonGranular:BuildGrid(grid)
	self.Model = Instance.new("Model")
	self.Model.Name = "Dungeon"
	
	local min = Vector2.new(0, 0)
	local max = Vector2.new(0, 0)
	
	local doorCells = {}
	
	for _, row in pairs(grid) do
		for _, cell in pairs(row) do
			self:BuildWalls(grid, cell.Position)
			
			if cell.IsDoor then
				table.insert(doorCells, cell)
			end
			
			min = Vector2.new(
				math.min(min.X, cell.Position.X),
				math.min(min.Y, cell.Position.Y)
			)
			max = Vector2.new(
				math.max(max.X, cell.Position.X),
				math.max(max.Y, cell.Position.Y)
			)
		end
	end
	
	for index, pattern in pairs(self.Patterns) do
		local roomTileGroup = {Tiles = {}}
		for _, row in pairs(pattern.Grid) do
			for _, cell in pairs(row) do
				local position = pattern.Position + cell.Position
				table.insert(roomTileGroup.Tiles, self:GetCell(grid, position))
			end
		end
		self.RoomTileGroups[index] = roomTileGroup
		
		local room = self:CreateNew"RoomGranular"{
			Dungeon = self,
			RoomTileGroup = roomTileGroup,
			Id = index,
		}
		room:InitSpawns()
		room.Completed:Connect(function()
			self:OnRoomCompleted(room)
		end)
		
		self.Rooms[index] = room
	end
	
	self.StartRoom = self.Rooms[1]
	self.StartRoom:Complete()
	
	for _, cell in pairs(doorCells) do
		if not cell.PatternIds then
			local a = cell.Position + cell.Direction
			a = self:GetCell(grid, a)
			
			local b = cell.Position - cell.Direction
			b = self:GetCell(grid, b)
			
			cell.PatternIds = {a.PatternId, b.PatternId}
		end
		
		self:BuildDoor(grid, cell)
	end
	
	for x = min.X, max.X do
		for y = min.Y, max.Y do
			local cell = self:GetCell(grid, Vector2.new(x, y))
			self.ThemeMachine:GenerateFeatures(grid, cell)
		end
	end
	
	for x = min.X, max.X do
		for y = min.Y, max.Y do
			local position = Vector2.new(x, y)
			
			-- build features
			local cell = self:GetCell(grid, position)
			if cell and cell.Features then
				for _, feature in pairs(cell.Features) do
					feature:Finalize()
				end
			end
			
			-- build the floor
			self:BuildCell(grid, position)
		end
	end
	
	self.ThemeMachine:PostBuild(grid, min, max)
	
	local physicsService = game:GetService("PhysicsService")
	for _, object in pairs(self.Model:GetDescendants()) do
		if
			object:IsA("BasePart") and
				(not physicsService:CollisionGroupContainsPart("Debris", object)) and
				(not physicsService:CollisionGroupContainsPart("DungeonInvisibleWall", object))
		then
			physicsService:SetPartCollisionGroup(object, "Dungeon")
		end
	end
	
	self.Model.Parent = workspace
end

function DungeonGranular:OnRoomCompleted()
	if not self.Active then return end
	
	local dungeonCompleted = true
	for _, room in pairs(self.Rooms) do
		if room.State ~= "Completed" then
			dungeonCompleted = false
			break
		end
	end
	
	if dungeonCompleted then
		self.Completed:Fire()
	end
end

function DungeonGranular:CleanUp()
	self.Active = false
	workspace.Terrain:Clear()

	if self.ThemeMachine.CleanUp then
		self.ThemeMachine:CleanUp()
	end
end

function DungeonGranular:Destroy()
	self.Model:Destroy()

	self:CleanUp()
end

function DungeonGranular:Explode()
	self:GetService("EffectsService"):RequestEffectAll("ExplodeDungeon", {Model = self.Model})
	game:GetService("Debris"):AddItem(self.Model, 2)

	self:CleanUp()
end

return DungeonGranular