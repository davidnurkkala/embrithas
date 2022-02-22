local Super = require(script.Parent)
local ThemeMachineForest = Super:Extend()

function ThemeMachineForest:SetUpLighting()
	local lighting = game:GetService("Lighting")
	lighting.ClockTime = 12
	lighting.Brightness = 2
	
	lighting:ClearAllChildren()
	self.Storage.Models.OutdoorSky:Clone().Parent = lighting
end

-- DarknessSolo was here
local FloorModelNames = {
	LargeRock1 = 8,
	LargeRock2 = 8,
	LargeRock3 = 8,
	LargeRock4 = 8,
	LargeRock5 = 8,
	LargeRock6 = 8,
	LargeRock7 = 8,
	LargeRock8 = 8,
	LargeRock9 = 8,
	LargeRock10 = 8,
	LargeRock11 = 8,
	LargeRock12 = 8,

	Rock1 = 16,
	Rock2 = 16,
	Rock3 = 16,
	Rock4 = 16,

	SmallTree1 = 8,
	SmallTree2 = 8,

	Flower1 = 16,
	Flower2 = 16,

	-- iMeckLords was here
	Log1 = 8,
	Log2 = 8,
}

function ThemeMachineForest:GenerateFeatures(tile)
	if not tile.TerrainFilled then
		self:TerrainFillEmptyTiles(tile.Position, Enum.Material.Grass)
	end
	
	local chance = 128
	
	if not tile.Filled and self.Random:NextInteger(1, chance) == 1 then
		self.Dungeon:ApplyFeatureIfFits(self:CreateNew"DungeonFeature"{
			RequiresFilled = false,
			Position = tile.Position,
			Rotation = self.Random:NextInteger(0, 3),
			Model = self.Storage.Models.Forest["LargeTree"..self.Random:NextInteger(1, 4)],
			Dungeon = self.Dungeon,
			PlacementType = "Center",
		})
	elseif self.Random:NextInteger(1, 32) == 1 then
		self.Dungeon:ApplyFeatureIfFits(self:CreateNew"DungeonFeature"{
			Position = tile.Position,
			Rotation = self.Random:NextInteger(0, 3),
			Model = self.Storage.Models.Forest[self:GetWeightedResult(FloorModelNames, self.Random)],
			Dungeon = self.Dungeon,
			PlacementType = "Center",
		})
	end
	
	self:GenerateFallenTree(tile)
end

function ThemeMachineForest:GenerateFallenTree(tile)
	if (self.Random:NextInteger(1, 16) == 1) and self:IsTileWall(tile) then
		local rotation = 0
		local delta = Vector2.new(3, 0)
		if tile.Walls.NegY then
			rotation = 1
			delta = Vector2.new(0, 3)
		elseif tile.Walls.PosX then
			rotation = 2
			delta = Vector2.new(-3, 0)
		elseif tile.Walls.PosY then
			rotation = 3
			delta = Vector2.new(0, -3)
		end
		
		-- this only goes if the end will be empty
		local other = self.Dungeon:Get(tile.Position + delta)
		if other and other.Filled then return end
		
		local feature = self:CreateNew"DungeonFeature"{
			Position = tile.Position,
			Rotation = rotation,
			Model = self.Storage.Models.Forest.FallenTree,
			PlacementType = "Back",
			Dungeon = self.Dungeon,
		}
		
		if self.Dungeon:IsFeatureAgainstWall(feature) then
			self.Dungeon:ApplyFeatureIfFits(feature)
		end
	end
end

function ThemeMachineForest:GetFloorPart()
	return self.Storage.Models.Forest.Floor:Clone()
end

function ThemeMachineForest:GetWallPart()
	return self.Storage.Models.Forest.Wall:Clone()
end

function ThemeMachineForest:GetDoorModel()
	return self.Storage.Models.Forest.Door:Clone()
end

local RoomTypes = {
	Square = 8,
	Circle = 8,
	Cave = 24,
}

function ThemeMachineForest:GenerateChunk(chunkPosition)
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

return ThemeMachineForest