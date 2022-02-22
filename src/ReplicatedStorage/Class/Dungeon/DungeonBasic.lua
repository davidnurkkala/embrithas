local Lighting = game:GetService("Lighting")

local Super = require(script.Parent)
local DungeonBasic = Super:Extend()

DungeonBasic.Size = Vector2.new(4, 4)
DungeonBasic.TileSize = 64

function DungeonBasic:OnCreated()
	Super.OnCreated(self)
	
	local seed = tick()
	
	print("Generating dungeon with seed", seed)
	self.Random = Random.new(seed)
	
	self.Rooms = {}
	self.Doors = {}
	
	if self.GridMap then
		self:LoadGrid()
	else
		self:GenerateGrid()
		self:CarveGrid()
	end
	
	self:BuildGrid()
	
	self:InitStartRoom()
end

function DungeonBasic:OnRoomCompleted()
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

function DungeonBasic:InitStartRoom()
	local position = self.StartRoomGridPosition or Vector2.new(
		self.Random:NextInteger(1, self.Size.X),
		self.Random:NextInteger(1, self.Size.Y)
	)
	
	local startRoom = self:GetGrid(position).Room
	self.StartRoom = startRoom
	startRoom:Complete()
	startRoom:SetModelEffects(true)
	startRoom:ActivateSafeFeatures()
end

function DungeonBasic:CreateCell()
	return {
		PosY = false,
		NegY = false,
		PosX = false,
		NegX = false,
		
		Position = Vector2.new(0, 0),
		
		Carved = false,
		
		GetDoorCount = function(self)
			if self.DoorCount then return self.DoorCount end
			local doors = 0
			if self.PosY then doors += 1 end
			if self.NegY then doors += 1 end
			if self.PosX then doors += 1 end
			if self.NegX then doors += 1 end
			self.DoorCount = doors
			return doors
		end,
	}
end

function DungeonBasic:LoadGrid()
	self.Size = Vector2.new(
		#self.GridMap[1],
		#self.GridMap
	)
	self.Grid = {}
	
	for x = 1, self.Size.X do
		self.Grid[x] = {}
		for y = 1, self.Size.Y do
			local cell = self:CreateCell()
			cell.Position = Vector2.new(x, y)
			
			self.Grid[x][y] = cell
		end
	end
	
	local function carve(x1, y1, x2, y2)
		self:CarveBetween(self:GetGrid(Vector2.new(x1, y1)), self:GetGrid(Vector2.new(x2, y2)))
	end
	
	for y = 1, self.Size.Y do
		local row = self.GridMap[y]
		for x = 1, self.Size.X do
			local symbol = string.sub(row, x, x)
			if symbol == "V" then
				carve(x, y, x, y + 1)
			elseif symbol == "<" then
				carve(x, y, x - 1, y)
			elseif symbol == "^" then
				carve(x, y, x, y - 1)
			elseif symbol == ">" then
				carve(x, y, x + 1, y)
			elseif symbol == "-" then
				carve(x, y, x + 1, y)
				carve(x, y, x - 1, y)
			elseif symbol == "|" then
				carve(x, y, x, y + 1)
				carve(x, y, x, y - 1)
			elseif symbol == "#" then
				carve(x, y, x + 1, y)
				carve(x, y, x - 1, y)
				carve(x, y, x, y + 1)
				carve(x, y, x, y - 1)
			end
		end
	end
end

function DungeonBasic:GenerateGrid()
	self.Grid = {}
	for x = 1, self.Size.X do
		self.Grid[x] = {}
		for y = 1, self.Size.Y do
			local cell = self:CreateCell()
			cell.Position = Vector2.new(x, y)
			
			self.Grid[x][y] = cell
		end
	end
end

function DungeonBasic:GetGrid(position)
	if position.X < 1 then return end
	if position.X > self.Size.X then return end
	if position.Y < 1 then return end
	if position.Y > self.Size.Y then return end
	
	return self.Grid[position.X][position.Y]
end

function DungeonBasic:GetGridNeighbors(position)
	local neighbors = {}
	for _, delta in pairs{
		Vector2.new(1, 0),
		Vector2.new(-1, 0),
		Vector2.new(0, 1),
		Vector2.new(0, -1)
	} do
		local neighbor = self:GetGrid(position + delta)
		if neighbor then table.insert(neighbors, neighbor) end
	end
	return neighbors
end

function DungeonBasic:CarveBetween(a, b)
	if not (a and b) then return end
	
	local delta = b.Position - a.Position
	
	if delta.X == 1 then
		a.PosX = true
		b.NegX = true
	elseif delta.X == -1 then
		a.NegX = true
		b.PosX = true
	elseif delta.Y == 1 then
		a.PosY = true
		b.NegY = true
	elseif delta.Y == -1 then
		a.NegY = true
		b.PosY = true
	end
	
	a.Carved = true
	b.Carved = true
end

function DungeonBasic:CarveGrid()
	local start = Vector2.new(self.Random:NextInteger(1, self.Size.X), self.Random:NextInteger(1, self.Size.Y))
	local stack = {self.Grid[start.X][start.Y]}
	while #stack > 0 do
		local current = stack[#stack]
		
		--acquire our neighbors
		local neighbors = self:GetGridNeighbors(current.Position)
		
		--choose an uncarved neighbor at random
		self:Shuffle(neighbors, self.Random)
		local chosen
		for _, neighbor in pairs(neighbors) do
			if not neighbor.Carved then
				chosen = neighbor
				break
			end
		end
		
		--if we found an uncarved neighbor, we carve to it and push it to the stack
		--if we didn't, then we remove this one from the stack
		if chosen then
			self:CarveBetween(current, chosen)
			table.insert(stack, chosen)
		else
			table.remove(stack, #stack)
		end
	end
	
	local function makeExtraDoor()
		repeat
			local cell = self:GetGrid(
				Vector2.new(
					self.Random:NextInteger(1, self.Size.X),
					self.Random:NextInteger(1, self.Size.Y)
				)
			)
			local choices = {"PosX", "NegX", "PosY", "NegY"}
			self:Shuffle(choices, self.Random)
			
			local function try(way)
				local other
				if way == "PosX" and (not cell.PosX) then
					other = self:GetGrid(cell.Position + Vector2.new(1, 0))
				elseif way == "PosY" and (not cell.PosY) then
					other = self:GetGrid(cell.Position + Vector2.new(0, 1))
				elseif way == "NegX" and (not cell.NegX) then
					other = self:GetGrid(cell.Position + Vector2.new(-1, 0))
				elseif way == "NegY" and (not cell.NegY) then
					other = self:GetGrid(cell.Position + Vector2.new(0, -1))
				end
				if other then
					self:CarveBetween(cell, other)
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
		until succeeded
	end
	
	local extraDoors = math.floor((self.Size.X * self.Size.Y) * 0.4)
	if self.Size.X < 2 or self.Size.Y < 2 then
		extraDoors = 0
	end
	self:Print("Generating %d extra doors", extraDoors)
	for n = 1, extraDoors do
		makeExtraDoor()
	end
end

function DungeonBasic:GetTileSet(name)
	return self:CreateNew"TileSet"{
		TileSetName = name,
		Random = self.Random,
	}
end

function DungeonBasic:GetRoomPosition(cell)
	return Vector3.new(self.TileSize * cell.Position.X, 0, self.TileSize * cell.Position.Y) + Vector3.new(-self.TileSize * self.Size.X / 2, 0, -self.TileSize * self.Size.Y / 2)
end

function DungeonBasic:BuildGrid()
	local model do
		model = Instance.new("Model")
		model.Parent = workspace
		model.Name = "Dungeon"
		self.Model = model
	end
	
	local tileSet = self:GetTileSet(self.TileSetName)
	
	for x = 1, self.Size.X do
		for y = 1, self.Size.Y do
			local cell = self:GetGrid(Vector2.new(x, y))
			local doors = cell:GetDoorCount()
			local rot = 0
			local model
			
			if doors == 1 then
				model = tileSet:GetTile("DeadEnd")
				
				if cell.NegX then
					rot = 1
				elseif cell.PosY then
					rot = 2
				elseif cell.PosX then
					rot = 3
				end
			elseif doors == 2 then
				if cell.NegY then
					if cell.PosY then
						model = tileSet:GetTile("Hallway")
						rot = (self.Random:NextInteger(1, 2) == 1) and 0 or 2
					elseif cell.NegX then
						model = tileSet:GetTile("Corner")
					elseif cell.PosX then
						model = tileSet:GetTile("Corner")
						rot = 3
					end
				elseif cell.PosX then
					if cell.NegX then
						model = tileSet:GetTile("Hallway")
						rot = (self.Random:NextInteger(1, 2) == 1) and 1 or 3
					elseif cell.PosY then
						model = tileSet:GetTile("Corner")
						rot = 2
					end
				elseif cell.NegX and cell.PosY then
					model = tileSet:GetTile("Corner")
					rot = 1
				end	
			elseif doors == 3 then
				model = tileSet:GetTile("ThreeWay")
				
				if not cell.NegY then
					rot = 1
				elseif not cell.NegX then
					rot = 2
				elseif not cell.PosY then
					rot = 3
				end
			elseif doors == 4 then
				model = tileSet:GetTile("FourWay")
				rot = self.Random:NextInteger(0, 3)
			elseif doors == 0 then
				continue
			end
			
			local position = self:GetRoomPosition(cell)
			local rotation = CFrame.Angles(0, rot * (math.pi / 2), 0)
			local cframe = CFrame.new(position) * rotation
			
			local room = self:CreateNew"RoomBasic"{
				Model = model,
				CFrame = cframe,
				GridData = cell,
				Dungeon = self,
			}
			room.Completed:Connect(function()
				self:OnRoomCompleted(room)
			end)
			cell.Room = room
			table.insert(self.Rooms, room)
		end
	end
	
	for x = 1, self.Size.X do
		for y = 1, self.Size.Y do
			local cell = self:GetGrid(Vector2.new(x, y))
			local room = cell.Room
			local position = self:GetRoomPosition(cell)
			
			--doors
			local function makeDoor(cframe, delta)
				local door = self:CreateNew"Door"{
					Dungeon = self,
					Rooms = {room, self:GetGrid(cell.Position + delta).Room},
					Model = tileSet:GetDoor(),
					CFrame = cframe,
				}
				table.insert(self.Doors, door)
			end
			if cell.PosX or cell.PosY then
				local door = tileSet:GetDoor()
				local dy = door.PrimaryPart.Size.Y / 2 + 1.5
				
				if cell.PosX then
					local doorCFrame = 	CFrame.new(position + Vector3.new(self.TileSize / 2, dy, 0)) *
										CFrame.Angles(0, math.pi / 2, 0)
					makeDoor(doorCFrame, Vector2.new(1, 0))
				end
				if cell.PosY then
					local doorCFrame = CFrame.new(position + Vector3.new(0, dy, self.TileSize / 2))
					makeDoor(doorCFrame, Vector2.new(0, 1))
				end
			end
		end
	end
	
	-- set up lighting
	Lighting:ClearAllChildren()
	
	local skyboxName = tileSet.Lighting.SkyboxName 
	if skyboxName then
		self.Storage.Models:FindFirstChild(skyboxName):Clone().Parent = Lighting
	end
	
	for key, val in pairs(tileSet.Lighting.Attributes) do
		Lighting[key] = val
	end
end

function DungeonBasic:DistributeEncounters(encounters)
	local rooms = {}
	for _, room in pairs(self.Rooms) do
		if room ~= self.StartRoom then
			table.insert(rooms, room)
		end
	end

	-- positioned encounters go first
	for index = #encounters, 1, -1 do
		local encounter = encounters[index]
		if encounter.GridPosition then
			table.remove(encounters, index)
			
			local cell = self:GetGrid(encounter.GridPosition)
			local room = cell.Room
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

function DungeonBasic:Destroy()
	self.Active = false
	self.Model:Destroy()
end

function DungeonBasic:Explode()
	self:GetService("EffectsService"):RequestEffectAll("ExplodeDungeon", {Model = self.Model})
	game:GetService("Debris"):AddItem(self.Model, 2)
end

return DungeonBasic