local Super = require(script.Parent)
local DungeonGranular = Super:Extend()

DungeonGranular.TileSize = 4
DungeonGranular.WallHeight = 12

DungeonGranular.ChunkSize = Vector2.new(48, 48)
DungeonGranular.ChunkPadding = Vector2.new(5, 5)
DungeonGranular.SizeInChunks = Vector2.new(2, 1)
DungeonGranular.PaddingChunks = 1

DungeonGranular.FloorThickness = 1

function DungeonGranular:OnCreated()
	Super.OnCreated(self)
	
	if self.ChunkMap then
		self.SizeInChunks = Vector2.new(
			#self.ChunkMap[1],
			#self.ChunkMap
		)
	end
	
	self.SizeInChunks = self.SizeInChunks + Vector2.new(2, 2) * self.PaddingChunks
	self.Size = self.ChunkSize * self.SizeInChunks
	
	self.RoomTileGroups = {}
	self.Rooms = {}
	
	local seed = math.floor(tick())
	print("Dungeon generating with seed", seed)
	workspace.DungeonSeed.Value = seed
	self.Random = Random.new(seed)
	
	self.ThemeMachine = self:CreateNew("ThemeMachine"..self.Theme or ""){
		Dungeon = self,
		Random = self.Random,
	}
	
	self.ThemeMachine:SetUpLighting()
	self.ThemeMachine:SetUpMusic()
	self:CreateGrid()
	self:GenerateRooms()
	if self.CustomGenerateRooms then
		self:CustomGenerateRooms()
	end
	self:DetermineRooms()
	local chunkGrid = self:ChunkGenerateGrid()
	if self.CustomChunkGenerateGrid then
		self:CustomChunkGenerateGrid(chunkGrid, function(...) return self:ChunkCarveBetween(...) end)
	end
	self:ConstructHallways(chunkGrid)
	self:CleanUpDoors()
	self:RenderDungeon()
	
	for _, room in pairs(self.Rooms) do
		room:InitSpawns()
	end
	
	local startRoom
	if self.StartRoomChunkPosition then
		startRoom = self:GetRoomByChunkPosition(self.StartRoomChunkPosition)
	else
		repeat
			startRoom = self.Rooms[self.Random:NextInteger(0, #self.Rooms - 1)]
		until self:IsStartRoomLegal(startRoom)
	end
	
	self.StartRoom = startRoom
	self.StartRoom:Complete()
	self.StartRoom:CreateGuaranteedFloorItems()
end

function DungeonGranular:GetRoomByChunkPosition(chunkPosition)
	for _, room in pairs(self.Rooms) do
		if room.RoomTileGroup.ChunkPosition == chunkPosition then
			return room
		end
	end
	return nil
end

function DungeonGranular:IsStartRoomLegal(room)
	local roomTileGroup = room.RoomTileGroup
	local chunkPosition = roomTileGroup.ChunkPosition
	if self.StartRoomLegalChunkGrid then
		return self.StartRoomLegalChunkGrid[chunkPosition.X][chunkPosition.Y]
	else
		return true
	end
end

function DungeonGranular:ResetChunk(chunkPosition)
	local position = chunkPosition * self.ChunkSize
	for dx = 0, self.ChunkSize.X - 1 do
		for dy = 0, self.ChunkSize.Y - 1 do
			local x = position.X + dx
			local y = position.Y + dy
			
			self.Grid[x][y] = self:CreateCell(x, y)
		end
	end
end

function DungeonGranular:DistributeEncounters(encounters)
	local rooms = {}
	for _, room in pairs(self.Rooms) do
		if room ~= self.StartRoom then
			table.insert(rooms, room)
		end
	end
	
	-- positioned encounters go first
	for index = #encounters, 1, -1 do
		local encounter = encounters[index]
		if encounter.ChunkPosition then
			table.remove(encounters, index)
			
			local room = self:GetRoomByChunkPosition(encounter.ChunkPosition)
			table.remove(rooms, table.find(rooms, room))
			
			room.EncounterData = encounter
		end
	end
	
	-- random ones next
	for _, encounter in pairs(encounters) do
		local index = self.Random:NextInteger(1, #rooms)
		local room = table.remove(rooms, index)
		room.EncounterData = encounter
	end
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

function DungeonGranular:CleanUpDoors()
	for _, roomTileGroup in pairs(self.RoomTileGroups) do
		for index = #roomTileGroup.DoorTiles, 1, -1 do
			local doorTile = roomTileGroup.DoorTiles[index]
			if not doorTile.UsedDoor then
				doorTile.Walls = {}
				table.remove(roomTileGroup.DoorTiles, index)
			end
		end
	end
end

function DungeonGranular:ConstructHallway(roomTileGroupA, roomTileGroupB)
	local delta = (roomTileGroupB.ChunkPosition - roomTileGroupA.ChunkPosition)
	
	local directionA, directionB
	if delta.X > 0 then
		directionA = "PosX"
		directionB = "NegX"
	elseif delta.X < 0 then
		directionA = "NegX"
		directionB = "PosX"
	elseif delta.Y > 0 then
		directionA = "PosY"
		directionB = "NegY"
	elseif delta.Y < 0 then
		directionA = "NegY"
		directionB = "PosY"
	end
	
	local tileA = self:GetDoorByDirection(roomTileGroupA, directionA)
	local tileB = self:GetDoorByDirection(roomTileGroupB, directionB)
	
	if not (tileA and tileB) then return end
	
	tileA.UsedDoor = true
	tileB.UsedDoor = true
	
	local function fill(position, radius)
		local center = self:Get(position)
		if center then
			center.Occupied = true
		end
		
		for dr = -radius, radius do
			for dc = -radius, radius do
				local tile = self:Get(position + Vector2.new(dr, dc))
				if tile then
					tile.Filled = true
					tile.SpawnDisabled = true
				end
			end
		end
	end
	
	local delta = tileB.Position - tileA.Position
	if (directionA == "PosX") or (directionA == "NegX") then
		local midX = tileA.Position.X + math.floor(delta.X / 2)
		
		if delta.Y ~= 0 then
			for col = tileA.Position.Y, tileB.Position.Y, math.sign(delta.Y) do
				fill(Vector2.new(midX, col), 1)
			end
		end
		
		for row = tileA.Position.X, midX, math.sign(delta.X) do
			fill(Vector2.new(row, tileA.Position.Y), 1)
		end
		
		for row = midX, tileB.Position.X, math.sign(delta.X) do
			fill(Vector2.new(row, tileB.Position.Y), 1)
		end
	else
		local midY = tileA.Position.Y + math.floor(delta.Y / 2)
		
		if delta.X ~= 0 then
			for row = tileA.Position.X, tileB.Position.X, math.sign(delta.X) do
				fill(Vector2.new(row, midY), 1)
			end
		end
		
		for col = tileA.Position.Y, midY, math.sign(delta.Y) do
			fill(Vector2.new(tileA.Position.X, col), 1)
		end
		
		for col = midY, tileB.Position.Y, math.sign(delta.Y) do
			fill(Vector2.new(tileB.Position.X, col), 1)
		end
	end
end

function DungeonGranular:GetDoorByDirection(roomTileGroup, direction)
	for _, doorTile in pairs(roomTileGroup.DoorTiles) do
		if doorTile.Walls[direction] == "Door" then
			return doorTile
		end
	end
	return nil
end

function DungeonGranular:GetNearestDoor(roomTileGroupA, roomTileGroupB)
	local positionB = (roomTileGroupB.ChunkPosition + Vector2.new(0.5, 0.5)) * self.ChunkSize
	
	local best = nil
	local bestDistanceSq = math.huge
	for _, doorTile in pairs(roomTileGroupA.DoorTiles) do
		local delta = positionB - doorTile.Position
		local distanceSq = delta.X ^ 2 + delta.Y ^ 2
		if distanceSq < bestDistanceSq then
			best = doorTile
			bestDistanceSq = distanceSq
		end
	end
	
	return best
end

function DungeonGranular:GetRoomTileGroupByChunkPosition(chunkPosition)
	for _, roomTileGroup in pairs(self.RoomTileGroups) do
		if roomTileGroup.ChunkPosition == chunkPosition then
			return roomTileGroup
		end
	end
	return nil
end

function DungeonGranular:ChunkCarveBetween(a, b)
	local delta = b.Position - a.Position
	if delta.X > 0 then
		a.PosX = true
		b.NegX = true
	elseif delta.X < 0 then
		a.NegX = true
		b.PosX = true
	elseif delta.Y > 0 then
		a.PosY = true
		b.NegY = true
	elseif delta.Y < 0 then
		a.NegY = true
		b.PosY = true
	end
	a.Carved = true
	b.Carved = true
end

function DungeonGranular:ChunkGenerateGrid()
	if self.ChunkMap then
		return self:ChunkDecodeMap()
	else
		return self:ChunkGenerateGridRandom()
	end
end

-- A11Noob was here 9/23/2020
function DungeonGranular:ChunkDecodeMap()
	local chunkGrid = {}
	for row = self.PaddingChunks, self.SizeInChunks.X - 1 - self.PaddingChunks do
		chunkGrid[row] = {}
		for col = self.PaddingChunks, self.SizeInChunks.Y - 1 - self.PaddingChunks do
			chunkGrid[row][col] = {
				Position = Vector2.new(row, col),
				PosX = false,
				NegX = false,
				PosY = false,
				NegY = false,
				Carved = false
			}
		end
	end
	
	local function carve(row, col, dc, dr)
		local a = chunkGrid[row] and chunkGrid[row][col]
		local b = chunkGrid[row + dc] and chunkGrid[row + dc][col + dr]
		if not (a and b) then return end
		self:ChunkCarveBetween(a, b)
	end
	
	local y = self.PaddingChunks
	for _, str in pairs(self.ChunkMap) do
		local x = self.PaddingChunks
		for char in string.gmatch(str, ".") do
			if     char == ">" then
				carve(x, y, 1, 0)
			elseif char == "<" then
				carve(x, y, -1, 0)
			elseif char == "^" then
				carve(x, y, 0, -1)
			elseif char == "V" then
				carve(x, y, 0, 1)
			elseif char == "-" then
				carve(x, y, 1, 0)
				carve(x, y, -1, 0)
			elseif char == "|" then
				carve(x, y, 0, 1)
				carve(x, y, 0, -1)
			elseif char == "#" then
				carve(x, y, 1, 0)
				carve(x, y, -1, 0)
				carve(x, y, 0, 1)
				carve(x, y, 0, -1)
			elseif char == " " then
				local position = Vector2.new(x, y)
				self:ResetChunk(position)
				self:GetRoomByChunkPosition(position):Complete()
			end
			x += 1
		end
		y += 1
	end
	
	return chunkGrid
end

function DungeonGranular:ChunkGenerateGridRandom()
	local chunkGrid = {}
	for row = self.PaddingChunks, self.SizeInChunks.X - 1 - self.PaddingChunks do
		chunkGrid[row] = {}
		for col = self.PaddingChunks, self.SizeInChunks.Y - 1 - self.PaddingChunks do
			chunkGrid[row][col] = {
				Position = Vector2.new(row, col),
				PosX = false,
				NegX = false,
				PosY = false,
				NegY = false,
				Carved = false,
			}
		end
	end
	
	local function get(position)
		if chunkGrid[position.X] then
			return chunkGrid[position.X][position.Y]
		end
		return nil
	end
	
	local function getNeighbors(chunk)
		local neighbors = {}
		for _, delta in pairs{
			Vector2.new(1, 0),
			Vector2.new(-1, 0),
			Vector2.new(0, 1),
			Vector2.new(0, -1),
		} do
			local position = chunk.Position + delta
			table.insert(neighbors, get(position))
		end
		return neighbors
	end
	
	local function shuffle(list)
		for index = 1, #list do
			local swap = self.Random:NextInteger(1, #list)
			local temp = list[swap]
			list[swap] = list[index]
			list[index] = temp
		end
	end
	
	local start = chunkGrid[self.Random:NextInteger(self.PaddingChunks, self.SizeInChunks.X - 1 - self.PaddingChunks)][self.Random:NextInteger(self.PaddingChunks, self.SizeInChunks.Y - 1 - self.PaddingChunks)]
	local stack = {start}
	while #stack > 0 do
		-- look at the top of the stack
		local chunk = stack[#stack]
		
		-- find an uncarved neighbor at random
		local neighbors = getNeighbors(chunk)
		shuffle(neighbors)
		local chosen
		for _, neighbor in pairs(neighbors) do
			if not neighbor.Carved then
				chosen = neighbor
				break
			end
		end
		
		-- if we found one then carve
		-- otherwise pop off the stack
		if chosen then
			self:ChunkCarveBetween(chunk, chosen)
			table.insert(stack, chosen)
		else
			table.remove(stack, #stack)
		end
	end
	
	local function makeExtraDoor()
		local attempt = 0
		repeat
			attempt = attempt + 1
			
			local chunk = chunkGrid[self.Random:NextInteger(self.PaddingChunks, self.SizeInChunks.X - 1 - self.PaddingChunks)][self.Random:NextInteger(self.PaddingChunks, self.SizeInChunks.Y - 1 - self.PaddingChunks)]
			local choices = {"PosX", "NegX", "PosY", "NegY"}
			shuffle(choices)
			
			local function try(way)
				local other
				if way == "PosX" and (not chunk.PosX) then
					other = get(chunk.Position + Vector2.new(1, 0))
				elseif way == "PosY" and (not chunk.PosY) then
					other = get(chunk.Position + Vector2.new(0, 1))
				elseif way == "NegX" and (not chunk.NegX) then
					other = get(chunk.Position + Vector2.new(-1, 0))
				elseif way == "NegY" and (not chunk.NegY) then
					other = get(chunk.Position + Vector2.new(0, -1))
				end
				if other then
					self:ChunkCarveBetween(chunk, other)
					return true
				else
					return false
				end
			end
			
			local succeeded = false
			for _, way in pairs(choices) do
				if try(way) then
					succeeded = true
					break
				end
			end
		until succeeded or (attempt > 16)
	end
	
	if (self.SizeInChunks.X > 1) and (self.SizeInChunks.Y > 1) then
		local extraDoors = math.floor((self.SizeInChunks.X + self.SizeInChunks.Y) / 8)
		for _ = 1, extraDoors do
			makeExtraDoor()
		end
	end
	
	return chunkGrid
end

function DungeonGranular:ConstructHallways(chunkGrid)
	for _, roomTileGroupA in pairs(self.RoomTileGroups) do
		local position = roomTileGroupA.ChunkPosition
		local chunk = chunkGrid[position.X][position.Y]
		if chunk.PosX then
			self:ConstructHallway(roomTileGroupA, self:GetRoomTileGroupByChunkPosition(position + Vector2.new(1, 0)))
		end
		if chunk.PosY then
			self:ConstructHallway(roomTileGroupA, self:GetRoomTileGroupByChunkPosition(position + Vector2.new(0, 1)))
		end
	end
end

function DungeonGranular:DetermineRooms()
	for row = 0, self.Size.X - 1 do
		for col = 0, self.Size.Y - 1 do
			local position = Vector2.new(row, col)
			local tile = self:Get(position)
			if tile.Filled and not tile.RoomId then
				self:DetermineRoom(position)
			end
		end
	end
end

function DungeonGranular:CreateNewRoomId()
	if not self.RoomId then
		self.RoomId = 0
	end
	
	local id = self.RoomId
	self.RoomId = self.RoomId + 1
	
	return id
end

function DungeonGranular:IsTileDoor(tile)
	if not tile.Walls then return false end
	for key, val in pairs(tile.Walls) do
		if val == "Door" then
			return true
		end
	end
	return false
end

function DungeonGranular:DetermineRoom(position)
	local startTile = self:Get(position)
	if not startTile then return end
	
	local id = self:CreateNewRoomId()
	local roomTileGroup = {
		Id = id,
		Tiles = {},
		DoorTiles = {},
	}
	self.RoomTileGroups[id] = roomTileGroup
	
	local queue = {startTile}
	
	while #queue > 0 do
		local tile = table.remove(queue, 1)
		tile.RoomId = id
		
		if not roomTileGroup.ChunkPosition then
			roomTileGroup.ChunkPosition = Vector2.new(
				math.floor(tile.Position.X / self.ChunkSize.X),
				math.floor(tile.Position.Y / self.ChunkSize.Y)
			)
		end
		
		table.insert(roomTileGroup.Tiles, tile)
		
		if self:IsTileDoor(tile) then
			table.insert(roomTileGroup.DoorTiles, tile)
		end
		
		for _, delta in pairs{
			Vector2.new(1, 0),
			Vector2.new(0, 1),
			Vector2.new(-1, 0),
			Vector2.new(0, -1),
		} do
			local neighbor = self:Get(tile.Position + delta)
			if neighbor and neighbor.Filled and (neighbor.RoomId == nil) then
				neighbor.RoomId = -1
				table.insert(queue, neighbor)
			end
		end
	end
	
	local room = self:CreateNew"RoomGranular"{
		Dungeon = self,
		RoomTileGroup = roomTileGroup,
		Id = id,
	}
	room.Completed:Connect(function()
		self:OnRoomCompleted(room)
	end)
	self.Rooms[id] = room
end

function DungeonGranular:CreateCell(row, col)
	return {
		Filled = false,
		Walls = {},
		Position = Vector2.new(row, col)
	}
end

function DungeonGranular:CreateGrid()
	self.Grid = {}
	
	for row = 0, self.Size.X - 1 do
		self.Grid[row] = {}
		for col = 0, self.Size.Y - 1 do
			self.Grid[row][col] = self:CreateCell(row, col)
		end
	end
end

function DungeonGranular:DoesPatternOverlap(pattern, size, position)
	for row = 0, size.X - 1 do
		for col = 0, size.Y - 1 do
			local patternTile = pattern[row][col]
			local gridTile = self.Grid[row + position.X][col + position.Y]

			if patternTile.Filled and gridTile.Filled then
				return true
			end
		end
	end
	
	return false
end

function DungeonGranular:ApplyPattern(pattern, size, position)
	for row = 0, size.X - 1 do
		for col = 0, size.Y - 1 do
			local patternTile = pattern[row][col]
			if patternTile.Filled then
				local gridTile = self.Grid[row + position.X][col + position.Y]
				for key, val in pairs(patternTile) do
					gridTile[key] = val
				end
			end
		end
	end
end

function DungeonGranular:AddFeature(tile, feature)
	if not tile.Features then
		tile.Features = {}
	end
	table.insert(tile.Features, feature)
end

function DungeonGranular:GenerateRooms()
	self.ThemeMachine:GenerateRooms()
end

function DungeonGranular:RenderTileFeatures(tile)
	if not tile.Features then return end
	
	for _, feature in pairs(tile.Features) do
		feature:Finalize()
	end
end

function DungeonGranular:RenderTileDoors(tile)
	if not tile.Walls then return end
	
	local worldPosition = Vector3.new(
		tile.Position.X * self.TileSize,
		0,
		tile.Position.Y * self.TileSize
	)
	
	local deltasByDirection = {
		NegX = Vector3.new(-0.5, 0, 0),
		PosX = Vector3.new(0.5, 0, 0),
		NegY = Vector3.new(0, 0, -0.5),
		PosY = Vector3.new(0, 0, 0.5),
	}
	
	for direction, wallType in pairs(tile.Walls) do
		if wallType == "Door" then
			local delta = deltasByDirection[direction] * self.TileSize
			
			local position = worldPosition + delta + Vector3.new(math.sign(delta.X) / 2, 6, math.sign(delta.Z) / 2)
			local rotation = CFrame.new()
			if (direction == "PosX" or direction == "NegX") then
				rotation = CFrame.Angles(0, math.pi / 2, 0)
			end
			
			local roomTileGroup = self.RoomTileGroups[tile.RoomId]
			local chunkDelta
			if direction == "PosX" then
				chunkDelta = Vector2.new(1, 0)
			elseif direction == "NegX" then
				chunkDelta = Vector2.new(-1, 0)
			elseif direction == "PosY" then
				chunkDelta = Vector2.new(0, 1)
			elseif direction == "NegY" then
				chunkDelta = Vector2.new(0, -1)
			end
			local chunkPosition = roomTileGroup.ChunkPosition + chunkDelta
			local adjacentRoomTileGroup = self:GetRoomTileGroupByChunkPosition(chunkPosition)
			
			local rooms
			if adjacentRoomTileGroup then
				rooms = {
					self.Rooms[roomTileGroup.Id],
					self.Rooms[adjacentRoomTileGroup.Id],
				}
			else
				rooms = {
					self.Rooms[roomTileGroup.Id]
				}
			end
			
			local cframe = CFrame.new(position) * rotation
			self.ThemeMachine:CreateDoor(cframe, rooms)
			
			-- door jam (i'm pretty sure it's spelled differently and may not even be this)
			local jamSize
			local jamWidth = 2
			if (direction == "PosX" or direction == "NegX") then
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
					local other = self:Get(tile.Position + Vector2.new(dx, dy))
					if other then
						other.Occupied = true
					end
				end
			end
		end
	end
end

function DungeonGranular:RenderTile(position)
	local tile = self:Get(position)
	
	-- now for the floor
	if tile.Rendered then return end
	local row = position.X
	local col = position.Y
	
	while true do --breaks
		if row > (self.Size.X - 1) then break end
		
		tile = self.Grid[row][col]
		if not tile.Filled then break end
		if tile.Rendered then break end
		
		tile.Rendered = true
		
		row = row + 1
	end
	row = row - 1
	
	local function canAddRow()
		for r = position.X, row do
			local tile = self.Grid[r][col]
			if (not tile.Filled) or tile.Rendered then
				return false
			end
		end
		return true
	end
	
	while true do --breaks
		col = col + 1
		
		if col > (self.Size.Y - 1) then break end
		
		if canAddRow() then
			for r = position.X, row do
				tile = self.Grid[r][col]
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
	
	local size = Vector3.new(size.X, 0, size.Y) * self.TileSize + Vector3.new(0, self.FloorThickness, 0)
	local position = Vector3.new(center.X * self.TileSize, -self.FloorThickness / 2, center.Y * self.TileSize)
	
	self.ThemeMachine:CreateFloor(size, position)
end

function DungeonGranular:Get(position)
	if position.X < 0 then
		return nil
	elseif position.X > self.Size.X - 1 then
		return nil
	elseif position.Y < 0 then
		return nil
	elseif position.Y > self.Size.Y - 1 then
		return nil
	else
		return self.Grid[position.X][position.Y]
	end
end

function DungeonGranular:RenderWalls(position)
	local tile = self:Get(position)
	if not tile then return end
	if not tile.Filled then return end
	
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
			local here = self:Get(cursor)
			if not here then return false, "external" end
			if not here.Filled then return false, "external" end
			if here.Walls and here.Walls[hereWall] then return false, "other" end
			
			local there = self:Get(cursor + wallDirection)
			if there then
				if there.Filled then return false, "internal" end
				if there.Walls and there.Walls[thereWall] then return false, "other" end
			end
			
			return true
		end
		
		local tiles = {}
		local pass, reason
		repeat
			pass, reason = check()
			
			if pass then
				table.insert(tiles, self:Get(cursor))
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
			
			local other = self:Get(tile.Position + wallDirection)
			if other then
				other.Walls.NegX = "Wall"
			end
		end
		
		local tileStart = tiles[1]
		local tileEnd = tiles[#tiles]
		
		local x = (tileStart.Position.X + 0.5) * self.TileSize + 0.5
		
		local zStart = (tileStart.Position.Y - 0.5) * self.TileSize
		if reasonStart == "internal" then
			zStart = zStart + 1
		elseif reasonStart == "external" then
			zStart = zStart - 1
		end
		
		local zEnd = (tileEnd.Position.Y + 0.5) * self.TileSize
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
			
			local other = self:Get(tile.Position + wallDirection)
			if other then
				other.Walls.NegY = "Wall"
			end
		end
		
		local tileStart = tiles[1]
		local tileEnd = tiles[#tiles]
		
		local z = (tileStart.Position.Y + 0.5) * self.TileSize + 0.5
		
		local xStart = (tileStart.Position.X - 0.5) * self.TileSize
		local xEnd = (tileEnd.Position.X + 0.5) * self.TileSize
		local x = (xStart + xEnd) / 2
		
		self.ThemeMachine:CreateWall(Vector3.new(math.abs(xEnd - xStart), self.WallHeight, 1), Vector3.new(x, self.WallHeight / 2, z))
	end
	
	-- negX
	wallDirection = Vector2.new(-1, 0)
	local success, tiles, reasonStart, reasonEnd = fullScan(position, Vector2.new(0, 1), wallDirection)
	if success then
		for _, tile in pairs(tiles) do
			tile.Walls.NegX = "Wall"
			
			local other = self:Get(tile.Position + wallDirection)
			if other then
				other.Walls.PosX = "Wall"
			end
		end
		
		local tileStart = tiles[1]
		local tileEnd = tiles[#tiles]
		
		local x = (tileStart.Position.X - 0.5) * self.TileSize - 0.5
		
		local zStart = (tileStart.Position.Y - 0.5) * self.TileSize
		if reasonStart == "internal" then
			zStart = zStart + 1
		elseif reasonStart == "external" then
			zStart = zStart - 1
		end
		
		local zEnd = (tileEnd.Position.Y + 0.5) * self.TileSize
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
			
			local other = self:Get(tile.Position + wallDirection)
			if other then
				other.Walls.PosY = "Wall"
			end
		end
		
		local tileStart = tiles[1]
		local tileEnd = tiles[#tiles]
		
		local z = (tileStart.Position.Y - 0.5) * self.TileSize - 0.5
		
		local xStart = (tileStart.Position.X - 0.5) * self.TileSize
		local xEnd = (tileEnd.Position.X + 0.5) * self.TileSize
		local x = (xStart + xEnd) / 2
		
		self.ThemeMachine:CreateWall(Vector3.new(math.abs(xEnd - xStart), self.WallHeight, 1), Vector3.new(x, self.WallHeight / 2, z))
	end
end

function DungeonGranular:RenderWallsOld(position)
	local function buildWall(size, position)
		self.ThemeMachine:CreateWall(size, position)
	end
	
	local cursor, shouldBuild
	
	-- check walls in the positive x direction
	shouldBuild = false
	cursor = Vector2.new(position.X, position.Y)
	repeat
		local stop = true
		
		local tile = self:Get(cursor)
		local posX = self:Get(cursor + Vector2.new(1, 0))
		if (tile ~= nil) and (tile.Walls.PosX == nil) and ( (posX and (posX.Filled ~= tile.Filled) and posX.Walls.NegX == nil) or (tile.Filled and (posX == nil)) ) then
			tile.Walls.PosX = "Wall"
			
			if posX then
				posX.Walls.NegX = "Wall"
			end
			
			cursor = cursor + Vector2.new(0, 1)
			stop = false
			shouldBuild = true
		end
	until stop
	cursor = cursor - Vector2.new(0, 1)
	
	if shouldBuild then
		local delta = cursor - position
		local center = position + (delta / 2)
		local size = delta + Vector2.new(1, 1)
		buildWall(
			Vector3.new(1, self.WallHeight, size.Y * self.TileSize - 1),
			Vector3.new((center.X + 0.5) * self.TileSize, self.WallHeight / 2, center.Y * self.TileSize)
		)
	end
	
	-- check walls in the positive y direction
	shouldBuild = false
	cursor = Vector2.new(position.X, position.Y)
	repeat
		local stop = true
		
		local tile = self:Get(cursor)
		local posY = self:Get(cursor + Vector2.new(0, 1))
		if (tile ~= nil) and (tile.Walls.PosY == nil) and ( (posY and (posY.Filled ~= tile.Filled) and posY.Walls.NegY == nil) or (tile.Filled and (posY == nil)) ) then
			tile.Walls.PosY = "Wall"
			
			if posY then
				posY.Walls.NegY = "Wall"
			end
			
			cursor = cursor + Vector2.new(1, 0)
			stop = false
			shouldBuild = true
		end
	until stop
	cursor = cursor - Vector2.new(1, 0)
	
	if shouldBuild then
		local delta = cursor - position
		local center = position + (delta / 2)
		local size = delta + Vector2.new(1, 1)
		buildWall(
			Vector3.new(size.X * self.TileSize + 1, self.WallHeight, 1),
			Vector3.new(center.X * self.TileSize, self.WallHeight / 2, (center.Y + 0.5) * self.TileSize)
		)
	end
	
	-- edge case: x is zero
	if position.X == 0 then
		shouldBuild = false
		cursor = Vector2.new(position.X, position.Y)
		repeat
			local stop = true
			
			local tile = self:Get(cursor)
			if tile and tile.Filled and (tile.Walls.NegX == nil) then
				tile.Walls.NegX = "Wall"
				cursor = cursor + Vector2.new(0, 1)
				stop = false
				shouldBuild = true
			end
		until stop
		cursor = cursor - Vector2.new(0, 1)
		
		if shouldBuild then
			local delta = cursor - position
			local center = position + (delta / 2)
			local size = delta + Vector2.new(1, 1)
			buildWall(
				Vector3.new(1, self.WallHeight, size.Y * self.TileSize - 1),
				Vector3.new((center.X - 0.5) * self.TileSize, self.WallHeight / 2, center.Y * self.TileSize)
			)
		end
	end
	
	-- edge case: y is zero
	if position.Y == 0 then
		shouldBuild = false
		cursor = Vector2.new(position.X, position.Y)
		repeat
			local stop = true
			
			local tile = self:Get(cursor)
			if tile and tile.Filled and (tile.Walls.NegY == nil) then
				tile.Walls.NegY = "Wall"
				cursor = cursor + Vector2.new(1, 0)
				stop = false
				shouldBuild = true
			end
		until stop
		cursor = cursor - Vector2.new(1, 0)
		
		if shouldBuild then
			local delta = cursor - position
			local center = position + (delta / 2)
			local size = delta + Vector2.new(1, 1)
			buildWall(
				Vector3.new(size.X * self.TileSize + 1, self.WallHeight, 1),
				Vector3.new(center.X * self.TileSize, self.WallHeight / 2, (center.Y - 0.5) * self.TileSize)
			)
		end
	end
end

function DungeonGranular:ForEachTile(size, position, callback)
	for dx = 0, size.X - 1 do
		for dy = 0, size.Y - 1 do
			callback(self:Get(position + Vector2.new(dx, dy)))
		end
	end
end

function DungeonGranular:IsTileWall(tile)
	return
		(tile.Walls ~= nil) and
		(tile.Walls.PosX == "Wall") or
		(tile.Walls.NegX == "Wall") or
		(tile.Walls.PosY == "Wall") or
		(tile.Walls.NegY == "Wall")
end

function DungeonGranular:IsFeatureAgainstWall(feature)
	local tile = self:Get(feature.Position)
	if not tile then return false end
	if not tile.Filled then return false end
	if not self:IsTileWall(tile) then return false end
	
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
			local otherTile = self:Get(position + Vector2.new(dx, dy))
			if not otherTile then return false end
			if not otherTile.Filled then return false end
			
			if vertical and (otherTile.Position.X == tile.Position.X) then
				if not (otherTile.Walls and otherTile.Walls[wall] == "Wall") then
					return false
				end
			
			elseif (not vertical) and (otherTile.Position.Y == tile.Position.Y) then
				if not (otherTile.Walls and otherTile.Walls[wall] == "Wall") then
					return false
				end
			end
		end
	end
	
	return true
end

function DungeonGranular:DoesFeatureFit(feature)
	local size, position = feature:GetFootprint()
	
	for dx = 0, size.X - 1 do
		for dy = 0, size.Y - 1 do
			local tile = self:Get(position + Vector2.new(dx, dy))
			if not tile then
				return false, "Missing tile"
			end
			if tile.Features and #tile.Features > 0 then
				return false, "Existing features"
			end
			if feature.RequiresFilled and (not tile.Filled) then
				return false, "Tile not filled"
			end
			if tile.Occupied then
				return false, "Tile occupied"
			end
			if tile.NoFeatures then
				return false, "No features allowed"
			end
		end
	end
	return true
end

function DungeonGranular:ApplyFeature(feature)
	local size, position = feature:GetFootprint()
	
	for dx = 0, size.X - 1 do
		for dy = 0, size.Y - 1 do
			local tile = self:Get(position + Vector2.new(dx, dy))
			tile.Occupied = true
		end
	end
	
	self:AddFeature(self:Get(feature.Position), feature)
end

function DungeonGranular:ApplyFeatureIfFits(feature)
	local success, reason = self:DoesFeatureFit(feature) 
	if success then
		self:ApplyFeature(feature)
		return true
	else
		return false, reason
	end
end

function DungeonGranular:RenderDungeon()
	if self.ThemeMachine.PreRender then
		self.ThemeMachine:PreRender()
	end
	
	self.Model = Instance.new("Model")
	self.Model.Name = "Dungeon"
	self.Model.Parent = workspace
	
	-- determine walls
	for row = 0, self.Size.X - 1 do
		for col = 0, self.Size.Y - 1 do
			local position = Vector2.new(row, col)
			
			self:RenderWalls(position)
			
			-- also doors tho
			self:RenderTileDoors(self:Get(position))
		end
	end
	
	-- generate features
	for row = 0, self.Size.X - 1 do
		for col = 0, self.Size.Y - 1 do
			-- now we can generate features
			self.ThemeMachine:GenerateFeatures(self:Get(Vector2.new(row, col)))
		end
	end
	
	if self.ThemeMachine.GenerateCustom then
		self.ThemeMachine:GenerateCustom()
	end
	
	-- fill the floor
	for row = 0, self.Size.X - 1 do
		for col = 0, self.Size.Y - 1 do
			local tile = self.Grid[row][col]
			local position = Vector2.new(row, col)
			
			-- features first because it plays nicer with the part-saving algorithm
			self:RenderTileFeatures(tile)
			
			-- now we can fill the floor
			if tile.Filled then
				self:RenderTile(position)
			end
		end
	end
	
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