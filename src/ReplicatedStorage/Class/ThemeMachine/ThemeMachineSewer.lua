local Super = require(script.Parent)
local ThemeMachineSewer = Super:Extend()

function ThemeMachineSewer:GetDoorModel()
	return self.Storage.Models.Mine.Door:Clone()
end

function ThemeMachineSewer:GenerateFeatures(tile)
	self:GenerateFeatureWallDecoration(tile)
	self:GenerateFeatureFloorDecoration(tile)
end

local FloorDecorationModelNames = {
	Anvil1 = 1,
	Anvil2 = 1,
	Anvil3 = 1,
	Mixer = 3,
	Pot = 5,
	PotPoison = 3,
	PotStack = 3,
	Scrap1 = 11,
	Scrap2 = 11,
}
function ThemeMachineSewer:GenerateFeatureFloorDecoration(tile)
	if self.Random:NextInteger(1, 32) == 1 then
		self.Dungeon:ApplyFeatureIfFits(self:CreateNew"DungeonFeature"{
			Position = tile.Position,
			Rotation = self.Random:NextInteger(0, 3),
			Model = self.Storage.Models.Sewer[self:GetWeightedResult(FloorDecorationModelNames, self.Random)],
			PlacementType = "Center",
			Dungeon = self.Dungeon,
		})
	end
end

local WallDecorationModelNames = {
	WallChains = 1,
	Grate1 = 1,
	Grate2 = 1,
	Grate3 = 1,
	Grate4 = 1,
	GrateSpawner = 1,
	Pipe1 = 1,
	Pipe2 = 1,
	Pipe3 = 1,
	WeaponRack1 = 1,
	WeaponRack2 = 1,
}
function ThemeMachineSewer:GenerateFeatureWallDecoration(tile)
	if (self.Random:NextInteger(1, 8) == 1) and self:IsTileWall(tile) then
		local rotation = 0
		if tile.Walls.NegY then
			rotation = 1
		elseif tile.Walls.PosX then
			rotation = 2
		elseif tile.Walls.PosY then
			rotation = 3
		end
		local feature = self:CreateNew"DungeonFeature"{
			Position = tile.Position,
			Rotation = rotation,
			Model = self.Storage.Models.Sewer[self:GetWeightedResult(WallDecorationModelNames, self.Random)],
			PlacementType = "Back",
			Dungeon = self.Dungeon,
		}
		
		if self.Dungeon:IsFeatureAgainstWall(feature) then
			self.Dungeon:ApplyFeatureIfFits(feature)
		end
	end
end

function ThemeMachineSewer:GetFloorPart()
	return self.Storage.Models.Sewer.Floor:Clone()
end

function ThemeMachineSewer:GetWallPart()
	return self.Storage.Models.Sewer.Wall:Clone()
end

function ThemeMachineSewer:GenerateChunk(chunkPosition)
	local chunkSize = self.Dungeon.ChunkSize
	local roomSize = chunkSize - self.Dungeon.ChunkPadding
	
	-- create a rectangle
	local sideSmall = self.Random:NextInteger(10, 20)
	local sideLarge = self.Random:NextInteger(20, 30)
	local size
	if self.Random:NextInteger(1, 2) == 1 then
		size = Vector2.new(sideSmall, sideLarge)
	else
		size = Vector2.new(sideLarge, sideSmall)
	end
	
	local position = Vector2.new(
		self.Random:NextInteger(0, roomSize.X - size.X - 1),
		self.Random:NextInteger(0, roomSize.Y - size.Y - 1)
	)
	position = position + chunkPosition * chunkSize
	
	-- apply the pattern
	self.Dungeon:ApplyPattern(self:CreateSquareRoom(size, position))
	self:AddTorches(size, position)
end

local TorchModelNames = {
	Brazier1 = 4,
	Brazier2 = 1,
}
function ThemeMachineSewer:AddTorch(position)
	local tile = self.Dungeon:Get(position)
	if tile and tile.Filled then
		local feature = self:CreateNew"DungeonFeature"{
			Position = position,
			Rotation = self.Random:NextInteger(0, 3),
			Model = self.Storage.Models.Sewer[self:GetWeightedResult(TorchModelNames, self.Random)],
			Dungeon = self.Dungeon,
		}
		self.Dungeon:ApplyFeatureIfFits(feature)
	end
end
function ThemeMachineSewer:AddTorches(size, position)
	local padding = 0.2
	local minX = math.floor(position.X + size.X * padding)
	local minY = math.floor(position.Y + size.Y * padding)
	local maxX = math.ceil(position.X + size.X * (1 - padding))
	local maxY = math.ceil(position.Y + size.Y * (1 - padding))
	self:AddTorch(Vector2.new(minX, minY))
	self:AddTorch(Vector2.new(minX, maxY))
	self:AddTorch(Vector2.new(maxX, minY))
	self:AddTorch(Vector2.new(maxX, maxY))
end

return ThemeMachineSewer