local Super = require(script.Parent)
local ThemeMachineMountain = Super:Extend()

function ThemeMachineMountain:SetUpLighting()
	local lighting = game:GetService("Lighting")
	lighting.ClockTime = 12
	lighting.Brightness = 1
	
	lighting:ClearAllChildren()
	self.Storage.Models.OutdoorSky:Clone().Parent = lighting
end

function ThemeMachineMountain:GenerateFeatures(tile)
	if not tile.TerrainFilled then
		self:TerrainFillEmptyTiles(tile.Position, Enum.Material.Rock)
	end
	
	if self.Random:NextInteger(1, 64) == 1 then
		self.Dungeon:ApplyFeatureIfFits(self:CreateNew"DungeonFeature"{
			Position = tile.Position,
			Rotation = self.Random:NextInteger(0, 3),
			Model = self.Storage.Models.Mountain["Rock"..self.Random:NextInteger(1, 16)],
			Dungeon = self.Dungeon,
			PlacementType = "Center",
		})
	end
end

function ThemeMachineMountain:GetFloorPart()
	return self.Storage.Models.Mountain.Floor:Clone()
end

function ThemeMachineMountain:GetWallPart()
	local wall = self.Storage.Models.Mountain.Wall:Clone()
	wall.Transparency = 1
	return wall
end

function ThemeMachineMountain:GetDoorjambPart()
	return self.Storage.Models.Mountain.Wall:Clone()
end

function ThemeMachineMountain:GetDoorModel()
	return self.Storage.Models.Mountain.Door:Clone()
end

local RoomTypes = {
	Square = 8,
	Circle = 8,
	Cave = 48,
}

function ThemeMachineMountain:GenerateChunk(chunkPosition)
	local chunkSize = self.Dungeon.ChunkSize
	local roomSize = chunkSize - self.Dungeon.ChunkPadding
	local choice = self:GetWeightedResult(RoomTypes, self.Random)
	
	local patternArgs = {}
					
	if choice == "Square" then
		local size = Vector2.new(
			self.Random:NextInteger(16, 32),
			self.Random:NextInteger(16, 32)
		)
		
		local position = Vector2.new(
			self.Random:NextInteger(0, roomSize.X - size.X - 1),
			self.Random:NextInteger(0, roomSize.Y - size.Y - 1)
		)
		position = position + chunkPosition * chunkSize
		
		patternArgs = {self:CreateSquareRoom(size, position)}
	
	elseif choice == "Circle" then
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
	elseif choice == "Cave" then
		patternArgs = {self:CreateLargeCaveRoom(roomSize, chunkPosition * chunkSize, 4)}
	end
	
	self.Dungeon:ApplyPattern(unpack(patternArgs))
end

return ThemeMachineMountain